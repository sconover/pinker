require "./test/test_helper"

require "pinker/rule"
include Pinker

regarding "problem printing" do
  class Color; end
  class Shirt; end
  
  regarding "problems looks nice with you to_s them" do
      
    test "simple" do
      assert{ Problem.new(Declaration.new("Must be red."), "blue").to_s == 
                %{'Must be red.':"blue"} }
    end
    
  end
end