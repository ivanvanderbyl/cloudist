require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')

require "cloudist/core_ext/string"

describe "String" do
  it "should support ends_with?" do
    "started!".ends_with?('!').should be_true
    "started!".ends_with?('-').should be_false
  end

  it "should support starts_with?" do
    "event-started".starts_with?("event").should be_true
    "event-started".starts_with?("reply").should be_false
  end

end
