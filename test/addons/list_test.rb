require "./test/test_helper"

require "pinker/rule"
require "pinker/addons/list"
include Pinker

regarding "check that the supplied values are contained in a list of possible values" do
  
  class RuleBuilder
    include RuleBuilderAddons::DeclareList
  end
  
  before do
    @color_rule =
      RuleBuilder.new(:colors) {
        declare_list{{:allowed => %w{red green blue}, :actual => self}}
      }.build
  end

  test "basic pass/fail" do
    assert{ @color_rule.apply_to(%w{red green blue}).satisfied? }
    assert{ @color_rule.apply_to(%w{red green}).satisfied? }
    assert{ @color_rule.apply_to(%w{red blue}).satisfied? }
    assert{ @color_rule.apply_to(%w{blue}).satisfied? }

    deny  { @color_rule.apply_to(%w{yellow}).satisfied? }  
    deny  { @color_rule.apply_to(%w{blue yellow}).satisfied? }  
  end
  
  test "allowed, actual, and not allowed lists are details within the problem" do
    problem_details = @color_rule.apply_to(%w{yellow}).problems.first.details
    assert{ problem_details[:actual] == %w{yellow} }  
    assert{ problem_details[:allowed] == %w{red green blue} }  
    assert{ problem_details[:not_allowed] == %w{yellow} }  

    problem_details = @color_rule.apply_to(%w{yellow blue}).problems.first.details
    assert{ problem_details[:actual] == %w{yellow blue} }  
    assert{ problem_details[:allowed] == %w{red green blue} }  
    assert{ problem_details[:not_allowed] == %w{yellow} }  
  end

  test "single value is surrounded with array" do
    assert{ @color_rule.apply_to("blue").satisfied? }
    deny  { @color_rule.apply_to("yellow").satisfied? }  

    problem_details = @color_rule.apply_to("yellow").problems.first.details
    assert{ problem_details[:actual] == %w{yellow} }  
    assert{ problem_details[:allowed] == %w{red green blue} }  
    assert{ problem_details[:not_allowed] == %w{yellow} }      
  end
    
  test "default failure message" do
    assert{ rescuing{@color_rule.apply_to(%w{yellow}).satisfied!}.
              message == "'yellow' is not allowed.  Valid values are 'red', 'green' and 'blue'." }  
    
    assert{ rescuing{@color_rule.apply_to(%w{111}).satisfied!}.
              message == "'111' is not allowed.  Valid values are 'red', 'green' and 'blue'." }  
    
    assert{ rescuing{@color_rule.apply_to(%w{yellow blue}).satisfied!}.
              message == "'yellow' is not allowed.  Valid values are 'red', 'green' and 'blue'." }  

    assert{ rescuing{@color_rule.apply_to(%w{yellow blue orange pink}).satisfied!}.
              message == "'yellow', 'orange' and 'pink' are not allowed.  Valid values are 'red', 'green' and 'blue'." }  
  end
  
  test "custom failure message" do
    my_color_rule =
      RuleBuilder.new(:colors) {
        declare_list(proc{|not_allowed, allowed|
                       "not allowed: " + not_allowed.join(",") + " allowed: " + allowed.join(",")
                     }){
          {:allowed => %w{red green blue}, :actual => self}
        }
      }.build


    assert{ rescuing{my_color_rule.apply_to(%w{yellow}).satisfied!}.
              message == "not allowed: yellow allowed: red,green,blue" }  
  end
  
  regarding "bad declare_list situations" do
  
    test "blows up if the results aren't in the expected format" do
      bad_list_rule =
        RuleBuilder.new(:colors) {
          declare_list{{:zzz => %w{red green blue}, :yyy => self}}
        }.build
      
      assert{ rescuing{bad_list_rule.apply_to(%w{red green blue})}.message == 
                "Bad declare_list.  You must return a hash containing the :allowed and :actual lists." }
    end

    test "nil doesn't work (the expression of nothing is an empty array)" do
      nil_allowed_rule =
        RuleBuilder.new(:colors) {
          declare_list{{:allowed => nil, :actual => [1]}}
        }.build

      assert{ rescuing{nil_allowed_rule.apply_to(%w{red green blue})}.message == 
                "Bad declare_list.  :allowed was nil.  The expression of nothing should be an empty array." }

      assert{ rescuing{@color_rule.apply_to(nil)}.message == 
                "Bad declare_list.  :actual was nil.  The expression of nothing should be an empty array." }
    end
    
  end  

  
end
