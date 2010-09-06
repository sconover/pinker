require "./test/test_helper"

require "pinker/rule2"
include Pinker

regarding "problem message" do

  regarding "problems looks nice with you to_s them" do
      
    test "eval in actual_object" do
      problem = Problem.new(Declaration.new('Must be red, but was #{actual_object}.'), "blue")
      assert{ problem.message == 'Must be red, but was blue.' }
    end
      
    test "eval in context" do
      problem = Problem.new(Declaration.new('Must be red.  The time is #{time}.'), "blue", :time => "1:00")
      assert{ problem.message == 'Must be red.  The time is 1:00.' }
    end
      
  end
end