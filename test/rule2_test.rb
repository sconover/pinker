require "./test/test_helper"

require "pinker/rule2"
include Pinker

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
      RuleBuilder.new(Color) {
        declare("Must be red."){@name=="red"}
      }.create_rule
  end
  
  regarding "basics - build a rule and apply_to it against an object" do

    test "basic apply_to" do
      assert{ @red_rule.apply_to(Color.new("red")).satisfied? }
      deny  { @red_rule.apply_to(Color.new("blue")).satisfied? }
    end

    test "instance variable" do
      blue_rule = 
        RuleBuilder.new(Color) {
          declare{@name=="blue"}
        }.create_rule

      assert{ blue_rule.apply_to(Color.new("blue")).satisfied? }
      deny  { blue_rule.apply_to(Color.new("red")).satisfied? }
    end
  
    test "methods" do
      green_rule = 
        RuleBuilder.new(Color) {
          declare{name_x=="greenx"}
        }.create_rule

      assert{ green_rule.apply_to(Color.new("green")).satisfied? }
      deny  { green_rule.apply_to(Color.new("blue")).satisfied? }
    end

    test "symbol name for rule" do
      rule_with_symbol_name = 
        RuleBuilder.new(:color) {
          declare{@name=="red"}
        }.create_rule

      assert{ rule_with_symbol_name.apply_to(Color.new("red")).satisfied? }
      deny  { rule_with_symbol_name.apply_to(Color.new("blue")).satisfied? }
    end

  end
end

regarding "result of rule application" do
  test "merging with another result merges problems and memory" do
    r1 = ResultOfRuleApplication2.new(
           [Problem.new(Declaration.new("Must be red."), "blue")], 
           {:a => 1}
         )
    r2 = ResultOfRuleApplication2.new(
           [Problem.new(Declaration.new("Must be blue."), "green")], 
           {:b => 2}
         )
    r3 = ResultOfRuleApplication2.new(
           [Problem.new(Declaration.new("Must be orange."), "yellow")], 
           {:a => 3}
         )
    
    assert{ r1.merge!(r2).problems == [
              Problem.new(Declaration.new("Must be red."), "blue"),
              Problem.new(Declaration.new("Must be blue."), "green")
            ] }

    assert{ r1.merge!(r3).problems == [
              Problem.new(Declaration.new("Must be red."), "blue"),
              Problem.new(Declaration.new("Must be blue."), "green"),
              Problem.new(Declaration.new("Must be orange."), "yellow")
            ] }

    assert{ r1.merge!(r3).memory == {:a => 3, :b => 2} }
  end
  
end
