require "predicated/predicate"
require "predicated/simple_templated_predicate"
require "predicated/evaluate"
require "predicated/autogen_call"

module Pinker
  
  class Rule
    attr_reader :name_or_class
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
    
    def satisfied_by?(object)
      return false if @name_or_class.is_a?(Class) && 
                      !object.nil? && 
                      !object.is_a?(@name_or_class)
      
      @expressions.evaluate_all(object)
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
    
    def expression(finder, constraint)
      finder = instance_variable(finder.to_sym) if finder.is_a?(String) && finder =~ /^@/
      finder = method(finder) if finder.is_a?(Symbol)
      
      if constraint.is_a?(Predicated::Predicate)
        constraint = TemplatedPredicateHolder.new(constraint)
      elsif constraint.is_a?(Rule)
        constraint = RuleHolder.new(constraint)
      end
      
      @expressions << Expression.new(finder, constraint)
      self
    end
  end

  class Expressions < Array
    def evaluate_all(object)
      find{|expression|expression.evaluate(object)==false}.nil?
    end
  end
    
  class Expression
    def initialize(finder, constraint)
      @finder = finder
      @constraint = constraint
    end
    
    def evaluate(object)
      object_part = @finder.pluck_from(object)
      @constraint.evaluate(object_part)
    end
  end

  class RuleReference
    def initialize(rule_key, other_rules)
      @rule_key = rule_key
      @other_rules = other_rules
    end
    
    def resolve_rule
      @other_rules[@rule_key]
    end
    
    def evaluate(object)
      resolve_rule.satisfied_by?(object)
    end
  end
  
  class RuleHolder
    def initialize(rule)
      @rule = rule
    end
    
    def evaluate(object)
      @rule.satisfied_by?(object)
    end
  end

  class TemplatedPredicateHolder
    def initialize(templated_predicate)
      @templated_predicate = templated_predicate
    end
    
    def resolve_predicate(object)
      @templated_predicate.fill_in(object)
    end
    
    def evaluate(object)
      resolve_predicate(object).evaluate
    end
  end
  
  class InstanceVariableFinder
    def initialize(instance_variable_symbol)
      @instance_variable_symbol = instance_variable_symbol
    end
    
    def pluck_from(object)
      object.instance_variable_get(@instance_variable_symbol)
    end
  end
  
  class MethodFinder
    def initialize(method_symbol)
      @method_symbol = method_symbol
    end
    
    def pluck_from(object)
      object.send(@method_symbol)
    end
  end
  
end

require "pinker/print_rule"