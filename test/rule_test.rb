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
      Rule.new(Color) do 
        declare("Must be red."){@name=="red"}
      end
  end
  
  regarding "basics - build a rule and apply_to it against an object" do

    test "basic apply_to" do
      assert{ @red_rule.apply_to(Color.new("red")).satisfied? }
      deny  { @red_rule.apply_to(Color.new("blue")).satisfied? }
    end

    test "instance variable" do
      blue_rule = 
        Rule.new(Color) do 
          declare{@name=="blue"}
        end

      assert{ blue_rule.apply_to(Color.new("blue")).satisfied? }
      deny  { blue_rule.apply_to(Color.new("red")).satisfied? }
    end
  
    test "methods" do
      green_rule = 
        Rule.new(Color) do 
          declare{name_x=="greenx"}
        end

      assert{ green_rule.apply_to(Color.new("green")).satisfied? }
      deny  { green_rule.apply_to(Color.new("blue")).satisfied? }
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
          [Problem.new(Declaration.new("Must be red."), Color.new("blue"))]
      }
    end

    test "conform to another rule" do
      red_rule = @red_rule #block scoping
      shirt_rule =
        Rule.new(Shirt) do
          declare{red_rule.apply_to(@color)}
        end
      
      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("red"))).problems.empty? }
      assert{ shirt_rule.apply_to(Shirt.new("large", Color.new("blue"))).problems ==
                [Problem.new(Declaration.new("Must be red."), Color.new("blue"))] 
      }
    end
    
    test "no weird side effects of evaluation..." do
      red_rule = @red_rule #block scoping
      shirt_rule =
        Rule.new(Shirt) do
          declare{red_rule.apply_to(@color)}
        end
        
      shirt = Shirt.new("large", Color.new("red"))
      shirt_rule.apply_to(shirt)
      
      deny  { shirt.respond_to?(:declare) }
    end
    
    test "more complex rule" do
      red_rule = @red_rule #block scoping
      shirt_rule =
        Rule.new(Shirt) do
          declare{red_rule.apply_to(@color)}
          declare("Must be large."){@size=="large"}
        end

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
      empty_rule = Rule.new(Color)
      assert{ empty_rule.apply_to(Color.new("zzz")).satisfied? }
      assert{ empty_rule.apply_to(Shade.new("zzz")).satisfied? }
      deny  { empty_rule.apply_to("zzz").satisfied? }
    end
    
    test "but a rule allowing nil should work" do
      weird_rule = Rule.new(Color) {declare{@name.nil? || !@name.nil?}}
      assert{ weird_rule.apply_to(Color.new("zzz")).satisfied? }
      assert{ weird_rule.apply_to(nil).satisfied? }
      deny  { weird_rule.apply_to("zzz").satisfied? }
    end
    
  end


end