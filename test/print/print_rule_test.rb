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

regarding "rule declaration printing" do
  test "basic" do
    assert{ RuleDeclaration.new(:a, {}).to_s == "with_rule:a" }
  end
end

regarding "remembering" do
  test "basic" do
    assert{ Remembering.new{}.to_s == "remember" }
  end
end

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

regarding "rule printing" do
  class Color; end
  class Shirt; end
  
  regarding "a rule looks nice with you to_s it" do
      
    test "simple" do
      assert{ RuleBuilder.new(Color) { declare("Must be red."){@name == "red"} }.build.to_s == 
                %{Rule(Color)[declare:'Must be red.']} }

      assert{ RuleBuilder.new(:red_color_rule) {}.build.to_s == 
                %{Rule(:red_color_rule)[]} }
    end
    
    test "several declarations" do
      assert {
        RuleBuilder.new(Shirt) {
          declare{@color=="red"}
          declare("Size must be large"){size=="large"}
        }.build.to_s ==
        %{Rule(Shirt)[declare:<no message>,declare:'Size must be large']}
      }
    end
    
  end

  regarding "inspect is like to_s except it's multiline, so you see the tree structure" do
    
    test "one declaration" do
      assert {
        RuleBuilder.new(Shirt) {
          declare("Must be red."){@color == "red"}
        }.build.inspect ==
%{Rule(Shirt)[
  declare:'Must be red.'
]
}
      }
    end
  
    test "more than one declaration" do
      assert {
        RuleBuilder.new(Shirt) { 
          declare("Must be button-down."){@style == "button-down"}
          declare("Must be red."){@color == "red"}
        }.build.inspect ==
%{Rule(Shirt)[
  declare:'Must be button-down.',
  declare:'Must be red.'
]
}
      }
    end
    
  end
end