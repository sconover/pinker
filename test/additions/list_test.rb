require "./test/test_helper"

require "pinker/rule"
require "pinker/additions/list"
include Pinker

regarding "check that the supplied values are contained in a list of possible values" do
  
  class RuleBuilder
    include RuleBuilderAdditions::DeclareList
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
