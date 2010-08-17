require "./test/test_helper"

require "pinker/grammar"
include Pinker

regarding "grammar printing" do
  class Color; end
  class Shirt; end
  
  regarding "a grammar looks nice with you inspect it" do
      
    test "simple" do
      assert{ Grammar.new(:my_grammar){rule(Color){expression("@name", Eq("red"))}}.inspect == 
                %{Grammar(:my_grammar)[Rule(Color)[@name->Eq('red')]]} }
    end
    
    test "several rules" do
      assert{ Grammar.new(:my_grammar){rule(Color){};rule(Shirt){}}.inspect == 
                %{Grammar(:my_grammar)[Rule(Color)[],Rule(Shirt)[]]} }
    end
  end

  regarding "to_s is like inspect except it's multiline, so you see the tree structure" do
    
    test "a couple of rules" do
      assert {
        Grammar.new(:my_grammar) do
          rule(Shirt) do 
            expression("@color", rule(:red_color_rule))
          end
          rule(:red_color_rule) do 
            expression("@name", Eq("red"))
          end
        end.to_s ==
%{Grammar(:my_grammar)[
  Rule(Shirt)[
    @color->rule(:red_color_rule)
  ],
  Rule(:red_color_rule)[
    @name->Eq('red')
  ]
]
}
      }
    end
  end
end