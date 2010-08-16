require "predicated/predicate"
require "predicated/curried_predicate"
require "predicated/evaluate"
require "predicated/autogen_call"

module Pinker
  
  class Rule
    def initialize(name_or_class, options={}, &block)
      @name_or_class = name_or_class
      @expressions = Expressions.new
      @other_rules = options[:other_rules]
      
      add(&block) if block
    end
    
    def add(&block)
      expressions = nil
      other_rules = @other_rules
      Module.new do
        extend ExpressionContext
        @other_rules = other_rules
        instance_eval(&block)
        expressions = @expressions
      end
      @expressions.push(*expressions)
    end
    
    def satisfied_by?(object)
      return false if @name_or_class.is_a?(Class) && 
                      !object.nil? && 
                      !object.is_a?(@name_or_class)
      
      @expressions.evaluate_all(object)
    end
  end
  
  module ExpressionContext
    include Predicated::CurriedShorthand

    def instance_variable(symbol)
      proc{|object|object.instance_variable_get(symbol)}
    end

    def method(symbol)
      proc{|object|object.send(symbol)}
    end
    
    def rule(key)
      proc{@other_rules[key]}
    end
    
    def expression(finder, curried_predicate_or_rule)
      finder = instance_variable(finder.to_sym) if finder.is_a?(String) && finder =~ /^@/
      finder = method(finder) if finder.is_a?(Symbol)
      
      @expressions ||= []
      @expressions << Expression.new(finder, curried_predicate_or_rule)
      self
    end
  end
  
  class Expression
    def initialize(finder, curried_predicate_or_rule)
      @finder = finder
      @curried_predicate_or_rule = curried_predicate_or_rule
    end
    
    def evaluate(object)
      object_part = @finder.call(object)
      if @curried_predicate_or_rule.is_a?(Proc)
        @curried_predicate_or_rule = @curried_predicate_or_rule.call 
      end
      
      if @curried_predicate_or_rule.is_a?(Rule)
        @curried_predicate_or_rule.satisfied_by?(object_part)
      else
        predicate = @curried_predicate_or_rule.apply(object_part)
        predicate.evaluate
      end
    end
  end
  
  class Expressions < Array
    def evaluate_all(object)
      find{|expression|expression.evaluate(object)==false}.nil?
    end
  end
end