# Copied into each generated app; no dependency on a personal skill directory.
require "json"
require "rbconfig"
require "shellwords"

def store_asset_root
  File.expand_path("..", __dir__)
end

def store_asset_paths
  root = store_asset_root
  {root: root, lib: File.join(root, "fastlane", "lib"),
   manifest: File.join(root, "fastlane", ".store-assets", "screenshots.json")}
end

def prepare_store_screenshots!(platform)
  paths = store_asset_paths
  config_path = File.join(paths[:root], platform == "ios" ? "AppStoreScreenshots/screenshot.config.json" : "play/screenshot-config.json")
  config = JSON.parse(File.read(config_path))
  locales = platform == "ios" ? metadata_locales : ENV.fetch("PLAY_SCREENSHOT_LOCALES", config.fetch("locales").join(",")).split(",")
  if platform == "ios"
    mapping = {"iphone63" => "APP_IPHONE_61", "iphone69" => "APP_IPHONE_67", "duoOuter" => "APP_IPHONE_DUO", "duoInner" => "APP_IPHONE_DUO", "ipad13" => "APP_IPAD_PRO_3GEN_129"}
    devices = config.fetch("exportDevices").map { |key| mapping.fetch(key) }.uniq
    source = File.join(paths[:root], "outputs", "appstore-exports")
    dest = File.join(paths[:root], "fastlane", "screenshots")
    incomplete = locales.reject { |locale| config.fetch("localizationStatus").fetch(locale, "draft") == "ready" }
    UI.user_error!("Incomplete screenshot translations: #{incomplete.join(', ')}") unless incomplete.empty?
  else
    devices = config.fetch("devices")
    source = File.join(paths[:root], "play", "screenshots")
    dest = File.join(paths[:root], "fastlane", "metadata", "android")
  end
  command = ["python3", File.join(paths[:lib], "store_screenshots.py"), "--platform", platform,
     "--root", source, "--locales", locales.join(","), "--devices", devices.join(","),
     "--stage", dest, "--manifest", paths[:manifest]]
  command << "--require-provenance" if platform == "ios"
  sh(*command)
  paths[:manifest]
end

def sync_store_screenshots!(platform, upload:, version: nil)
  manifest = prepare_store_screenshots!(platform)
  # Scoped environment prevents metadata for another app/version leaking in.
  environment = platform == "ios" ? {"APP_IDENTIFIER" => DEFAULT_BUNDLE_ID, "APP_VERSION" => version.to_s} : {"ANDROID_PACKAGE_NAME" => PACKAGE_NAME}
  command = [RbConfig.ruby, File.join(store_asset_paths[:lib], "store_screenshot_sync.rb"), "--manifest", manifest]
  command << "--upload" if upload
  FastlaneCore::Helper.with_env_values(environment) { sh(*command) }
end

platform :ios do
  lane :validate_store_screenshots do
    prepare_store_screenshots!("ios")
  end
  lane :upload_store_screenshots do |options|
    sync_store_screenshots!("ios", upload: true, version: options[:version] || read_project_spec_value("MARKETING_VERSION"))
  end
  lane :audit_store_screenshots do |options|
    sync_store_screenshots!("ios", upload: false, version: options[:version] || read_project_spec_value("MARKETING_VERSION"))
  end
end if lane_context[SharedValues::DEFAULT_PLATFORM] == :ios

platform :android do
  lane :validate_store_screenshots do
    prepare_store_screenshots!("android")
  end
  lane :upload_store_screenshots do
    sync_store_screenshots!("android", upload: true)
  end
  lane :audit_store_screenshots do
    sync_store_screenshots!("android", upload: false)
  end
end if lane_context[SharedValues::DEFAULT_PLATFORM] == :android
