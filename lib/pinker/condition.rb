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
    
    def condition(finder, constraint, custom_failure_message_template=nil)
      finder = instance_variable(finder.to_sym) if finder.is_a?(String) && finder =~ /^@/
      finder = method(finder) if finder.is_a?(Symbol)
      
      if constraint.is_a?(Predicated::Predicate)
        constraint = TemplatedPredicateHolder.new(constraint)
      elsif constraint.is_a?(Rule)
        constraint = RuleHolder.new(constraint)
      end
      
      condition = Condition.new(finder, constraint, custom_failure_message_template)
      @conditions << condition
      condition
    end
  end

  class Conditions < Array
    def problems_with(object)
      problems = Problems.new
      each do |condition|
        problems.push(*condition.problems_with(object))
      end
      problems
    end
    
    def evaluate_all(object)
      problems_with(object).empty?
    end
  end
    
  class Condition
    include ValueEquality
    
    def initialize(finder, constraint, custom_failure_message_template=nil)
      @finder = finder
      @constraint = constraint
      @custom_failure_message_template = custom_failure_message_template
    end
    
    def problems_with(object)
      object_part = @finder.pluck_from(object)
      @constraint.problems_with(object_part, @finder, @custom_failure_message_template)
    end

    def evaluate(object)
      problems_with(object).empty?
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
    
    def problems_with(actual_object, finder, custom_failure_message_template)
      expanded_predicate = resolve_predicate(actual_object)
      if expanded_predicate.evaluate
        []
      else
        templated_predicate = @templated_predicate #scoping, grr
        Problems.new{problem(condition(finder, templated_predicate), actual_object, custom_failure_message_template)}
      end
    end
  end
  
end

require "pinker/print_condition"