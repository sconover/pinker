require "predicated/predicate"
require "predicated/evaluate"
require "predicated/simple_templated_predicate"
require "predicated/autogen_call"

require "pinker/core"

module Pinker
  
  class Rule
    attr_reader :name_or_class, :conditions
    def initialize(name_or_class, options={}, &block)
      @name_or_class = name_or_class
      @other_rules = options[:other_rules]
      
      @conditions = Conditions.new
      
      add(&block) if block
    end
    
    def add(&block)
      other_rules = @other_rules
      conditions = @conditions
      Module.new do
        extend ConditionContext
        @other_rules = other_rules
        @conditions = conditions
        instance_eval(&block)
      end
    end
    
    def apply_to(object)
      problems = Problems.new
      unless object.nil? || object.is_a?(name_or_class)
        problems.compose do
          problem(condition(_object_, IsA?(name_or_class)), object)
        end
      end
      
      problems.push(*@conditions.problems_with(object))
      
      ResultOfRuleApplication.new(problems)
    end
    
    def ==(other)
      @name_or_class == other.name_or_class &&
      @conditions == other.conditions
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
    
  module ConditionContext
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

  class RuleReference
    attr_reader :rule_key
    
    def initialize(rule_key, other_rules)
      @rule_key = rule_key
      @other_rules = other_rules
    end
    
    def resolve_rule
      @other_rules[@rule_key]
    end
    
    def problems_with(object, finder, custom_failure_message_template)
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
    
    def problems_with(object, finder, custom_failure_message_template)
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
    
    def problems_with(actual_object, finder, custom_failure_message_template)
      expanded_predicate = resolve_predicate(actual_object)
      if expanded_predicate.evaluate
        []
      else
        
        custom_failure_message = 
          if custom_failure_message_template
            eval( '"' + custom_failure_message_template + '"' )
          else
            nil
          end
        
        templated_predicate = @templated_predicate #scoping, grr
        Problems.new{problem(condition(finder, templated_predicate), actual_object, custom_failure_message)}
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
  
end

require "pinker/problem"
require "pinker/print_rule"