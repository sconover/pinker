require "predicated/predicate"
require "predicated/evaluate"
require "predicated/simple_templated_predicate"
require "predicated/autogen_call"

require "pinker/core"

module Pinker
  
  class Rule
    attr_reader :name_or_class, :expressions
    def initialize(name_or_class, options={}, &block)
      @name_or_class = name_or_class
      @other_rules = options[:other_rules]
      
      @expressions = Expressions.new
      
      add(&block) if block
    end
    
    def add(&block)
      other_rules = @other_rules
      expressions = @expressions
      Module.new do
        extend ExpressionContext
        @other_rules = other_rules
        @expressions = expressions
        instance_eval(&block)
      end
    end
    
    def apply_to(object)
      problems = Problems.new
      unless object.nil? || object.is_a?(name_or_class)
        problems.compose do
          problem(expression(_object_, IsA?(name_or_class)), object)
        end
      end
      
      problems.push(*@expressions.problems_with(object))
      
      ResultOfRuleApplication.new(problems)
    end
    
    def ==(other)
      @name_or_class == other.name_or_class &&
      @expressions == other.expressions
    end
  end
  
  class ResultOfRuleApplication
    include ValueEquality
    
    attr_reader :problems
    
    def initialize(problems)
      @problems = problems
    end
    
    def satisfied?
      @problems.empty?
    end
  end
    
  module ExpressionContext
    include Predicated::SimpleTemplatedShorthand

    def instance_variable(symbol)
      InstanceVariableFinder.new(symbol)
    end

    def method(symbol)
      MethodFinder.new(symbol)
    end
    
    def rule(key)
      RuleReference.new(key, @other_rules)
    end
    
    def _object_
      SelfFinder.new
    end
    
    def expression(finder, constraint)
      finder = instance_variable(finder.to_sym) if finder.is_a?(String) && finder =~ /^@/
      finder = method(finder) if finder.is_a?(Symbol)
      
      if constraint.is_a?(Predicated::Predicate)
        constraint = TemplatedPredicateHolder.new(constraint)
      elsif constraint.is_a?(Rule)
        constraint = RuleHolder.new(constraint)
      end
      
      expression = Expression.new(finder, constraint)
      @expressions << expression
      expression
    end
  end

  class Expressions < Array
    def problems_with(object)
      problems = Problems.new
      each do |expression|
        problems.push(*expression.problems_with(object))
      end
      problems
    end
    
    def evaluate_all(object)
      problems_with(object).empty?
    end
  end
    
  class Expression
    include ValueEquality
    
    def initialize(finder, constraint)
      @finder = finder
      @constraint = constraint
    end
    
    def problems_with(object)
      object_part = @finder.pluck_from(object)
      @constraint.problems_with(object_part, @finder)
    end

    def evaluate(object)
      problems_with(object).empty?
    end
  end

  class RuleReference
    attr_reader :rule_key
    
    def initialize(rule_key, other_rules)
      @rule_key = rule_key
      @other_rules = other_rules
    end
    
    def resolve_rule
      @other_rules[@rule_key]
    end
    
    def problems_with(object, finder)
      resolve_rule.apply_to(object).problems
    end
    
    def ==(other)
      @rule_key == other.rule_key
    end
  end
  
  class RuleHolder
    include ValueEquality
    
    def initialize(rule)
      @rule = rule
    end
    
    def problems_with(object, finder)
      @rule.apply_to(object).problems
    end
  end

  class TemplatedPredicateHolder
    include ValueEquality
    
    def initialize(templated_predicate)
      @templated_predicate = templated_predicate
    end
    
    def resolve_predicate(object)
      @templated_predicate.fill_in(object)
    end
    
    def problems_with(object, finder)
      expanded_predicate = resolve_predicate(object)
      if expanded_predicate.evaluate
        []
      else
        templated_predicate = @templated_predicate #scoping, grr
        Problems.new{problem(expression(finder, templated_predicate), object)}
      end
    end
  end
  
  class InstanceVariableFinder
    include ValueEquality
    
    def initialize(instance_variable_symbol)
      @instance_variable_symbol = instance_variable_symbol
    end
    
    def pluck_from(object)
      object.instance_variable_get(@instance_variable_symbol)
    end
  end
  
  class MethodFinder
    include ValueEquality
    
    def initialize(method_symbol)
      @method_symbol = method_symbol
    end
    
    def pluck_from(object)
      object.send(@method_symbol)
    end
  end
  
  class SelfFinder
    def pluck_from(object)
      object
    end
    
    def ==(other)
      other.is_a?(SelfFinder)
    end
  end
  
  class Problems < Array
    def initialize(&block)
      compose(&block) if block
    end    
    
    def compose(&block)
      problems = self
      Module.new do
        extend ProblemContext
        @expressions = []
        @problems = problems
        instance_eval(&block)
      end
    end
  end

  module ProblemContext
    include ExpressionContext
    
    def problem(expression, actual_object)
      problem = Problem.new(expression, actual_object)
      @problems << problem
      problem
    end
  end
  
  class Problem
    include ValueEquality
    
    def initialize(expression, actual_object)
      @expression = expression
      @actual_object = actual_object
    end    
  end

  
end

require "pinker/print_rule"