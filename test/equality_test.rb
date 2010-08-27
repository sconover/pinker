require "./test/test_helper"

require "pinker/grammar"
include Pinker

regarding "prove value equality" do

  test "grammar" do
    assert{ Grammar.new(:A){rule(:a){}} == Grammar.new(:A){rule(:a){}} }

    deny  { Grammar.new(:A){rule(:a){}} == Grammar.new(:ZZZ){rule(:a){}} }
    deny  { Grammar.new(:A){rule(:a){}} == Grammar.new(:A){rule(:ZZZ){}} }
  end
    
  test "problem" do
    assert{ Problem.new(Declaration.new("a"), "objectA") == Problem.new(Declaration.new("a"), "objectA") }
    
    deny  { Problem.new(Declaration.new("a"), "objectA") == Problem.new(Declaration.new("ZZ"), "objectA") }
    deny  { Problem.new(Declaration.new("a"), "objectA") == Problem.new(Declaration.new("a"), "objectZZ") }
  end
    
  test "result of grammar application" do
    p1 = [Problem.new(Declaration.new("a"), "objectA")]
    p2 = [Problem.new(Declaration.new("a"), "objectA")]
    pZZ = [Problem.new(Declaration.new("ZZ"), "objectZZ")]

    assert{ ResultOfGrammarApplication.new(p1) == ResultOfGrammarApplication.new(p1) }
    
    deny  { ResultOfGrammarApplication.new(p1) == ResultOfGrammarApplication.new(pZZ) }
  end
    
  test "rule" do
    assert{ Rule.new(:a){declare("Must be red."){@color=="red"}} ==
              Rule.new(:a){declare("Must be red."){@color=="red"}} }

    deny  { Rule.new(:a){declare("Must be red."){@color=="red"}} ==
              Rule.new(:a){declare("Must be green."){@color=="green"}} }
    deny  { Rule.new(:a){declare("Must be red."){@color=="red"}} ==
              Rule.new(:ZZZ){declare("Must be red."){@color=="red"}} }
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
    assert { RuleDeclaration.new(:a) == RuleDeclaration.new(:a) }
    deny   { RuleDeclaration.new(:a) == RuleDeclaration.new(:ZZ) }
  end

end