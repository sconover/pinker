require "./test/test_helper"

require "pinker/rule2"
include Pinker

regarding "a rule can have other rules" do

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
      RuleBuilder.new(Shirt) {
        rule(Shirt) {
          declare("Size must be either large or small."){%w{small large}.include?(@size)}
          with_rule(Color){|rule|rule.apply_to(@color)}
        }
    
        rule(Color) {
          declare("Color must be either red or blue."){%w{red blue}.include?(@name)}
        }
      }.build
  end


  #error conditions:
    #refereced rule not defined
    #...be helpful
  regarding "is an object well-formed according to the grammar" do    
    test "not well-formed.  the shirt is tiny, but only large and small are allowed" do
      assert{ @shirt_grammar.is_a?(Rule2) }
      result = @shirt_grammar.apply_to(Shirt.new("tiny", Color.new("red")))
      deny  { result.satisfied? }
      assert{ result.problems == 
                [Problem.new(Declaration.new("Size must be either large or small."), Shirt.new("tiny", Color.new("red")))]
      }
    end
    
    test "simple grammar" do
      assert{ @shirt_grammar.apply_to(Shirt.new("small", Color.new("red"))).satisfied? }
      assert{ @shirt_grammar.apply_to(Shirt.new("large", Color.new("red"))).satisfied? }
      assert{ @shirt_grammar.apply_to(Shirt.new("large", Color.new("blue"))).satisfied? }
      assert{ @shirt_grammar.apply_to(Shirt.new("small", Color.new("blue"))).satisfied? }

      deny  { @shirt_grammar.apply_to(Shirt.new("tiny", Color.new("blue"))).satisfied? }
      deny  { @shirt_grammar.apply_to(Shirt.new("small", Color.new("green"))).satisfied? }
    end
  end
  
  regarding "invalid grammar error" do
    test "the error message is from the first problem encountered" do
      assert{ 
        rescuing{@shirt_grammar.apply_to(Shirt.new("tiny", Color.new("green"))).satisfied!}.
          message == "Size must be either large or small."
      }
    end
    
    test "all the problems are available on the error" do
      deny{ @shirt_grammar.apply_to(Shirt.new("tiny", Color.new("green"))).satisfied? }
      
      assert{ 
        rescuing{@shirt_grammar.apply_to(Shirt.new("tiny", Color.new("green"))).satisfied!}.
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

    test "there was a reference for an unknown rule" do
      shirt_grammar_with_no_color_rule_defined =
        RuleBuilder.new(Shirt) {
          rule(Shirt) {
            declare{["small", "large"].include?(@size)}
            with_rule(Color){|rule|rule.apply_to(@color)}
          }
        }.build
    end 
  end
end