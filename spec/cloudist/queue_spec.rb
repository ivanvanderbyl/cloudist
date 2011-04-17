require File.expand_path('../../spec_helper', __FILE__)

describe Cloudist::Queue do
  before(:each) do
    stub_amqp!
  end
  
  it "should cache new queues" do
    q1 = Cloudist::Queue.new("test.queue")
    q2 = Cloudist::Queue.new("test.queue")
    
    # q1.cached_queues.should == {}
    q1.q.should == q2.q
    Cloudist::Queue.cached_queues.should == {}
  end
end
