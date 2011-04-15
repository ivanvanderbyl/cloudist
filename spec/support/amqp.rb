def stub_amqp!
  AMQP.stubs(:start)
  mock_queue = mock("AMQP::Queue")
  mock_queue.stubs(:bind)
  mock_queue.stubs(:name).returns("test.queue")
  
  mock_ex = mock("AMQP::Exchange")
  mock_ex.stubs(:name).returns("test.queue")
  
  mock_channel = mock("AMQP::Channel")
  mock_channel.stubs(:prefetch).with(1)
  mock_channel.stubs(:queue).returns(mock_queue)
  mock_channel.stubs(:direct).returns(mock_ex)
  
  AMQP::Channel.stubs(:new).returns(mock_channel)
end
