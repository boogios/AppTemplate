#!/usr/bin/env ruby
# Sequential screenshot sync. No network or credentials are loaded on require.
require "json"
require "digest"
require "fileutils"
require "optparse"

module StoreScreenshots
  class Error < StandardError; end

  class Sync
    attr_reader :changed
    def initialize(adapter:, manifest:, state_path:, polls: 10, interval: 3)
      @adapter, @manifest, @path = adapter, manifest, state_path
      @polls, @interval = polls, interval
      @changed = false
      @state = File.file?(@path) ? JSON.parse(File.read(@path)) : {}
    end

    def write(key, value)
      @state[key] = value
      FileUtils.mkdir_p(File.dirname(@path))
      temporary = "#{@path}.tmp"
      File.write(temporary, JSON.pretty_generate(@state))
      File.rename(temporary, @path)
    end

    def poll
      @polls.times do |i|
        value = yield
        return value if value
        sleep(@interval) if i + 1 < @polls
      end
      raise Error, "Remote screenshots unresolved; audit again before retrying any upload"
    end

    def hashes(snapshot)
      images = snapshot.fetch(:images)
      return nil unless images.all? { |image| image[:complete] && image[:checksum] }
      values = images.map { |image| image[:checksum].downcase }
      return nil unless values.uniq.length == values.length
      values
    end

    def run(upload: false)
      @manifest.fetch("sets").each do |entry|
        key = [entry.fetch("locale"), entry.fetch("display_type")].join("/")
        algorithm = @adapter.checksum_algorithm
        paths = entry.fetch("images").map do |image|
          root = File.realpath(@manifest.fetch("root"))
          path = File.realpath(File.join(root, image.fetch("path")))
          raise Error, "Image escapes upload root" unless path.start_with?(root + File::SEPARATOR)
          actual = Digest.const_get(algorithm.upcase).file(path).hexdigest
          raise Error, "Local image changed since validation" unless actual == image.fetch(algorithm)
          path
        end
        expected = entry["images"].map { |image| image.fetch(algorithm) }
        fingerprint = Digest::SHA256.hexdigest(expected.join("/"))
        snapshot = poll { row = @adapter.snapshot(entry); hashes(row) ? row : nil }
        actual = hashes(snapshot)
        if actual == expected
          write(key, {"fingerprint" => fingerprint, "phase" => "verified"}) if upload
          puts "Verified #{key}: #{expected.length}, ordered checksums equal"
          next
        end
        raise Error, "Screenshot mismatch: #{key}; upload is disabled" unless upload
        prior = @state[key]
        if prior && prior["phase"] != "verified" && prior["fingerprint"] != fingerprint
          raise Error, "Unresolved prior operation for #{key}; reconcile before changing inputs"
        end
        prior = nil if prior && prior["fingerprint"] != fingerprint

        if prior && prior["phase"] == "pending_upload"
          count = prior.fetch("index") + 1
          snapshot = poll do
            row = @adapter.snapshot(entry)
            hashes(row) == expected.first(count) ? row : nil
          end
          actual = hashes(snapshot)
          write(key, {"fingerprint" => fingerprint, "phase" => "uploading"})
        elsif prior && prior["phase"] == "clearing"
          snapshot = poll { row = @adapter.snapshot(entry); hashes(row) == [] ? row : nil }
          actual = []
        elsif prior && prior["phase"] == "pending_prepare"
          snapshot = poll { row = @adapter.snapshot(entry); row[:exists] && hashes(row) == [] ? row : nil }
          actual = []
        elsif !(prior && prior["phase"] == "uploading")
          write(key, {"fingerprint" => fingerprint, "phase" => "clearing"})
          @changed = true
          @adapter.clear(entry, snapshot)
          snapshot = poll { row = @adapter.snapshot(entry); hashes(row) == [] ? row : nil }
          actual = []
        end
        raise Error, "Unexpected remote prefix for #{key}; reconcile manually" unless actual == expected.first(actual.length)
        unless snapshot[:exists]
          write(key, {"fingerprint" => fingerprint, "phase" => "pending_prepare"})
          @changed = true
          @adapter.prepare(entry)
        end
        write(key, {"fingerprint" => fingerprint, "phase" => "uploading"})
        (actual.length...paths.length).each do |index|
          write(key, {"fingerprint" => fingerprint, "phase" => "pending_upload", "index" => index})
          @changed = true
          @adapter.upload(entry, paths[index])
          poll { row = @adapter.snapshot(entry); hashes(row) == expected.first(index + 1) ? row : nil }
          write(key, {"fingerprint" => fingerprint, "phase" => "uploading"})
        end
        poll { row = @adapter.snapshot(entry); hashes(row) == expected ? row : nil }
        write(key, {"fingerprint" => fingerprint, "phase" => "verified"})
        puts "Verified #{key}: #{expected.length}, ordered checksums equal"
      end
    end
  end

  class IOS
    def initialize(identifier, version, credentials)
      require "spaceship"
      require "deliver/app_screenshot"
      raise Error, "Fastlane with APP_IPHONE_DUO support required (validated: 2.241.2)" unless Spaceship::ConnectAPI::AppScreenshotSet::DisplayType.const_defined?(:APP_IPHONE_DUO)
      Spaceship::ConnectAPI.token = Spaceship::ConnectAPI::Token.create(**credentials, in_house: false)
      app = Spaceship::ConnectAPI::App.find(identifier)
      raise Error, "App not found" unless app
      @version = app.get_app_store_versions(filter: {versionString: version, platform: "IOS"}).first
      raise Error, "App Store version not found" unless @version
      @locales = @version.get_app_store_version_localizations.to_h { |row| [row.locale, row] }
    end

    def editable!
      allowed = %w[PREPARE_FOR_SUBMISSION READY_FOR_REVIEW DEVELOPER_REJECTED REJECTED METADATA_REJECTED INVALID_BINARY]
      raise Error, "Version is locked or under review; no automatic cancellation" unless allowed.include?(@version.app_store_state)
    end

    def checksum_algorithm; "md5"; end
    def find(entry)
      locale = @locales[entry.fetch("locale")]
      raise Error, "Missing App Store localization: #{entry['locale']}" unless locale
      matches = locale.get_app_screenshot_sets.select { |row| row.screenshot_display_type == entry["display_type"] }
      raise Error, "Duplicate remote screenshot sets" if matches.length > 1
      matches.first
    end

    def snapshot(entry)
      set = find(entry)
      {exists: !set.nil?, images: (set&.app_screenshots || []).map { |image|
        {checksum: image.source_file_checksum, complete: image.complete?}
      }}
    end

    def clear(entry, _snapshot)
      editable!
      find(entry)&.delete!
    end

    def prepare(entry)
      editable!
      @locales.fetch(entry["locale"]).create_app_screenshot_set(attributes: {screenshotDisplayType: entry["display_type"]}) unless find(entry)
    end

    def upload(entry, path)
      editable!
      set = find(entry)
      raise Error, "Screenshot set not visible; audit again" unless set
      set.upload_screenshot(path: path, wait_for_processing: false)
    end
  end

  class Android
    attr_reader :client
    def initialize(identifier, key)
      require "supply"
      Supply.config = FastlaneCore::Configuration.create(Supply::Options.available_options, {
        package_name: identifier, json_key: key, changes_not_sent_for_review: true,
        rescue_changes_not_sent_for_review: false
      })
      @client = Supply::Client.make_from_config
      @identifier = identifier
      begin_edit
    end
    def begin_edit; @client.begin_edit(package_name: @identifier); end
    def checksum_algorithm; "sha256"; end
    def snapshot(entry)
      {exists: true, images: @client.fetch_images(image_type: entry["display_type"], language: entry["locale"]).map { |row|
        {checksum: row.sha256, complete: !row.sha256.nil?}
      }}
    end
    def clear(entry, _snapshot); @client.clear_screenshots(image_type: entry["display_type"], language: entry["locale"]); end
    def prepare(_entry); end
    def upload(entry, path); @client.upload_image(image_path: path, image_type: entry["display_type"], language: entry["locale"]); end
    def commit; @client.commit_current_edit!; end
    def abort_edit; @client.abort_current_edit if @client.current_edit; end
  end

  def self.environment(*names)
    names.map { |key| ENV[key].to_s.strip }.find { |value| !value.empty? }
  end

  def self.poll_options(env = ENV)
    attempts = Integer(env.fetch("STORE_SCREENSHOT_POLL_ATTEMPTS", "10"))
    interval = Integer(env.fetch("STORE_SCREENSHOT_POLL_INTERVAL", "3"))
    unless (1..100).cover?(attempts) && (1..30).cover?(interval) && attempts * interval <= 300
      raise Error, "Screenshot processing wait must use 1..100 polls, 1..30 seconds and at most 300 seconds total"
    end
    {polls: attempts, interval: interval}
  rescue ArgumentError, TypeError
    raise Error, "Screenshot poll settings must be integers"
  end

  def self.cli(argv = ARGV)
    args = {mode: "audit"}
    OptionParser.new do |parser|
      parser.on("--manifest PATH") { |value| args[:manifest] = value }
      parser.on("--state PATH") { |value| args[:state] = value }
      parser.on("--upload") { args[:mode] = "upload" }
      parser.on("--replace") { args[:mode] = "upload" } # old skill CLI alias
    end.parse!(argv)
    raise Error, "Unknown arguments" unless argv.empty?
    raise Error, "--manifest required; run local validation first" unless args[:manifest]
    polling = poll_options
    manifest = JSON.parse(File.read(args[:manifest]))
    raise Error, "Invalid screenshot manifest" unless manifest["schema_version"] == 1 && !manifest.fetch("sets").empty?
    platform = manifest.fetch("platform")
    raise Error, "Unsupported platform" unless %w[ios android].include?(platform)
    identifier = environment(platform == "ios" ? "APP_IDENTIFIER" : "ANDROID_PACKAGE_NAME", "BUNDLE_IDENTIFIER")
    raise Error, "App identifier required" unless identifier
    version = platform == "ios" ? environment("APP_VERSION") : "listing"
    raise Error, "APP_VERSION required" unless version
    identity = Digest::SHA256.hexdigest([platform, identifier, version].join('/'))
    state_path = args[:state] || File.join(File.dirname(args[:manifest]), '.screenshot-state', identity + '.json')
    FileUtils.mkdir_p(File.dirname(state_path))
    lock = File.open(state_path + '.lock', File::RDWR | File::CREAT, 0600)
    raise Error, "Another screenshot operation is running for this app/version" unless lock.flock(File::LOCK_EX | File::LOCK_NB)
    upload = args[:mode] == "upload"
    if platform == "ios"
      key_path = environment("APP_STORE_CONNECT_API_KEY_PATH", "ASC_KEY_FILEPATH")
      credentials = {key_id: environment("APP_STORE_CONNECT_API_KEY_KEY_ID", "ASC_KEY_ID"),
        issuer_id: environment("APP_STORE_CONNECT_API_KEY_ISSUER_ID", "ASC_ISSUER_ID"), filepath: key_path}
      raise Error, "Missing App Store credentials" if credentials.values.any?(&:nil?) || !File.readable?(File.expand_path(key_path))
      credentials[:filepath] = File.expand_path(key_path)
      adapter = IOS.new(identifier, version, credentials)
      adapter.editable! if upload
      Sync.new(adapter: adapter, manifest: manifest, state_path: state_path, **polling).run(upload: upload)
    else
      key = environment("BOOGIOS_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON", "SUPPLY_JSON_KEY_PATH", "SUPPLY_JSON_KEY", "GOOGLE_PLAY_JSON_KEY", "GOOGLE_APPLICATION_CREDENTIALS") || File.expand_path("~/.config/boogios/google-play-service-account.json")
      raise Error, "Shared Play service account file missing" unless File.readable?(File.expand_path(key))
      adapter = Android.new(identifier, File.expand_path(key))
      fingerprint = Digest::SHA256.hexdigest(JSON.generate(manifest.fetch("sets")))
      if File.file?(state_path) && (prior = JSON.parse(File.read(state_path)))["phase"] == "pending_commit"
        begin
          raise Error, "Uncertain prior Play commit with different inputs; reconcile first" unless prior["fingerprint"] == fingerprint
          Sync.new(adapter: adapter, manifest: manifest, state_path: state_path + '.audit', **polling).run(upload: false)
          File.write(state_path, JSON.generate({"phase" => "verified", "fingerprint" => fingerprint}))
          puts "Prior Play commit verified; no repeated upload"
          return 0
        ensure
          adapter.abort_edit
        end
      end
      # An edit is atomic. Never reuse an uncommitted edit's local upload ledger.
      edit_state = state_path + ".edit-#{adapter.client.current_edit.id}"
      begin
        sync = Sync.new(adapter: adapter, manifest: manifest, state_path: edit_state, **polling)
        sync.run(upload: upload)
        if upload && sync.changed
          # Save commit intent: an uncertain commit is reconciled by a fresh read,
          # never automatically committed again on the next invocation.
          FileUtils.mkdir_p(File.dirname(state_path))
          File.write(state_path, JSON.generate({"phase" => "pending_commit", "fingerprint" => fingerprint}))
          adapter.commit
          adapter.begin_edit
          Sync.new(adapter: adapter, manifest: manifest, state_path: edit_state, **polling).run(upload: false)
          File.write(state_path, JSON.generate({"phase" => "verified"}))
        end
      ensure
        adapter.abort_edit
        File.delete(edit_state) if File.file?(edit_state)
      end
    end
    puts "Screenshot remote verification complete"
    0
  rescue Error, StandardError => error
    warn(error.is_a?(Error) ? error.message : "Screenshot operation failed (#{error.class}); reconcile remote state before retry")
    1
  ensure
    lock&.flock(File::LOCK_UN)
    lock&.close
  end
end

exit(StoreScreenshots.cli) if $PROGRAM_NAME == __FILE__
