require "./test/test_helper"

require "pinker/rule"
include Pinker

regarding "a rule" do

  class Color
    def initialize(name)
      @name = name
    end
  
    def name_x
      @name + "x"
    end
  end

  before do
    @red_rule = 
      Rule.new(Color) do 
        expression(instance_variable("@name".to_sym), Eq("red"))
      end
  end
  
  regarding "basics - build a rule and satisfied_by? it against an object" do

    test "basic satisfied_by?" do
      assert{ @red_rule.satisfied_by?(Color.new("red")) }
      deny  { @red_rule.satisfied_by?(Color.new("blue")) }
    end

    test "finder shorthand - instance variables" do
      blue_rule = 
        Rule.new(Color) do 
          expression("@name", Eq("blue"))
        end

      assert{ blue_rule.satisfied_by?(Color.new("blue")) }
      deny  { blue_rule.satisfied_by?(Color.new("red")) }
    end
  
    test "method finder" do
      green_rule = 
        Rule.new(Color) do 
          expression(method(:name_x), Eq("greenx"))
        end

      assert{ green_rule.satisfied_by?(Color.new("green")) }
      deny  { green_rule.satisfied_by?(Color.new("blue")) }
    end

    test "finder shorthand - methods" do
      blue_rule = 
        Rule.new(Color) do 
          expression(:name_x, Eq("bluex"))
        end

      assert{ blue_rule.satisfied_by?(Color.new("blue")) }
      deny  { blue_rule.satisfied_by?(Color.new("red")) }
    end
  end
  
  
  regarding "typing and nil" do
    
    class Shade < Color
    end
    
    test "failure if object type is not the same as the type known to the rule" do
      empty_rule = Rule.new(Color)
      assert{ empty_rule.satisfied_by?(Color.new("zzz")) }
      assert{ empty_rule.satisfied_by?(Shade.new("zzz")) }
      deny  { empty_rule.satisfied_by?("zzz") }
    end
    
    test "but a rule allowing nil should work" do
      weird_rule = Rule.new(Color) {expression("@name", Or(Nil?, Not(Nil?)))}
      assert{ weird_rule.satisfied_by?(Color.new("zzz")) }
      assert{ weird_rule.satisfied_by?(nil) }
      deny  { weird_rule.satisfied_by?("zzz") }
    end
    
  end
end