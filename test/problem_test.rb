require "./test/test_helper"

require "pinker/problem"
include Pinker

regarding "problem message" do

  regarding "problems looks nice with you to_s them" do
      
    test "unintelligent default for now" do
      problem = Problems.new{ problem(condition("@name", Eq("red")), "blue") }.first
      assert{ problem.message == problem.inspect }
    end
    
    test "prefer a custom failure message" do
      problem = Problems.new{ problem(condition("@name", Eq("red")), "blue", "It was not red, that's bad") }.first
      assert{ problem.message == "It was not red, that's bad" }
    end
    
    test "substitute in the actual object" do
      problem = Problems.new{ problem(condition("@name", Eq("red")), "blue", 'It was not red, it was #{actual_object}') }.first
      assert{ problem.message == "It was not red, it was blue" }
    end
    
  end
end