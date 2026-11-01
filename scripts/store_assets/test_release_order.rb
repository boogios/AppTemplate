# Evaluate the real lane definitions with local spies; never loads store auth.
require 'minitest/autorun'

class LaneHarness
  module SharedValues
    DEFAULT_PLATFORM=:default_platform
    IPA_OUTPUT_PATH=:ipa
  end
  module UI
    def self.user_error!(message);raise message;end
  end
  attr_reader :events, :lanes
  attr_accessor :asset_failure
  def initialize(path, requested_platform)
    @events=[];@lanes={};@context={ipa:'/tmp/fixture.ipa'};@platform=requested_platform
    instance_eval(File.read(path),path)
    define_singleton_method(:ensure_common_inputs!) {}
    define_singleton_method(:load_asc_api_key) { {} }
    define_singleton_method(:read_project_spec_value) { |_| '1.2.3' }
    define_singleton_method(:default_build_number) { '123' }
    define_singleton_method(:metadata_value) { |_,fallback| fallback }
    define_singleton_method(:prepare_store_screenshots!) { |_| @events << :local_assets;raise 'invalid assets' if @asset_failure }
    define_singleton_method(:sync_store_screenshots!) do |_,upload:,**_|
      @events << (upload ? :asset_upload_and_audit : :asset_audit)
      raise 'remote assets differ' if @asset_failure
    end
    define_singleton_method(:build_release) { |**_| @events << :binary_build }
    define_singleton_method(:prepare_app_review_metadata) { |**_| @events << :metadata }
    define_singleton_method(:deliver) { |**kwargs| @events << [:deliver,kwargs] }
    define_singleton_method(:upload_to_play_store) { |**kwargs| @events << [:supply,kwargs] }
    define_singleton_method(:play_service_key) { __FILE__ }
  end
  def lane_context;@context;end
  def fastlane_version(_);end
  def default_platform(value);@context[:default_platform]=value;end
  def import(_);end
  def platform(value);yield if value==@platform;end
  def desc(_);end
  def lane(name,&block);@lanes[name]=block;end
  def run(name);instance_exec({},&@lanes.fetch(name));end
end

class ReleaseOrderTest < Minitest::Test
  ROOT=File.expand_path('../..',__dir__)
  def setup
    @original=ENV.to_h
    %w[RELEASE_SKIP_SCREENSHOTS RELEASE_SKIP_BINARY_UPLOAD RELEASE_SUBMIT_FOR_REVIEW ANDROID_SKIP_SCREENSHOTS].each { |key| ENV.delete(key) }
    ENV['ANDROID_PACKAGE_NAME']='com.example.fixture'
    ENV['ANDROID_UPLOAD_SCREENSHOTS']='true'
  end
  def teardown;ENV.replace(@original);end
  def harness(platform)
    folder=platform==:ios ? 'ios' : 'android'
    LaneHarness.new(File.join(ROOT,folder,'fastlane/Fastfile'),platform)
  end
  def test_ios_assets_finish_before_deliver_and_deliver_never_reuploads
    h=harness(:ios);h.run(:release)
    call=h.events.find { |x| x.is_a?(Array) }
    assert_operator h.events.index(:asset_upload_and_audit),:<,h.events.index(call)
    assert_equal true,call[1][:skip_screenshots]
    assert_equal true,call[1][:submit_for_review]
  end
  def test_ios_invalid_local_assets_prevent_archive_and_deliver
    h=harness(:ios);h.asset_failure=true
    assert_raises(RuntimeError) {h.run(:release)}
    refute_includes h.events,:binary_build
    refute h.events.any? { |x| x.is_a?(Array) }
  end
  def test_skip_still_audits_before_review
    ENV['RELEASE_SKIP_SCREENSHOTS']='true'
    h=harness(:ios);h.run(:release)
    assert_includes h.events,:asset_audit
    refute_includes h.events,:asset_upload_and_audit
  end
  def test_remote_failure_prevents_deliver
    h=harness(:ios)
    def h.sync_store_screenshots!(*,**);raise 'processing unresolved';end
    assert_raises(RuntimeError) {h.run(:release)}
    refute h.events.any? { |x| x.is_a?(Array) }
  end
  def test_android_assets_finish_before_build_and_supply
    h=harness(:android);h.run(:upload)
    assert_operator h.events.index(:asset_upload_and_audit),:<,h.events.index(:binary_build)
    call=h.events.last[1]
    assert_equal true,call[:skip_upload_screenshots]
    assert_equal true,call[:skip_upload_images]
    assert_equal 'draft',call[:release_status]
    assert_equal 'internal',call[:track]
  end
  def test_android_asset_failure_prevents_binary
    h=harness(:android);h.asset_failure=true
    assert_raises(RuntimeError) {h.run(:upload)}
    refute_includes h.events,:binary_build
    refute h.events.any? { |x| x.is_a?(Array) }
  end
  def test_android_binary_only_keeps_previous_flow
    ENV.delete('ANDROID_UPLOAD_SCREENSHOTS')
    h=harness(:android);h.run(:upload)
    refute_includes h.events,:asset_upload_and_audit
    assert_includes h.events,:binary_build
  end
end
