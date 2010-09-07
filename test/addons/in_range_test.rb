require "./test/test_helper"

require "pinker/rule"
require "pinker/addons/in_range"
include Pinker

regarding "check that the supplied values are contained in a range" do
  
  class RuleBuilder
    include RuleBuilderAddons::InRange
  end
  
  before do
    @above_freezing_rule =
      RuleBuilder.new(:above_freezing_rule) {
        in_range{{:allowed => 33..130, :actual => self}}
      }.build
  end

  test "basic pass/fail" do
    assert{ @above_freezing_rule.apply_to(44).satisfied? }

    deny  { @above_freezing_rule.apply_to(22).satisfied? }
    deny  { @above_freezing_rule.apply_to(166).satisfied? }
  end
  
  test "type failure" do
    deny  { @above_freezing_rule.apply_to("a").satisfied? }
  end
  
  test "allowed, actual are details within the problem" do
    problem_details = @above_freezing_rule.apply_to(22).problems.first.details
    assert{ problem_details[:actual] == 22 }  
    assert{ problem_details[:allowed] == (33..130) }
  end

  test "default failure message" do
    assert{ rescuing{@above_freezing_rule.apply_to(22).satisfied!}.
              message == "'22' is out of range.  Value must be between 33 and 130." }  
  end
  
  test "custom failure message" do
    my_range_rule =
      RuleBuilder.new(:my_range_rule) {
        in_range(proc{|actual, allowed|
                       "actual: " + actual.to_s + " allowed: " + allowed.to_s
                     }){
          {:allowed => 33..130, :actual => self}
        }
      }.build


    assert{ rescuing{my_range_rule.apply_to(22).satisfied!}.
              message == "actual: 22 allowed: 33..130" }  
  end
  
  test "actual is self by default" do
    my_range_rule =
      RuleBuilder.new(:my_range_rule) {
        in_range{{:allowed => 33..130}}
      }.build

    assert{ my_range_rule.apply_to(44).satisfied? }
    deny  { my_range_rule.apply_to(22).satisfied? }
  end
  
  test "allowed is a simple array by default" do
    my_range_rule =
      RuleBuilder.new(:my_range_rule) {
        in_range{33..130}
      }.build

    assert{ my_range_rule.apply_to(44).satisfied? }
    deny  { my_range_rule.apply_to(22).satisfied? }
  end
  
  regarding "bad in_range situations" do
  
    test "blows up if the results aren't in the expected format" do
      bad_range_rule =
        RuleBuilder.new(:range) {
          in_range{{:zzz => 33..130, :yyy => self}}
        }.build
      
      assert{ rescuing{bad_range_rule.apply_to(44)}.message == 
                "Bad in_range.  You must return a hash containing the :allowed range and :actual value." }
    end

  end  

  
end
