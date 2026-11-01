require 'minitest/autorun'
require 'tmpdir'
require_relative 'store_screenshot_sync'

class PlayCommitTest < Minitest::Test
  class FakePlay
    attr_accessor :fail_commit
    attr_reader :commits,:uploads
    def initialize
      @committed=[];@editing=[];@commits=0;@uploads=0;@edit_id=0
      begin_edit
    end
    def client;self;end
    def current_edit;@active ? Struct.new(:id).new(@edit_id.to_s) : nil;end
    def begin_edit;@edit_id+=1;@active=true;@editing=@committed.dup;end
    def checksum_algorithm;'sha256';end
    def snapshot(_);{exists:true,images:@editing.map { |x| {checksum:x,complete:true} }};end
    def clear(*);@editing=[];end
    def prepare(*);end
    def upload(_,path);@uploads+=1;@editing << Digest::SHA256.file(path).hexdigest;end
    def commit
      @commits+=1;@committed=@editing.dup;@active=false
      raise IOError if @fail_commit
    end
    def abort_edit;@active=false;end
  end
  def setup
    @env=ENV.to_h;@dir=Dir.mktmpdir;@fake=FakePlay.new
    image=File.join(@dir,'image.png');File.write(image,'local image')
    @manifest={'schema_version'=>1,'platform'=>'android','root'=>@dir,'sets'=>[
      {'locale'=>'en-US','display_type'=>'phoneScreenshots','images'=>[{'path'=>'image.png','sha256'=>Digest::SHA256.file(image).hexdigest}]}]}
    @file=File.join(@dir,'manifest.json');File.write(@file,JSON.generate(@manifest))
    @state=File.join(@dir,'journal.json')
    ENV['ANDROID_PACKAGE_NAME']='com.example.fixture'
    ENV['BOOGIOS_GOOGLE_PLAY_SERVICE_ACCOUNT_JSON']=image # only readability is used by the fake
    fake=@fake
    @original=StoreScreenshots::Android.method(:new)
    StoreScreenshots::Android.define_singleton_method(:new) { |*_|fake.begin_edit unless fake.current_edit;fake }
  end
  def teardown
    original=@original;StoreScreenshots::Android.define_singleton_method(:new) { |*args| original.call(*args) }
    ENV.replace(@env);FileUtils.remove_entry(@dir)
  end
  def run_cli
    StoreScreenshots.cli(['--manifest',@file,'--state',@state,'--upload'])
  end
  def test_committed_images_are_audited_and_identical_rerun_does_not_commit
    assert_equal 0,run_cli
    assert_equal 0,run_cli
    assert_equal 1,@fake.commits
    assert_equal 1,@fake.uploads
  end
  def test_uncertain_commit_is_read_back_without_repeating_it
    @fake.fail_commit=true
    assert_equal 1,run_cli
    assert_equal 'pending_commit',JSON.parse(File.read(@state))['phase']
    assert_equal 0,run_cli
    assert_equal 1,@fake.commits
    assert_equal 1,@fake.uploads
    assert_equal 'verified',JSON.parse(File.read(@state))['phase']
  end
  def test_concurrent_operation_is_blocked_before_upload
    File.open(@state+'.lock','w') do |lock|
      lock.flock(File::LOCK_EX)
      assert_equal 1,run_cli
      assert_equal 0,@fake.uploads
      assert_equal 0,@fake.commits
    end
  end
end
