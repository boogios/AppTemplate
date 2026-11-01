require 'minitest/autorun'
require 'tmpdir'
require_relative 'store_screenshot_sync'

class SyncTest < Minitest::Test
  class Fake
    attr_accessor :images, :fail_after_upload, :ambiguous_upload, :delay
    attr_reader :uploads, :clears
    def initialize
      @images, @uploads, @clears, @exists, @delay = [], 0, 0, false, 0
    end
    def checksum_algorithm; 'md5'; end
    def snapshot(_entry)
      @delay -= 1 if @delay > 0
      {exists: @exists, images: @images.map { |sum| {checksum: sum, complete: @delay <= 0} }}
    end
    def clear(_entry, _snapshot); @clears += 1; @images=[]; @exists=false; end
    def prepare(_entry); @exists=true; end
    def upload(_entry,path)
      @uploads += 1
      raise IOError if @ambiguous_upload
      @images << Digest::MD5.file(path).hexdigest
      if @fail_after_upload
        @fail_after_upload=false
        raise IOError
      end
    end
  end
  def setup
    @dir=Dir.mktmpdir
    @paths=2.times.map { |i| p=File.join(@dir,"#{i}.png");File.write(p,"image#{i}");p }
    @manifest={'root'=>@dir,'sets'=>[{'locale'=>'en-US','display_type'=>'APP_IPHONE_DUO','images'=>@paths.map { |p| {'path'=>File.basename(p),'md5'=>Digest::MD5.file(p).hexdigest} }}]}
    @state=File.join(@dir,'state.json');@fake=Fake.new
  end
  def teardown;FileUtils.remove_entry(@dir);end
  def run_sync(upload=true)
    StoreScreenshots::Sync.new(adapter:@fake,manifest:@manifest,state_path:@state,polls:3,interval:0).run(upload:upload)
  end
  def test_upload_and_identical_rerun_do_not_duplicate
    run_sync;run_sync
    assert_equal 2,@fake.uploads
    assert_equal 1,@fake.clears
  end
  def test_audit_checks_order_and_never_mutates
    @fake.images=@paths.reverse.map { |p| Digest::MD5.file(p).hexdigest }
    assert_raises(StoreScreenshots::Error) { run_sync(false) }
    assert_equal 0,@fake.clears
    assert_equal 0,@fake.uploads
  end
  def test_interrupted_successful_post_is_reconciled_and_resumed
    @fake.fail_after_upload=true
    assert_raises(IOError) { run_sync }
    run_sync
    assert_equal 2,@fake.uploads
    assert_equal 1,@fake.clears
  end
  def test_ambiguous_post_is_never_blindly_retried
    @fake.ambiguous_upload=true
    assert_raises(IOError) { run_sync }
    @fake.ambiguous_upload=false
    assert_raises(StoreScreenshots::Error) { run_sync }
    assert_equal 1,@fake.uploads
  end
  def test_processing_waits_before_deciding_to_replace
    @fake.images=@paths.map { |p| Digest::MD5.file(p).hexdigest };@fake.delay=2
    run_sync
    assert_equal 0,@fake.clears
    assert_equal 0,@fake.uploads
  end
  def test_duplicates_or_unavailable_checksums_block_replacement
    [ [nil], ['same','same'] ].each do |images|
      @fake.images=images
      assert_raises(StoreScreenshots::Error) { run_sync }
    end
    assert_equal 0,@fake.clears
  end
  def test_changed_local_file_fails_before_network
    File.write(@paths[0],'changed')
    assert_raises(StoreScreenshots::Error) { run_sync }
    assert_equal 0,@fake.uploads
  end
  def test_changed_inputs_after_uncertain_post_require_reconciliation
    @fake.ambiguous_upload=true
    assert_raises(IOError) { run_sync }
    @manifest['sets'][0]['images'].reverse!
    assert_raises(StoreScreenshots::Error) { run_sync }
    assert_equal 1,@fake.uploads
  end
end
