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
    conditionA = Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{}))
    conditionZZ = Condition.new(MethodFinder.new(:ZZ), RuleReference.new(:ZZ,{}))
  
    assert{ Problem.new(conditionA, "objectA") == Problem.new(conditionA, "objectA") }
    
    deny  { Problem.new(conditionA, "objectA") == Problem.new(conditionZZ, "objectA") }
    deny  { Problem.new(conditionA, "objectA") == Problem.new(conditionA, "objectZZ") }
  end
    
  test "problem with custom message" do
    conditionA = Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{}))
    conditionZZ = Condition.new(MethodFinder.new(:ZZ), RuleReference.new(:ZZ,{}))
  
    assert{ Problem.new(conditionA, "objectA") == Problem.new(conditionA, "objectA") }
    assert{ Problem.new(conditionA, "objectA", :custom_message_template => "Custom message") == 
            Problem.new(conditionA, "objectA", :custom_message_template => "Custom message") }
    
    deny  { Problem.new(conditionA, "objectA") == Problem.new(conditionZZ, "objectA") }
    deny  { Problem.new(conditionA, "objectA") == Problem.new(conditionA, "objectZZ") }
    
    deny  { Problem.new(conditionA, "objectA", :custom_message_template => "One message") == 
            Problem.new(conditionA, "objectA", :custom_message_template => "Another message") }
  end
    
  test "problems" do
    assert{ Problems.new{problem(condition("@color", Eq("red")), "objectA")} == 
              Problems.new{problem(condition("@color", Eq("red")), "objectA")} }
    
    deny  { Problems.new{problem(condition("@color", Eq("red")), "objectA")} == 
              Problems.new{problem(condition("@ZZ", Eq("ZZ")), "ZZ")} }
  end
    
  test "result of grammar application" do
    p1 = Problems.new{problem(condition("@color", Eq("red")), "objectA")}
    p2 = Problems.new{problem(condition("@color", Eq("red")), "objectA")}
    pZZ = Problems.new{problem(condition("@ZZ", Eq("ZZ")), "ZZ")}

    assert{ ResultOfGrammarApplication.new(p1) == ResultOfGrammarApplication.new(p1) }
    
    deny  { ResultOfGrammarApplication.new(p1) == ResultOfGrammarApplication.new(pZZ) }
  end
    
  test "rule" do
    assert{ Rule.new(:a){condition("@size", Eq("large"))} ==
              Rule.new(:a){condition("@size", Eq("large"))} }

    deny  { Rule.new(:a){condition("@size", Eq("large"))} ==
              Rule.new(:ZZ){condition("@size", Eq("large"))} }
    deny  { Rule.new(:a){condition("@size", Eq("large"))} ==
              Rule.new(:a){condition("@ZZZ", Eq("large"))} }
    deny  { Rule.new(:a){condition("@size", Eq("large"))} ==
              Rule.new(:a){condition("@size", Eq("ZZZ"))} }
  end

  test "result of rule application" do
    p1 = Problems.new{problem(condition("@color", Eq("red")), "objectA")}
    p2 = Problems.new{problem(condition("@color", Eq("red")), "objectA")}
    pZZ = Problems.new{problem(condition("@ZZ", Eq("ZZ")), "ZZ")}

    assert{ ResultOfRuleApplication.new(p1) == ResultOfRuleApplication.new(p1) }
    
    deny  { ResultOfRuleApplication.new(p1) == ResultOfRuleApplication.new(pZZ) }
  end


  test "rule holder" do
    assert{ RuleHolder.new(Rule.new(:a){}) == RuleHolder.new(Rule.new(:a){}) }
    deny  { RuleHolder.new(Rule.new(:a){}) == RuleHolder.new(Rule.new(:ZZ){}) }
  end
  
  test "instance variable finder" do
    assert { InstanceVariableFinder.new("@a".to_sym) == InstanceVariableFinder.new("@a".to_sym) }
    deny   { InstanceVariableFinder.new("@a".to_sym) == InstanceVariableFinder.new("@b".to_sym) }
  end
  
  test "method finder" do
    assert { MethodFinder.new(:a) == MethodFinder.new(:a) }
    deny   { MethodFinder.new(:a) == MethodFinder.new(:ZZ) }
  end
    
  test "templated predicate holder" do
    extend Predicated
    assert { TemplatedPredicateHolder.new(SimpleTemplatedPredicate{Eq("large")}) == 
               TemplatedPredicateHolder.new(SimpleTemplatedPredicate{Eq("large")}) }

    deny   { TemplatedPredicateHolder.new(SimpleTemplatedPredicate{Eq("large")}) == 
               TemplatedPredicateHolder.new(SimpleTemplatedPredicate{Eq("small")}) }
  end
  
  test "rule reference" do
    assert { RuleReference.new(:a, {}) == RuleReference.new(:a, {}) }
    deny   { RuleReference.new(:a, {}) == RuleReference.new(:ZZ, {}) }
  end
  
  test "self finder" do
    assert { SelfFinder.new == SelfFinder.new }
    deny   { SelfFinder.new == RuleReference.new(:ZZ, {}) }
  end
  
  test "conditions" do
    a1 = Conditions.new
    a1 << Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{}))
    
    a2 = Conditions.new
    a2 << Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{}))
    
    b = Conditions.new
    b << Condition.new(MethodFinder.new(:ZZ), RuleReference.new(:ZZ,{}))
    
    assert { a1 == a2 }

    deny   { a1 == b }
  end
  
  test "condition" do
    assert { Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{})) ==
               Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{})) }
    assert { Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{}), 
                           :custom_message_template => 'Custom failure message template') ==
               Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{}), 
                            :custom_message_template => 'Custom failure message template') }

    deny   { Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{})) ==
               Condition.new(MethodFinder.new(:ZZ), RuleReference.new(:A,{})) }
    deny   { Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{})) ==
               Condition.new(MethodFinder.new(:a), RuleReference.new(:ZZ,{})) }
    deny   { Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{}), 
                           :custom_message_template => 'One message') ==
              Condition.new(MethodFinder.new(:a), RuleReference.new(:A,{}), 
                            :custom_message_template => 'Another message') }

  end
  
  test "declaration" do
    assert { Declaration.new("a") == Declaration.new("a") }
    deny   { Declaration.new("a") == Declaration.new("ZZ") }
  end
end