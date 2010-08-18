require "./test/test_helper"

require "pinker/grammar"
include Pinker

regarding "a grammar is a set of rules" do

  class Color
    def initialize(name)
      @name = name
    end
  end
  
  class Shirt
    def initialize(size, color)
      @size = size
      @color = color
    end
  end

  #error conditions:
    #refereced rule not defined
    #...be helpful
  regarding "is an object well-formed according to the grammar" do
    before do
      @shirt_grammar =
        Grammar.new(Shirt) do
          rule(Shirt) do
            expression("@size", Or(Eq("small"), Eq("large"))) #future: replace with In
            expression("@color", rule(Color))
          end
      
          rule(Color) do
            expression("@name", Or(Eq("red"), Eq("blue"))) #future: replace with In
          end
        end    
    end
    
    test "not well-formed.  the shirt is tiny, but only large and small are allowed" do
      result = @shirt_grammar.apply_to(Shirt.new("tiny", Color.new("blue")))
      deny  { result.well_formed? }
      assert{ result.problems == 
                Problems.new do
                  problem(expression("@size", Or(Eq("small"), Eq("large"))), "tiny")
                end }
    end
    
    test "simple grammar" do
    
      assert{ @shirt_grammar.well_formed?(Shirt.new("small", Color.new("red"))) }
      assert{ @shirt_grammar.well_formed?(Shirt.new("large", Color.new("red"))) }
      assert{ @shirt_grammar.well_formed?(Shirt.new("large", Color.new("blue"))) }
      assert{ @shirt_grammar.well_formed?(Shirt.new("small", Color.new("blue"))) }
              
      deny  { @shirt_grammar.well_formed?(Shirt.new("tiny", Color.new("blue"))) }
      deny  { @shirt_grammar.well_formed?(Shirt.new("small", Color.new("green"))) }
    end
  end
end