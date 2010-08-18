require "./test/test_helper"

require "pinker/rule"
include Pinker

regarding "rule printing" do
  class Color; end
  class Shirt; end
  
  regarding "a rule looks nice with you to_s it" do
      
    test "simple" do
      assert{ Rule.new(Color) { expression("@name", Eq("red")) }.to_s == 
                %{Rule(Color)[@name->Eq('red')]} }

      assert{ Rule.new(Color) { expression(_object_, Eq("red")) }.to_s == 
                %{Rule(Color)[_object_->Eq('red')]} }

      assert{ Rule.new(:red_color_rule) { expression("@name", Eq("red")) }.to_s == 
                %{Rule(:red_color_rule)[@name->Eq('red')]} }

      assert{ Rule.new(Color) { expression(:name, Eq("red")) }.to_s == 
                %{Rule(Color)[:name->Eq('red')]} }
    end
    
    test "several conditions" do
      assert {
        Rule.new(Shirt) do 
          expression("@color", Eq("red"))
          expression(:size, Eq("large"))
        end.to_s ==
        %{Rule(Shirt)[@color->Eq('red'),:size->Eq('large')]}
      }
    end
    
    test "points to another rule" do
      red_color_rule = Rule.new(:red_color_rule) { expression("@name", Eq("red")) }
      assert {
        Rule.new(Shirt) {expression("@color", red_color_rule)}.to_s ==
          %{Rule(Shirt)[@color->Rule(:red_color_rule)[@name->Eq('red')]]}
      }
    end
    
    test "references another rule" do
      assert {
        Rule.new(Shirt) {expression("@color", rule(Color))}.to_s ==
          %{Rule(Shirt)[@color->rule(Color)]}
      }
    end
    
    test "complex predicate" do
      assert {
        Rule.new(Shirt) {expression(:size, Or(Eq("large"),Eq("small")))}.to_s ==
          %{Rule(Shirt)[:size->Or(Eq('large'),Eq('small'))]}
      }
    end
    
  end

  regarding "inspect is like to_s except it's multiline, so you see the tree structure" do
    
    test "one expression" do
      red_color_rule = Rule.new(:red_color_rule) { expression("@name", Eq("red")) }
      assert {
        Rule.new(Shirt) do 
          expression("@color", red_color_rule)
        end.inspect ==
%{Rule(Shirt)[
  @color->Rule(:red_color_rule)[
    @name->Eq('red')
  ]
]
}
      }
    end
  
    test "more than one expression" do
      red_color_rule = Rule.new(:red_color_rule) { expression("@name", Eq("red")) }
      assert {
        Rule.new(Shirt) do 
          expression("@color", red_color_rule)
          expression("@color2", rule(Color))
          expression(:size, Eq("large"))
        end.inspect ==
%{Rule(Shirt)[
  @color->Rule(:red_color_rule)[
    @name->Eq('red')
  ],
  @color2->rule(Color),
  :size->Eq('large')
]
}
      }
    end
    
    test "nesting" do
      assert {
        Rule.new(Shirt) do 
          expression("@color", Rule.new(:red_color_rule) do 
                                 expression("@name", Rule.new(:name_is_sam) do        
                                                       expression("@first_name", Eq("Sam")) 
                                                     end) 
                               end)
        end.inspect ==
%{Rule(Shirt)[
  @color->Rule(:red_color_rule)[
    @name->Rule(:name_is_sam)[
      @first_name->Eq('Sam')
    ]
  ]
]
}
      }
    end
    
    test "complex predicates chop down too" do
      assert {
        Rule.new(Shirt) do 
          expression(:size, Or(Eq("large"),Eq("small")))
        end.inspect ==
%{Rule(Shirt)[
  :size->Or(
    Eq('large'),
    Eq('small')
  )
]
}
      }

    end
  end
end