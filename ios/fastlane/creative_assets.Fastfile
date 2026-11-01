# Copy this file and app_store_creative_assets.rb into the app's fastlane/ folder.
# Import with: import "./creative_assets.Fastfile"
require File.expand_path("app_store_creative_assets.rb", __dir__)

def run_creative_assets!(mode, options)
  fastlane_dir = File.expand_path(__dir__)
  manifest_path = options[:manifest] || ENV["CREATIVE_ASSETS_MANIFEST"] || File.join(fastlane_dir, "creative_assets", "manifest.json")
  manifest_path = File.expand_path(manifest_path, File.expand_path("..", fastlane_dir))
  expected_bundle = ENV["APP_IDENTIFIER"] || ENV["BUNDLE_IDENTIFIER"]
  expected_bundle ||= DEFAULT_APP_IDENTIFIER if defined?(DEFAULT_APP_IDENTIFIER)
  expected_bundle ||= DEFAULT_BUNDLE_ID if defined?(DEFAULT_BUNDLE_ID)
  manifest = AppStoreCreativeAssets::Manifest.new(manifest_path, expected_bundle_id: expected_bundle)
  state_path = options[:state] || ENV["CREATIVE_ASSETS_STATE"] || File.join(fastlane_dir, ".creative-assets-state", "#{manifest.app_id}.json")
  runner = AppStoreCreativeAssets::Runner.new(manifest: manifest,
    client: mode == "validate" ? nil : AppStoreCreativeAssets::Client.new,
    state_path: File.expand_path(state_path, File.expand_path("..", fastlane_dir)),
    poll_timeout: options[:timeout] || 300)
  result = runner.run(mode: mode, version: options[:version])
  UI.message(JSON.pretty_generate(result))
  result
rescue AppStoreCreativeAssets::Error => error
  UI.user_error!(error.message)
end

platform :ios do
  desc "Validate local header/search creative images without contacting App Store Connect"
  lane :validate_creative_assets do |options|
    run_creative_assets!("validate", options)
  end

  desc "Read App Asset Library specs and creative image states; version is optional (GET only)"
  lane :audit_creative_assets do |options|
    run_creative_assets!("audit", options)
  end

  desc "Upload/resume unique creative images only; does not submit or publish"
  lane :upload_creative_assets do |options|
    run_creative_assets!("upload", options)
  end

  desc "Connect uploaded header/search images to an explicit editable version; does not replace, submit or publish"
  lane :place_creative_assets do |options|
    run_creative_assets!("place", options)
  end
end
