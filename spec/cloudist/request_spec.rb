require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe Cloudist::Request do
  before {
    @mq_header = mock("MQ::Header")
    @mq_header.stubs(:properties).returns({:published_on=>Time.now.to_i - 60, :event_hash=>"foo", :content_type=>"application/json", :message_id=>"foo", :ttl=>300})
    
    q = Cloudist::JobQueue.new('test.queue')
    
    @request = Cloudist::Request.new(q, {:bread => 'white'}.to_json, @mq_header)
  }
  
  it "should return ttl" do
    @request.ttl.should == 300
  end
  
  it "should have a payload" do
    @request.payload.should_not be_nil
    @request.payload.should be_a(Cloudist::Payload)
  end
  
  it "should be 1 minute old" do
    @request.age.should == 60
  end
  
  it "should not be expired" do
    @request.expired?.should_not be_true
  end
  
  it "should not be acked yet" do
    @request.acked?.should be_false
  end
  
  it "should be ackable" do
    @mq_header.stubs(:ack).returns(true)
    
    @request.ack.should be_true
    @request.acked?.should be_true
  end
  
end