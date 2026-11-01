# frozen_string_literal: true

# App Asset Library creative images. Standard screenshots remain a separate flow.
require "json"
require "digest"
require "fileutils"
require "net/http"
require "uri"
require "zlib"

module AppStoreCreativeAssets
  class Error < StandardError; end
  TYPES = {
    "header" => "PRODUCT_PAGE_HEADER_ASSET",
    "search" => "APP_STORE_SEARCH_RESULTS_ASSET"
  }.freeze
  READY = %w[PREPARE_FOR_SUBMISSION READY_FOR_REVIEW WAITING_FOR_REVIEW IN_REVIEW ACCEPTED APPROVED].freeze
  EDITABLE = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED].freeze

  # No raw API bodies, JWTs, or signed upload URLs are logged or saved.
  class Client
    ORIGIN = "https://api.appstoreconnect.apple.com"

    def initialize(env = ENV)
      require "spaceship"
      @key_id = env["ASC_KEY_ID"] || env["APP_STORE_CONNECT_API_KEY_KEY_ID"]
      @issuer_id = env["ASC_ISSUER_ID"] || env["APP_STORE_CONNECT_API_KEY_ISSUER_ID"]
      @filepath = env["ASC_KEY_FILEPATH"] || env["APP_STORE_CONNECT_API_KEY_PATH"]
      raise Error, "Configure the app-local ASC API key ID, issuer ID and .p8 filepath" if [@key_id, @issuer_id, @filepath].any? { |v| v.to_s.empty? }
      @filepath = File.expand_path(@filepath)
      raise Error, "Configured .p8 file does not exist" unless File.file?(@filepath)
    end

    def request(method, path, payload = nil)
      uri = URI.join(ORIGIN, path)
      raise Error, "Unexpected API origin" unless uri.scheme == "https" && uri.host == URI(ORIGIN).host
      if !@token || Time.now.to_i >= @renew_at
        @token = Spaceship::ConnectAPI::Token.create(key_id: @key_id, issuer_id: @issuer_id,
          filepath: @filepath, duration: 1200, in_house: false)
        @renew_at = Time.now.to_i + 1000
      end
      req = Net::HTTPGenericRequest.new(method, !payload.nil?, true, uri.request_uri)
      req["Authorization"] = "Bearer #{@token.text}"
      req["Content-Type"] = "application/json"
      req.body = JSON.generate(payload) if payload
      response = send_request(uri, req)
      unless response.code.to_i.between?(200, 299)
        codes = JSON.parse(response.body).fetch("errors", []).map { |e| e["code"] }.compact rescue []
        raise Error, "ASC #{method} #{uri.path}: HTTP #{response.code} #{codes.join(', ')}"
      end
      response.body.to_s.empty? ? {} : JSON.parse(response.body)
    rescue JSON::ParserError
      raise Error, "Invalid ASC response; audit remote state before retrying any write"
    end

    def list(path)
      items = []
      loop do
        page = request("GET", path)
        items.concat(page.fetch("data"))
        path = page.dig("links", "next")
        break if path.to_s.empty?
      end
      items
    end

    def transfer(operation, bytes)
      uri = URI(operation.fetch("url"))
      raise Error, "Invalid upload operation" unless uri.scheme == "https" && operation["method"] == "PUT"
      req = Net::HTTP::Put.new(uri.request_uri)
      operation.fetch("requestHeaders", []).each { |h| req[h.fetch("name")] = h.fetch("value") }
      raise Error, "Unexpected authorization header on asset transfer" if req["Authorization"]
      req.body = bytes
      response = send_request(uri, req)
      raise Error, "Asset transfer failed: HTTP #{response.code}; resume the existing reservation" unless response.code.to_i.between?(200, 299)
    end

    private

    def send_request(uri, req)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 120) { |http| http.request(req) }
    rescue IOError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError
      # POST is intentionally never retried: the server may already have accepted it.
      raise Error, "Network interrupted; audit/resume the existing operation before retrying"
    end
  end

  class Manifest
    attr_reader :app_id, :bundle_id, :assets, :path, :types

    def initialize(path, expected_bundle_id:)
      @path = File.expand_path(path)
      data = JSON.parse(File.read(@path))
      @app_id = data.fetch("app_id").to_s
      @bundle_id = data.fetch("bundle_id")
      raise Error, "Manifest app_id must be a numeric Apple app ID" unless @app_id.match?(/\A\d+\z/)
      raise Error, "Manifest belongs to another bundle ID" if expected_bundle_id.to_s.empty? || @bundle_id != expected_bundle_id
      @types = data.fetch("placements", %w[header search])
      raise Error, "Choose unique header/search placements" if @types.empty? || @types.uniq != @types || (@types - TYPES.keys).any?
      @assets = data.fetch("assets").map do |entry|
        locale = entry.fetch("locale")
        raise Error, "Invalid locale" unless locale.match?(/\A[a-z]{2,3}(?:-[A-Za-z]{2,4})*\z/)
        file = File.expand_path(entry.fetch("file"), File.dirname(@path))
        info = png_info(file)
        digest = Digest::SHA256.file(file).hexdigest
        raise Error, "Checksum differs from the approved manifest for #{locale}" unless entry.fetch("sha256") == digest
        info.merge("locale" => locale, "file" => file, "sha256" => digest,
          "reference_name" => "creative-v1-#{@app_id}-#{digest}")
      end
      raise Error, "Manifest must contain one image per locale" if @assets.empty? || @assets.map { |a| a["locale"] }.uniq.size != @assets.size
    rescue KeyError, JSON::ParserError, Errno::ENOENT => e
      raise Error, "Invalid creative manifest or missing file (#{e.class})"
    end

    def unique_assets
      @assets.uniq { |a| a["sha256"] }
    end

    private

    def png_info(path)
      # Validate all chunks/CRCs and reject palette transparency as well as alpha.
      File.open(path, "rb") do |file|
        raise Error, "Creative image must be PNG" unless file.read(8) == "\x89PNG\r\n\x1a\n".b
        ihdr = nil
        idat = false
        loop do
          header = file.read(8)
          raise Error, "Truncated PNG" unless header && header.bytesize == 8
          length, kind = header.unpack("Na4")
          raise Error, "Invalid PNG chunk length" if length > File.size(path)
          bytes = file.read(length)
          crc = file.read(4)
          raise Error, "Corrupt PNG" unless bytes && bytes.bytesize == length && crc && crc.bytesize == 4 && Zlib.crc32(kind + bytes) == crc.unpack1("N")
          if ihdr.nil?
            raise Error, "Missing PNG IHDR" unless kind == "IHDR" && length == 13
            ihdr = bytes.unpack("NNCCCCC")
          end
          raise Error, "Transparent PNG is not supported" if kind == "tRNS"
          idat = true if kind == "IDAT"
          break if kind == "IEND" && length.zero?
        end
        raise Error, "Missing PNG image data or trailing bytes" unless idat && file.eof?
        width, height, depth, color = ihdr
        raise Error, "Use a 5244x2950, 8-bit RGB universal PNG without alpha" unless [width, height, depth, color] == [5244, 2950, 8, 2]
        { "width" => width, "height" => height, "bytes" => File.size(path) }
      end
    end
  end

  class Runner
    def initialize(manifest:, client: nil, state_path:, poll_timeout: 300, sleeper: nil, clock: nil)
      @manifest, @client = manifest, client
      @state_path = File.expand_path(state_path)
      @timeout = Float(poll_timeout)
      raise Error, "poll_timeout must be positive" unless @timeout > 0
      @sleep = sleeper || ->(seconds) { sleep(seconds) }
      @clock = clock || -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
    end

    def run(mode:, version: nil)
      raise Error, "Mode must be validate, audit, upload, or place" unless %w[validate audit upload place].include?(mode)
      return summary if mode == "validate"
      raise Error, "place requires an explicit App Store version" if mode == "place" && version.to_s.empty?
      if %w[upload place].include?(mode)
        FileUtils.mkdir_p(File.dirname(@state_path))
        File.open(@state_path + ".lock", File::RDWR | File::CREAT, 0600) do |lock|
          raise Error, "Another creative asset operation is running for this app" unless lock.flock(File::LOCK_EX | File::LOCK_NB)
          remote_run(mode, version)
        end
      else
        remote_run(mode, version)
      end
    end

    private

    def summary
      { "app_id" => @manifest.app_id, "bundle_id" => @manifest.bundle_id,
        "locales" => @manifest.assets.size, "unique_images" => @manifest.unique_assets.size,
        "placements" => @manifest.types, "dimensions" => "5244x2950 RGB PNG" }
    end

    def remote_run(mode, version)
      assert_app!
      @library_id = @client.request("GET", "/v1/apps/#{@manifest.app_id}/assetLibrary").fetch("data").fetch("id")
      @state = File.exist?(@state_path) ? JSON.parse(File.read(@state_path)) : {
        "app_id" => @manifest.app_id, "bundle_id" => @manifest.bundle_id, "library_id" => @library_id, "images" => {}, "placement_intents" => {}
      }
      raise Error, "State file belongs to another app or library" unless @state.values_at("app_id", "bundle_id", "library_id") == [@manifest.app_id, @manifest.bundle_id, @library_id]
      @policies, @spec_ids = reference_specs!
      images = @client.list("/v1/appAssetLibraries/#{@library_id}/images?filter[category]=CREATIVE_ASSETS&limit=200")
      @remote = {}
      @manifest.unique_assets.each do |asset|
        record = @state.fetch("images")[asset["sha256"]]
        matches = images.select { |i| i.dig("attributes", "referenceName") == asset["reference_name"] }
        raise Error, "Duplicate remote references; inspect the asset library before continuing" if matches.size > 1
        image = record && record["id"] ? read_image(record["id"]) : matches.first
        verify_image!(image, asset, processed: false) if image
        @remote[asset["sha256"]] = image
      end
      version_info = version.to_s.empty? ? nil : read_version(version)
      if mode == "upload"
        @manifest.unique_assets.each { |a| @remote[a["sha256"]] = upload(a) }
      elsif mode == "place"
        preflight_placements!(version_info)
        place_all!(version_info)
      end
      placement_report = version_info && %w[audit place].include?(mode) ? audit_placements(version_info) : nil
      summary.merge("mode" => mode, "images" => @manifest.unique_assets.map do |asset|
        image = @remote[asset["sha256"]]
        { "locales" => @manifest.assets.select { |a| a["sha256"] == asset["sha256"] }.map { |a| a["locale"] },
          "id" => image && image["id"], "state" => image ? image.dig("attributes", "state") : "NOT_UPLOADED" }
      end, "version" => version_info && { "number" => version, "state" => version_info["state"],
        "missing_locales" => @manifest.assets.map { |a| a["locale"] } - version_info["localizations"].keys },
        "remote_placements" => placement_report)
    end

    def assert_app!
      app = @client.request("GET", "/v1/apps/#{@manifest.app_id}").fetch("data")
      raise Error, "Apple app ID does not match the expected bundle ID" unless app.dig("attributes", "bundleId") == @manifest.bundle_id
    end

    def reference_specs!
      refs = @client.request("GET", "/v1/appAssetLibraryRefData").fetch("data")
      refs = [refs] unless refs.is_a?(Array)
      attrs = refs.map { |r| r.fetch("attributes") }
      specs = attrs.flat_map { |a| a.fetch("imageSpecs") }.select do |s|
        d = s.fetch("dimensions")
        d.values_at("minWidth", "maxWidth", "minHeight", "maxHeight") == [5244, 5244, 2950, 2950] &&
          s["alphaAllowed"] == false && s.fetch("fileExtensions").include?(".png") &&
          @manifest.unique_assets.all? { |a| a["bytes"] <= s.fetch("maxFileSize") }
      end.map { |s| s.fetch("specId") }
      policies = {}
      @manifest.types.each do |key|
        type = TYPES.fetch(key)
        type_data = attrs.flat_map { |a| a.fetch("placementTypes") }.find { |t| t["placementTypeId"] == type }
        feature = attrs.flat_map { |a| a.fetch("features") }.find { |f| f["featureId"] == "APP_STORE_VERSIONS" }
        policy = feature && feature.fetch("placementPolicies").find { |p| p["placementType"] == type }
        raise Error, "Creative placement is unavailable in current ASC reference data" unless type_data && policy && type_data.fetch("acceptsAssetCategories").include?("CREATIVE_ASSETS")
        eligible = type_data.fetch("specMappings").select { |m| (m.fetch("specs") & specs).any? }
        raise Error, "Universal creative specification/group is missing or ambiguous" unless eligible.size == 1
        mapping = eligible.first
        limit = policy.fetch("groupLimits").find { |l| l.fetch("groupIds").include?(mapping.fetch("placementGroupId")) }
        raise Error, "Unexpected creative placement limit" unless limit && limit["maxCount"] == 1
        specs &= mapping.fetch("specs")
        policies[key] = { "type" => type, "group" => mapping.fetch("placementGroupId") }
      end
      raise Error, "No common universal image specification for requested placements" if specs.empty?
      [policies, specs]
    end

    def read_image(id)
      @client.request("GET", "/v1/appAssetLibraryImages/#{id}").fetch("data")
    end

    def verify_image!(image, asset, processed:)
      attrs = image.fetch("attributes")
      raise Error, "Remote image differs from the recorded upload intent" unless attrs.values_at("referenceName", "category", "fileSize") == [asset["reference_name"], "CREATIVE_ASSETS", asset["bytes"]]
      raise Error, "Image #{image['id']} is #{attrs['state']}; inspect ASC before continuing" if %w[FAILED REJECTED ARCHIVED].include?(attrs["state"])
      if processed
        raise Error, "Image #{image['id']} is not processed yet" unless READY.include?(attrs["state"])
        raise Error, "Processed image specification/dimensions differ" unless @spec_ids.include?(attrs["specId"]) && attrs.fetch("imageAsset").values_at("width", "height") == [5244, 2950]
      end
    end

    def upload(asset)
      image = @remote[asset["sha256"]]
      record = @state.fetch("images")[asset["sha256"]]
      if !image && record
        raise Error, "An earlier reservation has an uncertain result; audit until its reference appears. Do not reserve again"
      end
      if !image
        verify_local!(asset)
        assert_app!
        @state["images"][asset["sha256"]] = { "reference_name" => asset["reference_name"], "phase" => "RESERVATION_PENDING" }
        save_state!
        image = @client.request("POST", "/v1/appAssetLibraryImages", { "data" => {
          "type" => "appAssetLibraryImages", "attributes" => { "fileName" => File.basename(asset["file"]),
            "fileSize" => asset["bytes"], "category" => "CREATIVE_ASSETS", "referenceName" => asset["reference_name"] },
          "relationships" => { "assetLibrary" => { "data" => { "type" => "appAssetLibraries", "id" => @library_id } } }
        } }).fetch("data")
      end
      verify_image!(image, asset, processed: false)
      @state["images"][asset["sha256"]] = { "id" => image.fetch("id"), "reference_name" => asset["reference_name"], "phase" => image.dig("attributes", "state") }
      save_state!
      if image.dig("attributes", "state") == "AWAITING_UPLOAD"
        image = read_image(image.fetch("id"))
        verify_image!(image, asset, processed: false)
        if image.dig("attributes", "state") == "AWAITING_UPLOAD"
          verify_local!(asset)
          operations = image.dig("attributes", "uploadOperations")
          raise Error, "No upload operations; inspect the existing reservation" unless operations && !operations.empty?
          ranges = operations.map { |o| [Integer(o.fetch("offset")), Integer(o.fetch("length"))] }.sort
          cursor = 0
          ranges.each do |offset, length|
            raise Error, "Upload byte ranges do not cover the PNG exactly" unless offset == cursor && length > 0
            cursor += length
          end
          raise Error, "Upload byte ranges differ from declared size" unless cursor == asset["bytes"]
          File.open(asset["file"], "rb") do |file|
            operations.each do |operation|
              file.seek(Integer(operation.fetch("offset")))
              @client.transfer(operation, file.read(Integer(operation.fetch("length"))))
            end
          end
          assert_app!
          image = @client.request("PATCH", "/v1/appAssetLibraryImages/#{image['id']}", { "data" => {
            "type" => "appAssetLibraryImages", "id" => image["id"], "attributes" => { "uploaded" => true }
          } }).fetch("data")
        end
      end
      deadline = @clock.call + @timeout
      until READY.include?(image.dig("attributes", "state"))
        verify_image!(image, asset, processed: false)
        raise Error, "Processing timeout for #{image['id']}; rerun audit/upload to resume without another reservation" if @clock.call >= deadline
        @sleep.call(5)
        image = read_image(image.fetch("id"))
      end
      verify_image!(image, asset, processed: true)
      @state["images"][asset["sha256"]]["phase"] = image.dig("attributes", "state")
      save_state!
      image
    end

    def verify_local!(asset)
      raise Error, "Creative file changed since preflight" unless File.size(asset["file"]) == asset["bytes"] && Digest::SHA256.file(asset["file"]).hexdigest == asset["sha256"]
    end

    def read_version(version)
      path = "/v1/apps/#{@manifest.app_id}/appStoreVersions?" + URI.encode_www_form("filter[versionString]" => version, "filter[platform]" => "IOS")
      versions = @client.list(path)
      raise Error, "Target iOS App Store version is missing or ambiguous; create it in the normal release flow first" unless versions.size == 1
      target = versions.first
      locales = @client.list("/v1/appStoreVersions/#{target['id']}/appStoreVersionLocalizations?limit=200")
      { "id" => target.fetch("id"), "state" => target.dig("attributes", "appStoreState"),
        "localizations" => locales.each_with_object({}) { |l, hash| hash[l.dig("attributes", "locale")] = l.fetch("id") } }
    end

    def preflight_placements!(version_info)
      raise Error, "Target version is locked (#{version_info['state']}); use ASC's approved-asset flow for a live version" unless EDITABLE.include?(version_info["state"])
      missing = @manifest.assets.map { |a| a["locale"] } - version_info["localizations"].keys
      raise Error, "Target version is missing localizations: #{missing.join(', ')}" unless missing.empty?
      @manifest.unique_assets.each do |asset|
        image = @remote[asset["sha256"]]
        raise Error, "Upload the creative images before placing them" unless image
        verify_image!(read_image(image.fetch("id")), asset, processed: true)
      end
      @manifest.assets.each do |asset|
        placements = read_placements(version_info["localizations"].fetch(asset["locale"]))
        @manifest.types.each { |key| check_slot!(placements, key, @remote[asset["sha256"]].fetch("id"), asset["locale"]) }
      end
    end

    def read_placements(localization_id)
      query = URI.encode_www_form("filter[placementType]" => @manifest.types.map { |key| TYPES.fetch(key) }.join(","), "include" => "image", "limit" => 200)
      @client.list("/v1/appStoreVersionLocalizations/#{localization_id}/placements?#{query}")
    end

    def audit_placements(version_info)
      slots = @manifest.assets.flat_map do |asset|
        loc_id = version_info["localizations"][asset["locale"]]
        placements = loc_id ? read_placements(loc_id) : []
        @manifest.types.map do |key|
          policy = @policies.fetch(key)
          found = placements.select { |p| p.dig("attributes", "placementType") == policy["type"] && p.dig("attributes", "placementGroup") == policy["group"] }
          intended_id = @remote[asset["sha256"]] && @remote[asset["sha256"]]["id"]
          status = if !loc_id
            "MISSING_LOCALIZATION"
          elsif found.empty?
            "EMPTY"
          elsif found.size > 1
            "CONFLICT"
          elsif intended_id && found.first.dig("relationships", "image", "data", "id") == intended_id
            "MATCHES_MANIFEST"
          else
            "OTHER_ARTWORK"
          end
          { "locale" => asset["locale"], "placement" => key, "status" => status,
            "resources" => found.map { |p| { "id" => p["id"], "image_id" => p.dig("relationships", "image", "data", "id"), "state" => p.dig("attributes", "state") } } }
        end
      end
      { "counts" => slots.each_with_object(Hash.new(0)) { |slot, counts| counts[slot["status"]] += 1 }, "slots" => slots }
    end

    def check_slot!(placements, key, image_id, locale)
      policy = @policies.fetch(key)
      matches = placements.select { |p| p.dig("attributes", "placementType") == policy["type"] && p.dig("attributes", "placementGroup") == policy["group"] }
      if matches.size > 1 || (matches.first && matches.first.dig("relationships", "image", "data", "id") != image_id)
        raise Error, "#{locale} #{key} already has a different placement; inspect/replace it in ASC within the authorized scope"
      end
      matches.first
    end

    def place_all!(version_info)
      @manifest.assets.each do |asset|
        loc_id = version_info["localizations"].fetch(asset["locale"])
        image_id = @remote[asset["sha256"]].fetch("id")
        @manifest.types.each do |key|
          assert_app!
          parent = @client.request("GET", "/v1/appStoreVersions/#{version_info['id']}").fetch("data")
          raise Error, "Target version became locked; no placement was changed" unless EDITABLE.include?(parent.dig("attributes", "appStoreState"))
          existing = check_slot!(read_placements(loc_id), key, image_id, asset["locale"])
          next if existing
          intent_key = "#{loc_id}:#{key}"
          raise Error, "A prior placement write is awaiting reconciliation; audit ASC before retrying" if @state.fetch("placement_intents").key?(intent_key)
          verify_image!(read_image(image_id), asset, processed: true)
          @state["placement_intents"][intent_key] = { "image_id" => image_id, "phase" => "CREATE_PENDING" }
          save_state!
          policy = @policies.fetch(key)
          placement = @client.request("POST", "/v1/appAssetLibraryPlacements", { "data" => {
            "type" => "appAssetLibraryPlacements", "attributes" => { "placementType" => policy["type"], "placementGroup" => policy["group"] },
            "relationships" => { "image" => { "data" => { "type" => "appAssetLibraryImages", "id" => image_id } },
              "appStoreVersionLocalization" => { "data" => { "type" => "appStoreVersionLocalizations", "id" => loc_id } } }
          } }).fetch("data")
          @state["placement_intents"][intent_key] = { "image_id" => image_id, "id" => placement.fetch("id"), "phase" => "CREATED" }
          save_state!
          verified = @client.request("GET", "/v1/appAssetLibraryPlacements/#{placement['id']}").fetch("data")
          raise Error, "Placement verification failed; inspect ASC" unless verified.dig("relationships", "image", "data", "id") == image_id && verified.dig("attributes", "placementType") == policy["type"] && verified.dig("attributes", "placementGroup") == policy["group"]
        end
      end
    end

    def save_state!
      temp = @state_path + ".tmp-#{Process.pid}"
      File.open(temp, File::WRONLY | File::CREAT | File::TRUNC, 0600) do |file|
        file.write(JSON.pretty_generate(@state) + "\n")
        file.flush
        file.fsync
      end
      File.rename(temp, @state_path)
    end
  end
end
