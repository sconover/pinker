require "./test/test_helper"

require "pinker/rule"
include Pinker


  #error conditions:
    #no predicate or rule supplied
    #not a predicate or rule
    #invalid finder
    #...be helpful

  #symbol (vs class)
    #symbol plus class?
regarding "a rule" do

  class Color
    include ValueEquality
    def initialize(name)
      @name = name
    end
  
    def name_x
      @name + "x"
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
    @red_rule = 
      Rule.new(Color) do 
        condition(instance_variable("@name".to_sym), Eq("red"))
      end
  end
  
  regarding "basics - build a rule and apply_to it against an object" do

    test "basic apply_to" do
      assert{ @red_rule.apply_to(Color.new("red")).satisfied? }
      deny  { @red_rule.apply_to(Color.new("blue")).satisfied? }
    end

    test "finder shorthand - instance variables" do
      blue_rule = 
        Rule.new(Color) do 
          condition("@name", Eq("blue"))
        end

      assert{ blue_rule.apply_to(Color.new("blue")).satisfied? }
      deny  { blue_rule.apply_to(Color.new("red")).satisfied? }
    end
  
    test "method finder" do
      green_rule = 
        Rule.new(Color) do 
          condition(method(:name_x), Eq("greenx"))
        end

      assert{ green_rule.apply_to(Color.new("green")).satisfied? }
      deny  { green_rule.apply_to(Color.new("blue")).satisfied? }
    end

    test "finder shorthand - methods" do
      blue_rule = 
        Rule.new(Color) do 
          condition(:name_x, Eq("bluex"))
        end

      assert{ blue_rule.apply_to(Color.new("blue")).satisfied? }
      deny  { blue_rule.apply_to(Color.new("red")).satisfied? }
    end
  end
  
  regarding "apply_to is like apply_to but it gives more detail when things go wrong" do
    
    test "apply_to / result satisfied?" do
      assert{ @red_rule.apply_to(Color.new("red")).satisfied? }
      deny  { @red_rule.apply_to(Color.new("blue")).satisfied? }
    end

    test "show problems" do
      assert{ @red_rule.apply_to(Color.new("red")).problems.empty? }
      assert{ 
        @red_rule.apply_to(Color.new("blue")).problems == 
          Problems.new{problem(condition("@name", Eq("red")), "blue")}
      }
    end

    test "more complex rule with problems" do
      shirt_rule =
        Rule.new(Shirt) do
          condition("@size", Eq("large"))
          condition("@color", Rule.new(Color){condition("@name", Eq("red"))})
        end

      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("red"))).problems.empty? }
  
      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("blue"))).problems ==
                Problems.new{problem(condition("@name", Eq("red")), "blue")} }
      assert{ shirt_rule.apply_to(Shirt.new("small", Color.new("red"))).problems ==
                Problems.new{problem(condition("@size", Eq("large")), "small")} }
      assert{ shirt_rule.apply_to(Shirt.new("small", Color.new("blue"))).problems ==
                Problems.new{problem(condition("@size", Eq("large")), "small")
                             problem(condition("@name", Eq("red")), "blue")} }
    end

  end
  
  regarding "typing and nil" do
    
    class Shade < Color
    end
    
    test "failure if object type is not the same as the type known to the rule" do
      empty_rule = Rule.new(Color)
      assert{ empty_rule.apply_to(Color.new("zzz")).satisfied? }
      assert{ empty_rule.apply_to(Shade.new("zzz")).satisfied? }
      deny  { empty_rule.apply_to("zzz").satisfied? }
    end
    
    test "but a rule allowing nil should work" do
      weird_rule = Rule.new(Color) {condition("@name", Or(Nil?, Not(Nil?)))}
      assert{ weird_rule.apply_to(Color.new("zzz")).satisfied? }
      assert{ weird_rule.apply_to(nil).satisfied? }
      deny  { weird_rule.apply_to("zzz").satisfied? }
    end
    
  end

  regarding "reference to another rule" do
    
    test "should activate that rule with the found object" do
      shirt_rule =
        Rule.new(Shirt) do
          condition("@size", Eq("large"))
          condition("@color", Rule.new(Color){condition("@name", Eq("red"))})
        end
      
      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("red"))).satisfied? }
      deny  { shirt_rule.apply_to(Shirt.new("large", Color.new("blue"))).satisfied? }
      deny  { shirt_rule.apply_to(Shirt.new("small", Color.new("red"))).satisfied? }
    end
    
    #test error: hoped-for rule not there
    
    
    test "find the other rule at runtime" do
      other_rules = {
        Color => Rule.new(Color){condition("@name", Eq("red"))}
      }
      
      shirt_rule =
        Rule.new(Shirt, :other_rules => other_rules) do
          condition("@size", Eq("large"))
          condition("@color", rule(Color))
        end
      
      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("red"))).satisfied? }
      deny  { shirt_rule.apply_to(Shirt.new("large", Color.new("blue"))).satisfied? }
      deny  { shirt_rule.apply_to(Shirt.new("small", Color.new("red"))).satisfied? }
    end
    
  end
  
  
  regarding "a condition can have a custom message, and this message is communicated in the problem" do
    
    test "simple" do
      rule = 
        Rule.new(Color) do 
          condition(instance_variable("@name".to_sym), Eq("red"), "Needs to be red, sorry.")
        end
      
      assert{ rule.apply_to(Color.new("red")).satisfied? }
      assert{ rule.apply_to(Color.new("blue")).problems == 
                Problems.new do
                  problem(condition("@name", Eq("red")), "blue", "Needs to be red, sorry.")
                end
            }
    end
        
  end
  
end