require "./test/test_helper"

require "pinker/rule"
include Pinker

regarding "problem printing" do
  class Color; end
  class Shirt; end
  
  regarding "problems looks nice with you to_s them" do
      
    test "simple" do
      assert{ Problems.new{ problem(condition("@name", Eq("red")), "blue") }.to_s == 
                %{Problems[@name->Eq('red'):"blue"]} }

      assert{ Problems.new{ 
                problem(condition("@name", Eq("red")), "blue") 
                problem(condition("@weight", Eq(9)), 8) 
              }.to_s == 
                %{Problems[@name->Eq('red'):"blue",@weight->Eq(9):8]} }
    end
    
  end

  regarding "inspect is like to_s except it's multiline, so you see the tree structure" do

    test "simple" do
      assert{ Problems.new{ problem(condition("@name", Eq("red")), "blue") }.inspect == 
%{Problems[
  @name->Eq('red')
    ==> "blue"
]} }
    end
    
    test "two problems" do
      assert{ Problems.new{ 
                problem(condition("@name", Eq("red")), "blue") 
                problem(condition("@weight", Eq(9)), 8) 
              }.inspect == 
%{Problems[
  @name->Eq('red')
    ==> "blue",
  @weight->Eq(9)
    ==> 8
]} }
    end
  
  end
end