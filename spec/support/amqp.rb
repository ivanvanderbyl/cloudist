def stub_amqp!
  AMQP.stub(:start)
  mock_queue = mock("AMQP::Queue")
  mock_queue.stub(:bind)
  mock_queue.stub(:name).and_return("test.queue")

  mock_ex = mock("AMQP::Exchange")
  mock_ex.stub(:name).and_return("test.queue")

  mock_channel = mock("AMQP::Channel")
  mock_channel.stub(:prefetch).with(1)
  mock_channel.stub(:queue).and_return(mock_queue)
  mock_channel.stub(:direct).and_return(mock_ex)

  AMQP::Channel.stub(:new).and_return(mock_channel)
end
