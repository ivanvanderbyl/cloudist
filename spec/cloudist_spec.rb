require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "moqueue"

describe "Cloudist" do
  before(:each) do
    stub_amqp!
  end
  it "should start an AMQP instance" do
    AMQP.should_receive(:start).once
    Cloudist.start do
      
    end
  end
  
  # before(:each) do
  #   overload_amqp
  #   reset_broker
  #   Cloudist.remove_workers
  #   
  #   @mq = mock("MQ")
  #   @queue, @exchange = mock_queue_and_exchange('make.sandwich')
  #   
  #   @qobj = Cloudist::JobQueue.any_instance
  #   @qobj.stubs(:q).returns(@queue)
  #   @qobj.stubs(:mq).returns(@mq)
  #   @qobj.stubs(:ex).returns(@exchange)
  #   @qobj.stubs(:setup)
  # end
  # 
  # it "should register a worker" do
  #   Cloudist.register_worker('make.sandwich', SandwichWorker)
  #   Cloudist.workers.should have_key("make.sandwich")
  #   Cloudist.workers["make.sandwich"].size.should == 1
  # end
  # 
  # it "should support handle syntax" do
  #   Cloudist.workers.should == {}
  #   Cloudist.handle('make.sandwich').with(SandwichWorker)
  #   Cloudist.workers.should have_key("make.sandwich")
  #   Cloudist.workers["make.sandwich"].size.should == 1
  # end
  # 
  # # it "should support handle syntax with multiple queues" do
  # #     Cloudist.workers.should == {}
  # #     Cloudist.handle('make.sandwich', 'eat.sandwich').with(SandwichWorker)
  # #     # Cloudist.workers.should == {"make.sandwich"=>[SandwichWorker], "eat.sandwich"=>[SandwichWorker]}
  # #   end
  # 
  # it "should call process on worker when job arrives" do
  #   job = Cloudist.enqueue('make.sandwich', {:bread => 'white'})
  #   job.payload.published?.should be_true
  #   SandwichWorker.any_instance.expects(:process)
  #   Cloudist.handle('make.sandwich').with(SandwichWorker)
  #   Cloudist.workers.should have_key("make.sandwich")
  #   Cloudist.workers["make.sandwich"].size.should == 1
  # end
  
end
