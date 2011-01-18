require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe Cloudist::Payload do
  it "should raise bad payload error unless data is a hash" do
    lambda {
      Cloudist::Payload.new([1,2,3])
    }.should raise_error(Cloudist::BadPayload)
  end
  
  it "should accept a hash for data" do
    lambda {
      Cloudist::Payload.new({:bread => 'white'})
    }.should_not raise_error(Cloudist::BadPayload)
  end
  
  it "should prepare headers" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.body.should == {"bread"=>"white"}
    payload.headers.has_key?(:ttl).should be_true
    payload.headers.has_key?(:content_type).should be_true
    payload.headers[:content_type].should == "application/json"
    payload.headers.has_key?(:published_on).should be_true
    payload.headers.has_key?(:event_hash).should be_true
    payload.headers.has_key?(:message_id).should be_true
  end
  
  it "should extract published_on from data" do
    payload = Cloudist::Payload.new({:bread => 'white', :published_on => 12345678})
    payload.body.should == {"bread"=>"white"}
    payload.headers[:published_on].should == "12345678"
  end
  
  it "should extract custom event hash from data" do
    payload = Cloudist::Payload.new({:bread => 'white', :event_hash => 'foo'})
    payload.body.should == {"bread"=>"white"}
    payload.headers[:event_hash].should == "foo"
  end
  
  it "should parse JSON message" do
    payload = Cloudist::Payload.new({:bread => 'white', :event_hash => 'foo'}.to_json)
    payload.body.should == {"bread"=>"white"}
  end
  
  it "should parse custom headers" do
    payload = Cloudist::Payload.new({:bread => 'white', :event_hash => 'foo'}.to_json, {:published_on => 12345})
    payload.parse_custom_headers.should == {:published_on=>12345, :event_hash=>"foo", :content_type=>"application/json", :message_id=>"foo", :ttl=>300}
  end
  
  it "should create a unique event hash" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.create_event_hash.size.should == 32
  end
  
  it "should not create a new event hash unless it doesn't have one" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.event_hash.size.should == 32
    payload = Cloudist::Payload.new({:bread => 'white'}, {:event_hash => 'foo'})
    payload.event_hash.should == 'foo'
  end
  
  it "should delegate missing methods to header keys" do
    payload = Cloudist::Payload.new({:bread => 'white'}, {:event_hash => 'foo', :ttl => 300})
    payload[:bread].should == 'white'
  end
  
  it "should format payload for sending" do
    payload = Cloudist::Payload.new({:bread => 'white'}, {:event_hash => 'foo', :message_type => 'reply'})
    json, popts = payload.formatted
    headers = popts[:headers]
    
    json.should == "{\"bread\":\"white\"}"
    headers[:ttl].should == "300"
    headers[:message_type].should == 'reply'
  end
  
  it "should generate a unique payload ID" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.id.size.should == 32
  end
  
  it "should allow setting of payload ID" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.id = "2345"
    payload.id.should == "2345"
  end
  
  it "should allow changing of payload after being published" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.publish
    lambda { payload.id = "12334456" }.should raise_error
  end
  
  it "should freeze" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    lambda {payload.body[:bread] = "brown"}.should_not raise_error(TypeError)
    payload.body[:bread].should == "brown"
    payload.publish
    lambda {payload.body[:bread] = "rainbow"}.should raise_error(TypeError)
  end
  
  it "should allow setting of reply header" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    
    payload.headers[:reply_to].should be_nil
    payload.set_reply_to("my_custom_queue")
    payload.headers[:reply_to].should_not be_nil
    payload.headers[:reply_to].should match /^temp\.reply\.my_custom_queue\.(.+)/
    body, headers = payload.formatted
    headers[:reply_to].should == payload.headers[:reply_to]
    
  end
  
  it "should not overwrite passed in headers" do
    payload = Cloudist::Payload.new({:bread => 'white'}, {:ttl => 25, :event_hash => 'foo', :published_on => 12345, :message_id => 1})
    payload.headers[:ttl].should == "25"
    payload.headers[:event_hash].should == "foo"
    payload.headers[:published_on].should == "12345"
    payload.headers[:message_id].should == "1"
  end
  
  it "should allow custom headers to be set" do
    payload = Cloudist::Payload.new({:bread => 'white'}, {:reply_type => 'event'})
    payload.headers[:reply_type].should == 'event'
  end
  
end