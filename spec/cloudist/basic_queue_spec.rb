require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe "Cloudist" do
  describe "Cloudist::Queues::BasicQueue" do
    before(:each) do
      overload_amqp
      reset_broker
    end
    
    it "should create a queue and exchange" do
      # MQ.stubs(:direct).with(:name).returns(true)
      @mq = mock("MQ")
      @exchange = mock("MQ Exchange")
      @queue = mock("MQ Queue")
      
      @queue.expects(:bind).with(@exchange)
      # @mq.expects(:queue).with("make.sandwich")
      
      bq = Cloudist::Queues::BasicQueue.new("make.sandwich")
      bq.stubs(:q).returns(@queue)
      bq.stubs(:mq).returns(@mq)
      bq.stubs(:ex).returns(@exchange)
      
      bq.setup
      
      bq.q.should_not be_nil
      bq.ex.should_not be_nil
      bq.mq.should_not be_nil
    end
    
  end
  
end
