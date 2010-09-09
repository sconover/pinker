require "./test/test_helper"

require "pinker/rule"
require "pinker/addons/type_is"
include Pinker

regarding "check that self is the proper type.  convert self if appropriate." do
  
  class RuleBuilder
    include RuleBuilderAddons::TypeIs
  end
  
  test "basic pass/fail" do
    integer_rule =
      RuleBuilder.new(:integer_rule) {
        type_is{Integer}
      }.build

    assert{ integer_rule.apply_to(44).satisfied? }
    assert{ integer_rule.apply_to("55").satisfied? }
            
    deny  { integer_rule.apply_to("a").satisfied? }
    deny  { integer_rule.apply_to(44.2).satisfied? }
  end
    
end
