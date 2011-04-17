require File.expand_path('../../spec_helper', __FILE__)

describe Cloudist::Messaging do
  
  it "should add queue to queues list" do
    queue = mock("Cloudist::Queue")
    queue.stubs(:name).returns("test.queue")
    Cloudist::Messaging.add_queue(queue)
    Cloudist::Messaging.active_queues.keys.should include('test.queue')
  end
  
  it "should be able to remove queues from list" do
    queue = mock("Cloudist::Queue")
    queue.stubs(:name).returns("test.queue")
    Cloudist::Messaging.add_queue(queue).keys.should == ['test.queue']
    Cloudist::Messaging.remove_queue('test.queue').keys.should == []
  end
  
end
