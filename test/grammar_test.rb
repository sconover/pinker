require "./test/test_helper"

require "pinker/grammar"
include Pinker

regarding "a grammar is a set of rules" do

  class Color
    include ValueEquality
    def initialize(name)
      @name = name
    end
  end
  
  class Shirt
    include ValueEquality
    def initialize(size, color)
      @size = size
      @color = color
    end
  end

  before do
    @shirt_grammar =
      Grammar.new(Shirt) do
        rule(Shirt) do
          declare("Size must be either large or small."){%w{small large}.include?(@size)}
          with_rule(Color){|rule|rule.apply_to(@color)}
        end
    
        rule(Color) do
          declare("Color must be either red or blue."){%w{red blue}.include?(@name)}
        end
      end    
  end


  #error conditions:
    #refereced rule not defined
    #...be helpful
  regarding "is an object well-formed according to the grammar" do    
    test "not well-formed.  the shirt is tiny, but only large and small are allowed" do
      assert{ @shirt_grammar.is_a?(Grammar) }
      result = @shirt_grammar.apply_to(Shirt.new("tiny", Color.new("red")))
      deny  { result.well_formed? }
      assert{ result.problems == 
                [Problem.new(Declaration.new("Size must be either large or small."), Shirt.new("tiny", Color.new("red")))]
      }
    end
    
    test "simple grammar" do
      assert{ @shirt_grammar.apply_to(Shirt.new("small", Color.new("red"))).well_formed? }
      assert{ @shirt_grammar.apply_to(Shirt.new("large", Color.new("red"))).well_formed? }
      assert{ @shirt_grammar.apply_to(Shirt.new("large", Color.new("blue"))).well_formed? }
      assert{ @shirt_grammar.apply_to(Shirt.new("small", Color.new("blue"))).well_formed? }

      deny  { @shirt_grammar.apply_to(Shirt.new("tiny", Color.new("blue"))).well_formed? }
      deny  { @shirt_grammar.apply_to(Shirt.new("small", Color.new("green"))).well_formed? }
    end
  end
  
  regarding "invalid grammar error" do
    test "the error message is from the first problem encountered" do
      assert{ 
        rescuing{@shirt_grammar.apply_to(Shirt.new("tiny", Color.new("green"))).well_formed!}.
          message == "Size must be either large or small."
      }
    end
    
    test "all the problems are available on the error" do
      assert{ 
        rescuing{@shirt_grammar.apply_to(Shirt.new("tiny", Color.new("green"))).well_formed!}.
          problems.collect{|p|p.message} == [
            "Size must be either large or small.",
            "Color must be either red or blue."
          ]
      }

    end
  end
  
  regarding "invalid grammars" do

    #need to be able to pass information about the stack...
      #the object traversal
      #the rule/condition path
      #a Path?

    test "must define at least one rule" do
      shirt_grammar_with_no_rules =
        Grammar.new(Shirt) do
        end
      
      assert{ 
        rescuing{shirt_grammar_with_no_rules.apply_to(nil)}.message == 
          "A Grammar must have at least one Rule."
      }
    end
    
    test "there was a reference for an unknown rule" do
      shirt_grammar_with_no_color_rule_defined =
        Grammar.new(Shirt) do
          rule(Shirt) do
            declare{["small", "large"].include?(@size)}
            with_rule(Color){|rule|rule.apply_to(@color)}
          end
        end
    end 
  end
end