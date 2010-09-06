require "./test/test_helper"

require "pinker/rule2"
include Pinker

regarding "prove value equality" do

  test "problem" do
    assert{ Problem.new(Declaration.new("a"), "objectA") == Problem.new(Declaration.new("a"), "objectA") }
    
    deny  { Problem.new(Declaration.new("a"), "objectA") == Problem.new(Declaration.new("ZZ"), "objectA") }
    deny  { Problem.new(Declaration.new("a"), "objectA") == Problem.new(Declaration.new("a"), "objectZZ") }
  end
    
  test "rule" do
    assert{ RuleBuilder.new(:a){declare("Must be red."){@color=="red"}}.build ==
              RuleBuilder.new(:a){declare("Must be red."){@color=="red"}}.build }

    deny  { RuleBuilder.new(:a){declare("Must be red."){@color=="red"}}.build ==
              RuleBuilder.new(:a){declare("Must be green."){@color=="green"}}.build }
    deny  { RuleBuilder.new(:a){declare("Must be red."){@color=="red"}}.build ==
              RuleBuilder.new(:ZZZ){declare("Must be red."){@color=="red"}}.build }
  end

  test "result of rule application - problems differ" do
    p1 = [Problem.new(Declaration.new("a"), "objectA")]
    p2 = [Problem.new(Declaration.new("a"), "objectA")]
    pZZ = [Problem.new(Declaration.new("ZZ"), "objectZZ")]
    
    assert{ ResultOfRuleApplication.new(p1, memory={}) == ResultOfRuleApplication.new(p1, memory={}) }
    
    deny  { ResultOfRuleApplication.new(p1, memory={}) == ResultOfRuleApplication.new(pZZ, memory={}) }
  end

  test "result of rule application - memories differ" do
    p1 = [Problem.new(Declaration.new("a"), "objectA")]

    assert{ ResultOfRuleApplication.new(p1, {:a => 1}) == ResultOfRuleApplication.new(p1, {:a => 1}) }
    
    deny  { ResultOfRuleApplication.new(p1, {:a => 1}) == ResultOfRuleApplication.new(p1, {:a => "ZZ"}) }
  end

  test "declaration" do
    assert { Declaration.new("a") == Declaration.new("a") }
    deny   { Declaration.new("a") == Declaration.new("ZZ") }
  end

  test "rule declaration" do
    assert { RuleDeclaration.new(:a, {}) == RuleDeclaration.new(:a, {}) }
    deny   { RuleDeclaration.new(:a, {}) == RuleDeclaration.new(:ZZ, {}) }
  end

end