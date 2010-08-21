require "./test/test_helper"

require "pinker/rule"
include Pinker


regarding "declaration printing" do
  test "prints 'no message' if no message was provided." do
    assert{ Declaration.new.to_s == "declare:<no message>" }
  end

  test "prints the failure message if a message was provided." do
    assert{ Declaration.new("Must be red.").to_s == "declare:'Must be red.'" }
  end

end

regarding "rule printing" do
  class Color; end
  class Shirt; end
  
  regarding "a rule looks nice with you to_s it" do
      
    test "simple" do
      assert{ Rule.new(Color) { declare("Must be red."){@name == "red"} }.to_s == 
                %{Rule(Color)[declare:'Must be red.']} }

      assert{ Rule.new(:red_color_rule) {}.to_s == 
                %{Rule(:red_color_rule)[]} }
    end
    
    test "several declarations" do
      assert {
        Rule.new(Shirt) do 
          declare{@color=="red"}
          declare("Size must be large"){size=="large"}
        end.to_s ==
        %{Rule(Shirt)[declare:<no message>,declare:'Size must be large']}
      }
    end
    
  end

  regarding "inspect is like to_s except it's multiline, so you see the tree structure" do
    
    test "one declaration" do
      red_color_rule = Rule.new(:red_color_rule) { condition("@name", Eq("red")) }
      assert {
        Rule.new(Shirt) do 
          declare("Must be red."){@color == "red"}
        end.inspect ==
%{Rule(Shirt)[
  declare:'Must be red.'
]
}
      }
    end
  
    test "more than one declaration" do
      assert {
        Rule.new(Shirt) do 
          declare("Must be button-down."){@style == "button-down"}
          declare("Must be red."){@color == "red"}
        end.inspect ==
%{Rule(Shirt)[
  declare:'Must be button-down.',
  declare:'Must be red.'
]
}
      }
    end
    
  end
end