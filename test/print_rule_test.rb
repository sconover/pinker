require "./test/test_helper"

require "pinker/rule"
include Pinker

regarding "rule printing" do
  class Color; end
  class Shirt; end
  
  regarding "a rule looks nice with you inspect it" do
      
    test "simple" do
      assert{ Rule.new(Color) { expression("@name", Eq("red")) }.inspect == 
                %{Rule(Color)[@name->Eq('red')]} }

      assert{ Rule.new(:red_color_rule) { expression("@name", Eq("red")) }.inspect == 
                %{Rule(:red_color_rule)[@name->Eq('red')]} }

      assert{ Rule.new(Color) { expression(:name, Eq("red")) }.inspect == 
                %{Rule(Color)[:name->Eq('red')]} }
    end
    
    test "several conditions" do
      assert {
        Rule.new(Shirt) do 
          expression("@color", Eq("red"))
          expression(:size, Eq("large"))
        end.inspect ==
        %{Rule(Shirt)[@color->Eq('red'),:size->Eq('large')]}
      }
    end
    
    test "points to another rule" do
      red_color_rule = Rule.new(:red_color_rule) { expression("@name", Eq("red")) }
      assert {
        Rule.new(Shirt) {expression("@color", red_color_rule)}.inspect ==
          %{Rule(Shirt)[@color->Rule(:red_color_rule)[@name->Eq('red')]]}
      }
    end
    
    test "references another rule" do
      assert {
        Rule.new(Shirt) {expression("@color", rule(Color))}.inspect ==
          %{Rule(Shirt)[@color->rule(Color)]}
      }
    end
    
  end

  regarding "to_s is like inspect except it's multiline, so you see the tree structure" do
    
    test "one expression" do
      red_color_rule = Rule.new(:red_color_rule) { expression("@name", Eq("red")) }
      assert {
        Rule.new(Shirt) do 
          expression("@color", red_color_rule)
        end.to_s ==
%{Rule(Shirt)[
  @color->Rule(:red_color_rule)[
    @name->Eq('red')
  ]
]
}
      }
    end
  
    test "more than one expression" do
      red_color_rule = Rule.new(:red_color_rule) { expression("@name", Eq("red")) }
      assert {
        Rule.new(Shirt) do 
          expression("@color", red_color_rule)
          expression("@color2", rule(Color))
          expression(:size, Eq("large"))
        end.to_s ==
%{Rule(Shirt)[
  @color->Rule(:red_color_rule)[
    @name->Eq('red')
  ],
  @color2->rule(Color),
  :size->Eq('large')
]
}
      }
    end
    
    test "nesting" do
    end
  end
end