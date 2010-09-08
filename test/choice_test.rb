require "./test/test_helper"

require "pinker/rule"
include Pinker

xregarding "choice tries options until it finds one that works.  or it fails." do

  test "try until one works" do
    rule =
      RuleBuilder.new(:colors) {
        choice{ 
          option{declare{self=="red"}} 
          option{declare{self=="green"}}
        }
      }.build
      
    assert{ rule.apply_to("red").satisfied? }
    assert{ rule.apply_to("green").satisfied? }
    deny  { rule.apply_to("blue").satisfied? }
  end
  
end
