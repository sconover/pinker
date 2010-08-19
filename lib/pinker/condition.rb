require "predicated/predicate"
require "predicated/evaluate"
require "predicated/simple_templated_predicate"
require "predicated/autogen_call"

require "pinker/core"

module Pinker
  module ConditionContext
    include Predicated::SimpleTemplatedShorthand

    def instance_variable(symbol)
      InstanceVariableFinder.new(symbol)
    end

    def method(symbol)
      MethodFinder.new(symbol)
    end
        
    def _object_
      SelfFinder.new
    end
    
    def condition(finder, constraint, options={})
      finder = instance_variable(finder.to_sym) if finder.is_a?(String) && finder =~ /^@/
      finder = method(finder) if finder.is_a?(Symbol)
      
      if constraint.is_a?(Predicated::Predicate)
        constraint = TemplatedPredicateHolder.new(constraint)
      elsif constraint.is_a?(Rule)
        constraint = RuleHolder.new(constraint)
      end
      
      condition = Condition.new(finder, constraint, options)
      @conditions << condition
      condition
    end
  end

  class Conditions < Array
    def problems_with(object, path)
      problems = Problems.new
      each do |condition|
        problems.push(*condition.problems_with(object, path.dup))
      end
      problems
    end
    
    def evaluate_all(object)
      problems_with(object).empty?
    end
  end
    
  class Condition
    include ValueEquality
    
    def initialize(finder, constraint, options={})
      @finder = finder
      @constraint = constraint
      @options = options
    end
    
    def problems_with(object, path)
      object_part = @finder.pluck_from(object)
      path.push(self)
      @constraint.problems_with(object_part, @finder, @options.merge(:path => path.dup))
    end

    def evaluate(object, path)
      problems_with(object, path).empty?
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
  
  class TemplatedPredicateHolder
    include ValueEquality
    
    def initialize(templated_predicate)
      @templated_predicate = templated_predicate
    end
    
    def resolve_predicate(object)
      @templated_predicate.fill_in(object)
    end
    
    def problems_with(actual_object, finder, options)
      expanded_predicate = resolve_predicate(actual_object)
      if expanded_predicate.evaluate
        []
      else
        templated_predicate = @templated_predicate #scoping, grr
        Problems.new{problem(condition(finder, templated_predicate), actual_object, options)}
      end
    end
  end
  
end

require "pinker/print_condition"