require "./test/test_helper"

require "pinker/rule"
include Pinker

regarding "problem message" do

  regarding "problems looks nice with you to_s them" do
      
    test "unintelligent default for now" do
      problem = Problem.new(Declaration.new("Must be red."), "blue")
      assert{ problem.message == problem.inspect }
    end
      
  end
end