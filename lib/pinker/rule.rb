require "predicated/predicate"
require "predicated/curried_predicate"
require "predicated/evaluate"
require "predicated/autogen_call"

module Pinker
  
  class Rule
    def initialize(name_or_class, &block)
      @name_or_class = name_or_class
      @expressions = Expressions.new
      
      add(&block) if block
    end
    
    def add(&block)
      expressions = nil
      Module.new do
        extend ExpressionContext
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
    include Predicated::CurriedShorthand

    def instance_variable(symbol)
      proc{|object|object.instance_variable_get(symbol)}
    end

    def method(symbol)
      proc{|object|object.send(symbol)}
    end
    
    def expression(finder, predicate)
      finder = instance_variable(finder.to_sym) if finder.is_a?(String) && finder =~ /^@/
      finder = method(finder) if finder.is_a?(Symbol)
      
      @expressions ||= []
      @expressions << [finder, predicate]
      self
    end
  end
  
  class Expression
    def initialize(finder, curried_predicate)
      @finder = finder
      @curried_predicate = curried_predicate
    end
    
    def evaluate(object)
      predicate = curried_predicate.apply(finder.call(object))
      predicate.evaluate
    end
  end
  
  class Expressions < Array
    def evaluate_all(object)
      didnt_work = 
        find do |finder, curried_predicate|
          predicate = curried_predicate.apply(finder.call(object))
          predicate.evaluate==false
        end
      didnt_work.nil?
    end
  end
end