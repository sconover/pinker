require "./test/test_helper"

require "pinker/rule"
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
      }.build
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
        }.build

      assert{ blue_rule.apply_to(Color.new("blue")).satisfied? }
      deny  { blue_rule.apply_to(Color.new("red")).satisfied? }
    end
  
    test "methods" do
      green_rule = 
        RuleBuilder.new(Color) {
          declare{name_x=="greenx"}
        }.build

      assert{ green_rule.apply_to(Color.new("green")).satisfied? }
      deny  { green_rule.apply_to(Color.new("blue")).satisfied? }
    end

    test "symbol name for rule" do
      rule_with_symbol_name = 
        RuleBuilder.new(:color) {
          declare{@name=="red"}
        }.build

      assert{ rule_with_symbol_name.apply_to(Color.new("red")).satisfied? }
      deny  { rule_with_symbol_name.apply_to(Color.new("blue")).satisfied? }
    end

  end
  
  
  regarding "detail when things go wrong" do
    
    test "apply_to / result satisfied?" do
      assert{ @red_rule.apply_to(Color.new("red")).satisfied? }
      deny  { @red_rule.apply_to(Color.new("blue")).satisfied? }
    end

    test "empty declare" do
      red_rule =
        RuleBuilder.new(Color) {
          declare{@name=="red"}
        }.build
      
      assert{ red_rule.apply_to(Color.new("red")).satisfied? }
      deny  { red_rule.apply_to(Color.new("blue")).satisfied? }
    end


    test "show problems" do
      assert{ @red_rule.apply_to(Color.new("red")).problems.empty? }
      assert{ 
        @red_rule.apply_to(Color.new("blue")).problems == 
          [Problem.new(Declaration.new("Must be red."), Color.new("blue"))]
      }
    end

    test "conform to another rule" do
      red_rule = @red_rule #block scoping
      shirt_rule =
        RuleBuilder.new(Shirt) {
          declare{red_rule.apply_to(@color)}
        }.build
      
      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("red"))).problems.empty? }
      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("blue"))).problems ==
                [Problem.new(Declaration.new("Must be red."), Color.new("blue"))] 
      }
    end
    
    test "no weird side effects of evaluation..." do
      red_rule = @red_rule #block scoping
      shirt_rule =
        RuleBuilder.new(Shirt) {
          declare{red_rule.apply_to(@color)}
        }.build
        
      shirt = Shirt.new("large", Color.new("red"))
      shirt_rule.apply_to(shirt)
      
      deny  { shirt.respond_to?(:declare) }
    end
    
    test "optional declare form with call object" do
      green_rule =
        RuleBuilder.new(Color) {
          declare { |call|
            @name=="green" || call.fail("Must be green.")
          }
        }.build

      assert{ green_rule.apply_to(Color.new("green")).problems.empty? }
      assert{ 
        green_rule.apply_to(Color.new("blue")).problems == 
          [Problem.new(Declaration.new("Must be green."), Color.new("blue"))]
      }
    end

    test "provide details in the call that end up in the problem object" do
      green_rule =
        RuleBuilder.new(Color) {
          declare { |call|
            @name=="green" || call.fail("Must be green.", :was => @name, :should_be => "green")
          }
        }.build

      assert{ 
        green_rule.apply_to(Color.new("blue")).problems.first.details == 
          {:was => "blue", :should_be => "green"}
      }
    end

    test "in the call form, if fail is not called we treat the return value of the block as the result of the declare" do
      green_rule =
        RuleBuilder.new(Color) {
          declare { |call|
            @name=="green"
          }
        }.build

      assert{ green_rule.apply_to(Color.new("green")).satisfied? }
      deny  { green_rule.apply_to(Color.new("blue")).satisfied? }
    end

    
    test "more complex rule" do
      red_rule = @red_rule #block scoping
      shirt_rule =
        RuleBuilder.new(Shirt) {
          declare{red_rule.apply_to(@color)}
          declare("Must be large."){@size=="large"}
        }.build

      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("red"))).problems.empty? }
  
      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("blue"))).problems ==
                [Problem.new(Declaration.new("Must be red."), Color.new("blue"))] 
      }
      assert{ shirt_rule.apply_to(Shirt.new("small", Color.new("red"))).problems ==
                [Problem.new(Declaration.new("Must be large."), 
                             Shirt.new("small", Color.new("red")))] 
      }
      assert{ shirt_rule.apply_to(Shirt.new("small", Color.new("blue"))).problems ==
                [
                  Problem.new(Declaration.new("Must be red."), Color.new("blue")),
                  Problem.new(Declaration.new("Must be large."), 
                                              Shirt.new("small", Color.new("blue")))
                ]
      }
    end

  end

    regarding "typing and nil" do
    
    class Shade < Color
    end
    
    test "failure if object type is not the same as the type known to the rule" do
      empty_rule = RuleBuilder.new(Color).build
      assert{ empty_rule.apply_to(Color.new("zzz")).satisfied? }
      assert{ empty_rule.apply_to(Shade.new("zzz")).satisfied? }
      deny  { empty_rule.apply_to("zzz").satisfied? }
    end
    
    test "but a rule allowing nil should work" do
      weird_rule = RuleBuilder.new(Color) {declare{@name.nil? || !@name.nil?}}.build
      assert{ weird_rule.apply_to(Color.new("zzz")).satisfied? }
      assert{ weird_rule.apply_to(nil).satisfied? }
      deny  { weird_rule.apply_to("zzz").satisfied? }
    end
    
  end

  regarding "best effort" do
    test "don't swallow declare exceptions if nothing has failed yet" do
      shirt_rule =
        RuleBuilder.new(Shirt) {
          declare("Must be large."){@size=="large"}
          declare{zzz == "blam"}
        }.build
        
      assert{ rescuing{shirt_rule.apply_to(Shirt.new("large", Color.new("red")))} != nil }
    end
    
    test "swallow subsequent declare exceptions if a declare has failed already" do
      shirt_rule =
        RuleBuilder.new(Shirt) {
          declare("Must be large."){@size=="large"}
          declare{zzz == "blam"}
        }.build
        
      small_shirt = Shirt.new("small", Color.new("red"))
      assert{ rescuing{shirt_rule.apply_to(small_shirt)} == nil }
      assert{ shirt_rule.apply_to(small_shirt).problems == [
                Problem.new(Declaration.new("Must be large."), small_shirt)
              ] }
    end

  end

  
end

regarding "result of rule application" do
  test "merging with another result merges problems and memory" do
    r1 = ResultOfRuleApplication.new(
           [Problem.new(Declaration.new("Must be red."), "blue")], 
           {:a => 1}
         )
    r2 = ResultOfRuleApplication.new(
           [Problem.new(Declaration.new("Must be blue."), "green")], 
           {:b => 2}
         )
    r3 = ResultOfRuleApplication.new(
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
