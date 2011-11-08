require File.expand_path('../../spec_helper', __FILE__)

# describe Cloudist::Message do
#   before(:each) do
#     stub_amqp!
#     @queue = Cloudist::Queue.new("test.queue")
#     @queue.stubs(:publish)
#     @headers = {}
#   end
#
#   it "should have a unique id when new" do
#     msg = Cloudist::Message.new({:hello => "world"}, @headers)
#     msg.id.size.should == "57b474f0-496c-012e-6f57-34159e11a916".size
#   end
#
#   it "should not update id when existing message" do
#     msg = Cloudist::Message.new({:hello => "world"}, {:id => "not-an-id"})
#     msg.update_headers
#     msg.id.should == "not-an-id"
#   end
#
#   it "should remove id from headers and update with message_id" do
#     msg = Cloudist::Message.new({:hello => "world"}, {:id => "not-an-id"})
#     msg.update_headers
#     msg.id.should == "not-an-id"
#     msg.headers.id.should == nil
#
#     msg = Cloudist::Message.new({:hello => "world"}, {:message_id => "not-an-id"})
#     msg.update_headers
#     msg.id.should == "not-an-id"
#     msg.headers.id.should == nil
#   end
#
#   it "should update headers" do
#     msg = Cloudist::Message.new({:hello => "world"}, {:id => "not-an-id"})
#     msg.update_headers
#
#     msg.headers.keys.should include *["ttl", "timestamp", "message_id"]
#   end
#
#   it "should allow custom header when updating" do
#     msg = Cloudist::Message.new({:hello => "world"}, {:id => "not-an-id"})
#     msg.update_headers(:message_type => "reply")
#
#     msg.headers.keys.should include *["ttl", "timestamp", "message_id", "message_type"]
#   end
#
#   it "should not be published if timestamp is not in headers" do
#     msg = Cloudist::Message.new({:hello => "world"}, {:id => "not-an-id"})
#     msg.published?.should be_false
#   end
#
#   it "should be published if timestamp is in headers" do
#     msg = Cloudist::Message.new({:hello => "world"}, {:id => "not-an-id"})
#     msg.publish(@queue)
#     msg.published?.should be_true
#   end
#
#   it "should include ttl in headers" do
#     msg = Cloudist::Message.new({:hello => "world"})
#     # msg.publish(@queue)
#     msg.headers[:ttl].should == "300"
#   end
#
#   it "should get created_at date from header" do
#     time = Time.now.to_f
#     msg = Cloudist::Message.new({:hello => "world"}, {:timestamp => time})
#     msg.created_at.to_f.should == time
#   end
#
#   it "should set published_at when publishing" do
#     time = Time.now.to_f
#     msg = Cloudist::Message.new({:hello => "world"}, {:timestamp => time})
#     msg.publish(@queue)
#     msg.published_at.to_f.should > time
#   end
#
#   it "should have latency" do
#     time = (Time.now).to_f
#     msg = Cloudist::Message.new({:hello => "world"}, {:timestamp => time})
#     sleep(0.1)
#     msg.publish(@queue)
#     msg.latency.should be_within(0.001).of(0.1)
#   end
#
#   it "should reply to sender" do
#     msg = Cloudist::Message.new({:hello => "world"}, {:id => "not-an-id"})
#     msg.reply(:success => true)
#   end
#
# end
