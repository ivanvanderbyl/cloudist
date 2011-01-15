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
    hash, headers = payload.apply_custom_headers
    hash.should == {"bread"=>"white"}
    headers.has_key?(:ttl).should be_true
    headers.has_key?(:content_type).should be_true
    headers[:content_type].should == "application/json"
    headers.has_key?(:published_on).should be_true
    headers.has_key?(:event_hash).should be_true
    headers.has_key?(:message_id).should be_true
  end
  
  it "should extract published_on from data" do
    payload = Cloudist::Payload.new({:bread => 'white', :published_on => 12345678})
    hash, headers = payload.apply_custom_headers
    hash.should == {"bread"=>"white"}
    headers[:published_on].should == "12345678"
  end
  
  it "should extract custom event hash from data" do
    payload = Cloudist::Payload.new({:bread => 'white', :event_hash => 'foo'})
    hash, headers = payload.apply_custom_headers
    hash.should == {"bread"=>"white"}
    headers[:event_hash].should == "foo"
  end
  
  it "should parse JSON message" do
    payload = Cloudist::Payload.new({:bread => 'white', :event_hash => 'foo'}.to_json)
    payload.hash.should == {"bread" => 'white', 'event_hash' => 'foo'}
  end
  
  it "should parse custom headers" do
    payload = Cloudist::Payload.new({:bread => 'white', :event_hash => 'foo'}.to_json, {:published_on => 12345})
    payload.parse_custom_headers.should == {:published_on=>12345, :ttl=>-1}
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
    payload = Cloudist::Payload.new({:bread => 'white'}, {:event_hash => 'foo'})
    json, headers = payload.formatted
    json.should == "{\"bread\":\"white\"}"
    headers[:ttl].should == "300"
  end
  
end