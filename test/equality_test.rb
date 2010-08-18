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
    expressionA = Expression.new(MethodFinder.new(:a), RuleReference.new(:A,{}))
    expressionZZ = Expression.new(MethodFinder.new(:ZZ), RuleReference.new(:ZZ,{}))
  
    assert{ Problem.new(expressionA, "objectA") == Problem.new(expressionA, "objectA") }
    
    deny  { Problem.new(expressionA, "objectA") == Problem.new(expressionZZ, "objectA") }
    deny  { Problem.new(expressionA, "objectA") == Problem.new(expressionA, "objectZZ") }
  end
    
  test "problems" do
    assert{ Problems.new{problem(expression("@color", Eq("red")), "objectA")} == 
              Problems.new{problem(expression("@color", Eq("red")), "objectA")} }
    
    deny  { Problems.new{problem(expression("@color", Eq("red")), "objectA")} == 
              Problems.new{problem(expression("@ZZ", Eq("ZZ")), "ZZ")} }
  end
    
  test "rule" do
    assert{ Rule.new(:a){expression("@size", Eq("large"))} ==
              Rule.new(:a){expression("@size", Eq("large"))} }

    deny  { Rule.new(:a){expression("@size", Eq("large"))} ==
              Rule.new(:ZZ){expression("@size", Eq("large"))} }
    deny  { Rule.new(:a){expression("@size", Eq("large"))} ==
              Rule.new(:a){expression("@ZZZ", Eq("large"))} }
    deny  { Rule.new(:a){expression("@size", Eq("large"))} ==
              Rule.new(:a){expression("@size", Eq("ZZZ"))} }
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
  
  test "expressions" do
    a1 = Expressions.new
    a1 << Expression.new(MethodFinder.new(:a), RuleReference.new(:A,{}))
    
    a2 = Expressions.new
    a2 << Expression.new(MethodFinder.new(:a), RuleReference.new(:A,{}))
    
    b = Expressions.new
    b << Expression.new(MethodFinder.new(:ZZ), RuleReference.new(:ZZ,{}))
    
    assert { a1 == a2 }

    deny   { a1 == b }
  end
  
  test "expression" do
    assert { Expression.new(MethodFinder.new(:a), RuleReference.new(:A,{})) ==
               Expression.new(MethodFinder.new(:a), RuleReference.new(:A,{})) }

    deny   { Expression.new(MethodFinder.new(:a), RuleReference.new(:A,{})) ==
               Expression.new(MethodFinder.new(:ZZ), RuleReference.new(:A,{})) }
    deny   { Expression.new(MethodFinder.new(:a), RuleReference.new(:A,{})) ==
               Expression.new(MethodFinder.new(:a), RuleReference.new(:ZZ,{})) }
  end
  
end