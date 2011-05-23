require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe Cloudist::Payload do
  include Cloudist::Encoding
  
  it "should accept a hash for data" do
    pl = Cloudist::Payload.new({:bread => 'white'})
    pl.body.bread.should == "white"
  end
  
  it "should accept encoded message" do
    pl = Cloudist::Payload.new(encode({:bread => 'white'}))
    pl.body.bread.should == "white"
  end
  
  it "should retrieve id from headers" do
    pl = Cloudist::Payload.new({:bread => 'white'}, {:message_id => "12345"})
    pl.id.should == "12345"
  end
  
  it "should prepare headers" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.body.bread.should == "white"
    payload.headers.has_key?("ttl").should be_true
    # payload.headers.has_key?(:content_type).should be_true
    # payload.headers[:content_type].should == "application/json"
    payload.headers.has_key?("published_on").should be_true
    payload.headers.has_key?("message_id").should be_true
  end
  
  it "should extract published_on from data" do
    time = Time.now.to_f
    payload = Cloudist::Payload.new({:bread => 'white', :timestamp => time})
    payload.headers[:published_on].should == time
  end
  
  it "should not override timestamp if already present in headers" do
    time = (Time.now.to_f - 10.0)
    payload = Cloudist::Payload.new({:bread => 'white'}, {:published_on => time})
    payload.headers[:published_on].should == time
  end
  
  it "should override timestamp if not present" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.headers[:published_on].should be_within(0.1).of Time.now.to_f
    payload.timestamp.should be_within(0.1).of Time.now.to_f
  end
  
  it "should parse custom headers" do
    payload = Cloudist::Payload.new(Marshal.dump({:bread => 'white'}), {:published_on => 12345, :message_id => "foo"})
    payload.headers.to_hash.should == { "published_on"=>12345, "message_id"=>"foo", "ttl"=>300 }
  end
  
  it "should create a unique event hash" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.id.size.should == 36
  end
  
  it "should not create a new message_id unless it doesn't have one" do
    payload = Cloudist::Payload.new({:bread => 'white'})
    payload.id.size.should == 36
    payload = Cloudist::Payload.new({:bread => 'white'}, {:message_id => 'foo'})
    payload.id.should == 'foo'
  end
  
  it "should format payload for sending" do
    payload = Cloudist::Payload.new({:bread => 'white'}, {:message_id => 'foo', :message_type => 'reply'})
    body, popts = payload.to_a
    headers = popts[:headers]
    
    body.should == encode(Hashie::Mash.new({:bread => 'white'}))
    headers[:ttl].should == "300"
    headers[:message_type].should == 'reply'
  end
  
  
  
end