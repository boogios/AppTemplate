# frozen_string_literal: true
require "minitest/autorun"
require "tmpdir"
require_relative "../app_store_creative_assets"

class CreativeAssetsTest < Minitest::Test
  A = AppStoreCreativeAssets

  class FakeClient
    attr_reader :writes, :transfers, :images, :placements
    attr_accessor :version_state, :processing, :lose_reservation_response, :hide_images, :bundle_id, :image_dimensions

    def initialize
      @writes, @transfers, @images, @placements = [], [], [], []
      @version_state = "PREPARE_FOR_SUBMISSION"
      @bundle_id = "com.example.app"
      @image_dimensions = [5244, 2950]
    end

    def reference
      types = A::TYPES.values
      { "data" => [{ "attributes" => {
        "imageSpecs" => [{ "specId" => "live-spec", "dimensions" => { "minWidth" => 5244, "maxWidth" => 5244, "minHeight" => 2950, "maxHeight" => 2950 }, "alphaAllowed" => false, "fileExtensions" => [".png"], "maxFileSize" => 1000000 }],
        "placementTypes" => types.map { |type| { "placementTypeId" => type, "acceptsAssetCategories" => ["CREATIVE_ASSETS"], "specMappings" => [{ "placementGroupId" => "live-group", "specs" => ["live-spec"] }] } },
        "features" => [{ "featureId" => "APP_STORE_VERSIONS", "placementPolicies" => types.map { |type| { "placementType" => type, "groupLimits" => [{ "groupIds" => ["live-group"], "maxCount" => 1 }] } } }]
      } }] }
    end

    def request(method, path, payload = nil)
      @writes << [method, path, payload] unless method == "GET"
      result = case [method, path]
      when ["GET", "/v1/apps/123"] then { "data" => { "id" => "123", "attributes" => { "bundleId" => @bundle_id } } }
      when ["GET", "/v1/apps/123/assetLibrary"] then { "data" => { "id" => "library" } }
      when ["GET", "/v1/appAssetLibraryRefData"] then reference
      when ["GET", "/v1/appStoreVersions/version"] then { "data" => { "attributes" => { "appStoreState" => @version_state } } }
      when ["POST", "/v1/appAssetLibraryImages"]
        id = "image-#{@images.size + 1}"
        attrs = payload.fetch("data").fetch("attributes").merge("state" => "AWAITING_UPLOAD", "uploadOperations" => [{ "method" => "PUT", "url" => "https://secret-upload.invalid/secret", "offset" => 0, "length" => payload.dig("data", "attributes", "fileSize"), "requestHeaders" => [] }])
        image = { "id" => id, "attributes" => attrs }
        @images << image
        raise A::Error, "Lost POST response" if @lose_reservation_response
        { "data" => image }
      when ["POST", "/v1/appAssetLibraryPlacements"]
        placement = payload.fetch("data").merge("id" => "placement-#{@placements.size + 1}")
        @placements << placement
        { "data" => placement }
      else
        if method == "GET" && path.start_with?("/v1/appAssetLibraryImages/")
          { "data" => @images.find { |i| i["id"] == path.split("/").last } }
        elsif method == "PATCH" && path.start_with?("/v1/appAssetLibraryImages/")
          image = @images.find { |i| i["id"] == path.split("/").last }
          image["attributes"].merge!("state" => @processing ? "UPLOAD_COMPLETE" : "PREPARE_FOR_SUBMISSION", "specId" => "live-spec", "imageAsset" => { "width" => @image_dimensions[0], "height" => @image_dimensions[1] })
          { "data" => image }
        elsif method == "GET" && path.start_with?("/v1/appAssetLibraryPlacements/")
          { "data" => @placements.find { |p| p["id"] == path.split("/").last } }
        else
          raise "Unexpected request #{method} #{path}"
        end
      end
      # Simulate detached JSON responses instead of aliasing the server's state.
      JSON.parse(JSON.generate(result))
    end

    def list(path)
      if path.start_with?("/v1/appAssetLibraries/")
        @hide_images ? [] : JSON.parse(JSON.generate(@images))
      elsif path.start_with?("/v1/apps/123/appStoreVersions")
        [{ "id" => "version", "attributes" => { "appStoreState" => @version_state } }]
      elsif path.start_with?("/v1/appStoreVersions/version/appStoreVersionLocalizations")
        %w[en-US en-GB].map { |locale| { "id" => locale, "attributes" => { "locale" => locale } } }
      elsif path.start_with?("/v1/appStoreVersionLocalizations/")
        locale = path.split("/")[3]
        @placements.select { |p| p.dig("relationships", "appStoreVersionLocalization", "data", "id") == locale }
      else
        raise "Unexpected list #{path}"
      end
    end

    def transfer(operation, bytes)
      @transfers << bytes.bytesize
      raise "Transfer size differs" unless bytes.bytesize == operation.fetch("length")
    end
  end

  def setup
    @dir = Dir.mktmpdir("creative-assets-test-")
    # Minimal fixture; full production PNGs are verified by the real lane as well.
    chunk = ->(kind, bytes) { [bytes.bytesize].pack("N") + kind + bytes + [Zlib.crc32(kind + bytes)].pack("N") }
    @png = File.join(@dir, "universal.png")
    File.binwrite(@png, "\x89PNG\r\n\x1a\n".b + chunk.call("IHDR", [5244, 2950, 8, 2, 0, 0, 0].pack("NNCCCCC")) + chunk.call("IDAT", Zlib.deflate("test")) + chunk.call("IEND", ""))
    @json = File.join(@dir, "manifest.json")
    @state = File.join(@dir, "state", "123.json")
    @data = { "app_id" => "123", "bundle_id" => "com.example.app", "assets" => %w[en-US en-GB].map { |locale| { "locale" => locale, "file" => "universal.png", "sha256" => Digest::SHA256.file(@png).hexdigest } } }
    write_manifest
    @client = FakeClient.new
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def write_manifest
    File.write(@json, JSON.generate(@data))
  end

  def runner(timeout: 10)
    time = 0
    A::Runner.new(manifest: A::Manifest.new(@json, expected_bundle_id: "com.example.app"), client: @client, state_path: @state,
      poll_timeout: timeout, clock: -> { time }, sleeper: ->(seconds) { time += seconds })
  end

  def upload
    runner.run(mode: "upload")
  end

  def test_local_validate_needs_no_network_or_state
    result = runner.run(mode: "validate")
    assert_equal 2, result["locales"]
    assert_equal 1, result["unique_images"]
    refute File.exist?(@state)
    assert_empty @client.writes
  end

  def test_audit_is_read_only
    result = runner.run(mode: "audit", version: "1.0")
    assert_equal "NOT_UPLOADED", result["images"].first["state"]
    assert_empty result["version"]["missing_locales"]
    assert_equal({ "EMPTY" => 4 }, result["remote_placements"]["counts"])
    assert_empty @client.writes
    refute File.exist?(@state)
  end

  def test_duplicate_art_uploads_once_and_commit_has_no_old_checksum
    upload
    assert_equal 1, @client.images.size
    assert_equal [File.size(@png)], @client.transfers
    patch = @client.writes.find { |w| w[0] == "PATCH" }
    assert_equal({ "uploaded" => true }, patch[2].dig("data", "attributes"))
    refute_includes File.read(@state), "secret-upload"
    @client.hide_images = true
    upload
    assert_equal 1, @client.images.size
    assert_equal 1, @client.transfers.size
  end

  def test_processing_timeout_resumes_without_new_reservation
    @client.processing = true
    assert_raises(A::Error) { runner(timeout: 5).run(mode: "upload") }
    @client.images.first["attributes"]["state"] = "PREPARE_FOR_SUBMISSION"
    upload
    assert_equal 1, @client.images.size
    assert_equal 1, @client.transfers.size
  end

  def test_lost_reservation_response_does_not_duplicate
    @client.lose_reservation_response = true
    assert_raises(A::Error) { upload }
    @client.hide_images = true
    assert_raises(A::Error) { upload }
    assert_equal 1, @client.images.size
    @client.hide_images = false
    @client.lose_reservation_response = false
    upload
    assert_equal 1, @client.images.size
  end

  def test_wrong_remote_bundle_stops_before_writes
    @client.bundle_id = "com.other.app"
    assert_raises(A::Error) { upload }
    assert_empty @client.writes
  end

  def test_modified_art_stops_before_writes
    @data["assets"].last["sha256"] = "0" * 64
    write_manifest
    assert_raises(A::Error) { upload }
    assert_empty @client.writes
  end

  def test_live_parent_stops_before_any_placement
    upload
    @client.version_state = "READY_FOR_SALE"
    before = @client.writes.size
    assert_raises(A::Error) { runner.run(mode: "place", version: "1.0") }
    assert_equal before, @client.writes.size
  end

  def test_places_all_locales_and_is_idempotent
    upload
    result = runner.run(mode: "place", version: "1.0")
    assert_equal({ "MATCHES_MANIFEST" => 4 }, result["remote_placements"]["counts"])
    assert_equal 4, @client.placements.size
    assert_equal ["live-group"], @client.placements.map { |p| p.dig("attributes", "placementGroup") }.uniq
    runner.run(mode: "place", version: "1.0")
    assert_equal 4, @client.placements.size
  end

  def test_conflicting_existing_art_stops_all_writes
    upload
    @client.placements << { "id" => "existing", "attributes" => { "placementType" => A::TYPES["header"], "placementGroup" => "live-group" }, "relationships" => { "image" => { "data" => { "id" => "old-art" } }, "appStoreVersionLocalization" => { "data" => { "id" => "en-GB" } } } }
    before = @client.writes.size
    assert_raises(A::Error) { runner.run(mode: "place", version: "1.0") }
    assert_equal before, @client.writes.size
  end

  def test_missing_locale_stops_all_placement_writes
    upload
    @data["assets"] << @data["assets"].first.merge("locale" => "ko")
    write_manifest
    before = @client.writes.size
    assert_raises(A::Error) { runner.run(mode: "place", version: "1.0") }
    assert_equal before, @client.writes.size
  end

  def test_unexpected_processed_dimensions_stop_upload_success
    @client.image_dimensions = [100, 100]
    assert_raises(A::Error) { upload }
    assert_empty @client.placements
  end
end
