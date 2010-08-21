require "./test/test_helper"

require "pinker/rule"
include Pinker

regarding "problem printing" do
  class Color; end
  class Shirt; end
  
  regarding "problems looks nice with you to_s them" do
      
    test "simple" do
      assert{ Problems.new.push(Problem.new(Declaration.new("Must be red."), "blue")).to_s == 
                %{Problems['Must be red.':"blue"]} }

      assert{ Problems.new.push(
                Problem.new(Declaration.new("Must be red."), "blue"),
                Problem.new(Declaration.new("Must be 9 ounces."), 8)
              ).to_s == 
                %{Problems['Must be red.':"blue",'Must be 9 ounces.':8]} }
    end
    
  end

  regarding "inspect is like to_s except it's multiline, so you see the tree structure" do

    test "simple" do
      assert{ Problems.new.push(Problem.new(Declaration.new("Must be red."), "blue")).inspect == 
%{Problems[
  'Must be red.'
    ==> "blue"
]} }
    end
    
    test "two problems" do
      assert{ Problems.new.push(
                Problem.new(Declaration.new("Must be red."), "blue"),
                Problem.new(Declaration.new("Must be 9 ounces."), 8)
              ).inspect == 
%{Problems[
  'Must be red.'
    ==> "blue",
  'Must be 9 ounces.'
    ==> 8
]} }
    end
  
  end
end