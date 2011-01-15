require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Cloudist" do
  before(:all) do
    # overload_amqp
  end
    
  before(:each) do
    reset_broker
  end
  
  def run_start
    Cloudist.start {
      worker {
      
      }
    }
  end
  
  it "should start" do
    Cloudist.stubs(:worker).returns(true)
    Cloudist.expects(:worker).once
    
    run_start
  end
end
