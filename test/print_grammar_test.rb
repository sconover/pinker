require "./test/test_helper"

require "pinker/grammar"
include Pinker


#"with rule" should print differently...

regarding "rule declaration" do
  test "prints the rule" do
    assert{ RuleDeclaration.new(:some_rule).to_s == "declare:Rule(:some_rule)" }
  end
end

regarding "grammar printing" do
  class Color; end
  class Shirt; end
  
  regarding "a grammar looks nice when you to_s it" do
      
    test "simple" do
      assert{ Grammar.new(:my_grammar){rule(Color){declare("Must be red."){@name=="red"}}}.to_s == 
                %{Grammar(:my_grammar)[Rule(Color)[declare:'Must be red.']]} }
    end
    
    test "several rules" do
      assert{ Grammar.new(:my_grammar){rule(Color){};rule(Shirt){}}.to_s == 
                %{Grammar(:my_grammar)[Rule(Color)[],Rule(Shirt)[]]} }
    end
  end

  regarding "inspect is like to_s except it's multiline, so you see the tree structure" do
    
    test "a couple of rules" do
      assert {
        Grammar.new(:my_grammar) do
          rule(Shirt) do 
            with_rule(:red_color_rule){|rule|rule.apply_to(@color)}
          end
          rule(:red_color_rule) do 
            declare{@name == "red"}
          end
        end.inspect ==
%{Grammar(:my_grammar)[
  Rule(Shirt)[
    declare:Rule(:red_color_rule)
  ],
  Rule(:red_color_rule)[
    declare:<no message>
  ]
]
}
      }
    end
  end
end

regarding "grammar result printing" do
  regarding "to_s" do
    it "passes" do
      assert{ ResultOfGrammarApplication.new(Problems.new).to_s == "Result:Well-Formed"}
    end

    it "fails" do
      assert{ ResultOfGrammarApplication.new(Problems.new.push(
                  Problem.new(Declaration.new("Must be red."), "blue"),
                  Problem.new(Declaration.new("Must be 9 ounces."), 8)
                ){ 
              }).to_s == 
              %{Result:Not-Well-Formed:Problems['Must be red.':"blue",'Must be 9 ounces.':8]}
      }
    end
  end
  
  regarding "inspect" do
    it "passes" do
      assert{ ResultOfGrammarApplication.new(Problems.new).inspect == "Result:Well-Formed"}
    end    
    
    test "fails" do
      assert{ ResultOfGrammarApplication.new(Problems.new.push(
                Problem.new(Declaration.new("Must be red."), "blue"),
                Problem.new(Declaration.new("Must be 9 ounces."), 8)
              )).inspect == 
%{Result:Not-Well-Formed:
  Problems[
    'Must be red.'
      ==> "blue",
    'Must be 9 ounces.'
      ==> 8
  ]} }
    end

  end
end