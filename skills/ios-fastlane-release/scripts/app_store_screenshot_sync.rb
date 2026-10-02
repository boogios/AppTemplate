#!/usr/bin/env ruby

require "digest/md5"
require "deliver/app_screenshot"
require "spaceship"

REPLACE = ARGV.delete("--replace")
abort("Unknown arguments: #{ARGV.join(' ')}") unless ARGV.empty?

def required_env(name)
  value = ENV[name].to_s.strip
  abort("Missing required environment variable: #{name}") if value.empty?
  value
end

app_identifier = required_env("APP_IDENTIFIER")
version_string = required_env("APP_VERSION")
screenshots_path = File.expand_path(required_env("SCREENSHOTS_PATH"))
key_id = required_env("APP_STORE_CONNECT_API_KEY_KEY_ID")
issuer_id = required_env("APP_STORE_CONNECT_API_KEY_ISSUER_ID")
key_path = File.expand_path(required_env("APP_STORE_CONNECT_API_KEY_PATH"))

abort("Screenshots directory not found: #{screenshots_path}") unless Dir.exist?(screenshots_path)
abort("App Store Connect key not found: #{key_path}") unless File.exist?(key_path)

local = {}
Dir[File.join(screenshots_path, "*")].sort.each do |locale_dir|
  next unless File.directory?(locale_dir)

  locale = File.basename(locale_dir)
  Dir[File.join(locale_dir, "*.png")].sort.each do |path|
    screenshot = Deliver::AppScreenshot.new(path, locale)
    display_type = screenshot.device_type
    abort("Unsupported screenshot dimensions: #{path}") if display_type.nil?
    local[locale] ||= {}
    local[locale][display_type] ||= []
    local[locale][display_type] << path
  end
end

abort("No local screenshots found in #{screenshots_path}") if local.empty?

local.each do |locale, sets|
  sets.each do |display_type, paths|
    abort("#{locale} #{display_type} has #{paths.length} screenshots; App Store Connect allows at most 10") if paths.length > 10
    checksums = paths.map { |path| Digest::MD5.file(path).hexdigest }
    duplicates = checksums.group_by(&:itself).select { |_, values| values.length > 1 }
    abort("#{locale} #{display_type} has duplicate local screenshots") unless duplicates.empty?
  end
end

token = Spaceship::ConnectAPI::Token.create(
  key_id: key_id,
  issuer_id: issuer_id,
  filepath: key_path,
  in_house: false
)
Spaceship::ConnectAPI.token = token

app = Spaceship::ConnectAPI::App.find(app_identifier)
abort("App not found: #{app_identifier}") unless app

version = app.get_app_store_versions(
  filter: { versionString: version_string, platform: "IOS" }
).first
abort("App Store version not found: #{version_string}") unless version

localizations = version.get_app_store_version_localizations
localization_by_locale = localizations.to_h { |localization| [localization.locale, localization] }
missing_locales = local.keys - localization_by_locale.keys
abort("Missing App Store localizations: #{missing_locales.join(', ')}") unless missing_locales.empty?

if REPLACE
  local.each do |locale, sets|
    localization = localization_by_locale.fetch(locale)
    existing = localization.get_app_screenshot_sets
    existing.each do |set|
      next unless sets.key?(set.screenshot_display_type)
      puts("Deleting #{locale} #{set.screenshot_display_type}")
      set.delete!
    end
  end

  deadline = Time.now + 120
  loop do
    remaining = local.sum do |locale, sets|
      localization_by_locale.fetch(locale).get_app_screenshot_sets.count do |set|
        sets.key?(set.screenshot_display_type)
      end
    end
    break if remaining.zero?
    abort("Timed out waiting for old screenshot sets to delete") if Time.now >= deadline
    sleep(3)
  end

  local.each do |locale, sets|
    localization = localization_by_locale.fetch(locale)
    sets.sort.each do |display_type, paths|
      puts("Uploading #{locale} #{display_type}: #{paths.length} screenshots")
      set = localization.create_app_screenshot_set(
        attributes: { screenshotDisplayType: display_type }
      )
      uploaded_ids = paths.map do |path|
        screenshot = set.upload_screenshot(path: path, wait_for_processing: true)
        puts("  complete: #{File.basename(path)}")
        screenshot.id
      end
      set.reorder_screenshots(app_screenshot_ids: uploaded_ids)
    end
  end
end

errors = []
local.each do |locale, sets|
  localization = localization_by_locale.fetch(locale)
  remote_by_type = localization.get_app_screenshot_sets.to_h do |set|
    [set.screenshot_display_type, set]
  end

  sets.each do |display_type, paths|
    remote_set = remote_by_type[display_type]
    if remote_set.nil?
      errors << "#{locale} #{display_type}: remote set missing"
      next
    end

    remote = remote_set.app_screenshots || []
    local_checksums = paths.map { |path| Digest::MD5.file(path).hexdigest }
    remote_checksums = remote.map(&:source_file_checksum)
    duplicate_groups = remote_checksums.compact.group_by(&:itself).count { |_, values| values.length > 1 }
    missing_checksum_count = remote_checksums.count(&:nil?)

    errors << "#{locale} #{display_type}: expected #{paths.length}, found #{remote.length}" unless remote.length == paths.length
    errors << "#{locale} #{display_type}: #{missing_checksum_count} remote checksums unavailable" unless missing_checksum_count.zero?
    if missing_checksum_count.zero?
      errors << "#{locale} #{display_type}: remote checksums differ" unless remote_checksums.sort == local_checksums.sort
    end
    errors << "#{locale} #{display_type}: #{duplicate_groups} duplicate checksum groups" unless duplicate_groups.zero?
    errors << "#{locale} #{display_type}: incomplete processing" unless remote.all?(&:complete?)

    puts("Verified #{locale} #{display_type}: count=#{remote.length}, duplicate_groups=#{duplicate_groups}")
  end
end

abort(errors.join("\n")) unless errors.empty?
puts("Screenshot verification succeeded for #{local.length} locales")
