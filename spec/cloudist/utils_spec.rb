require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

describe Cloudist::Utils do
  it "should return reply queue name" do
    Cloudist::Utils.reply_prefix('eat.sandwich').should == 'temp.reply.eat.sandwich'
  end
  
  it "should return log queue name" do
    Cloudist::Utils.log_prefix('eat.sandwich').should == 'temp.log.eat.sandwich'
  end
  
  it "should return stats queue name" do
    Cloudist::Utils.stats_prefix('eat.sandwich').should == 'temp.stats.eat.sandwich'
  end
  
  # it "should generate queue name" do
  #   Cloudist::Utils.generate_queue('test').should == ''
  # end
end
