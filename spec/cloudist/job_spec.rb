require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe Cloudist::Job do
  before(:each) do
    @payload = Cloudist::Payload.new({:bread => 'white'})
  end
  
  it "should be constructable with payload" do
    job = Cloudist::Job.new(@payload)
    job.payload.should == @payload
  end
  
  it "should be constructable with payload and return ID" do
    job = Cloudist::Job.new(@payload)
    job.id.should == @payload.id
  end
  
  it "should be constructable with payload and return data" do
    job = Cloudist::Job.new(@payload)
    job.data.should == @payload.hash
  end
  
end
