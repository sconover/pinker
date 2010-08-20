require "pinker/core"
require "pinker/condition"
require "pinker/problem"

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
        extend DeclarationContext
        extend ConditionContext
        @other_rules = other_rules
        @conditions = conditions
        instance_eval(&block)
      end
    end
    
    def apply_to(object, path=[])
      problems = Problems.new
      unless object.nil? || object.is_a?(name_or_class)
        problems.compose do
          problem(condition(_object_, IsA?(name_or_class)), object)
        end
      end
      
      path.push(self)
      problems.push(*@conditions.problems_with(object, path.dup, {:rule => @other_rules}))
      
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

  module DeclarationContext
    def declare(failure_message=nil, &block)
      declaration = Declaration.new(failure_message, &block)
      @conditions << declaration
      declaration
    end
  end
  
  class Declaration
    attr_reader :failure_message
    
    def initialize(failure_message, &block)
      @failure_message = failure_message
      @block = block
    end
    
    def problems_with(object, path, context)
      path.push(self)

      result = instance_exec_block_with_context_as_local_variables(object, context)
      
      if result.is_a?(Problems)
        result
      elsif result.is_a?(ResultOfRuleApplication)
        result.problems
      elsif !result
        Problems.new.push(Problem.new(self, object))
      else
        []
      end
      
    end
        
    def ==(other)
      @failure_message == other.failure_message
    end
    
    private

    def instance_exec_block_with_context_as_local_variables(object, context)
      context_arr = context.to_a
      context_keys = []
      context_values = []
      context_arr.each{|k,v|context_keys << k; context_values << v}
      
      outer_block_with_local_variables = eval(%{proc do |#{context_keys.join(",")},_block_|
        self.instance_eval(&_block_)
      end})
      object.instance_exec(*(context_values + [@block]), &outer_block_with_local_variables)
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
    
    def problems_with(object, finder, options)
      resolve_rule.apply_to(object, options[:path].dup).problems
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
    
    def problems_with(object, finder, options)
      @rule.apply_to(object, options[:path].dup).problems
    end
  end

  module ConditionContext
    def rule(key)
      RuleReference.new(key, @other_rules)
    end
  end
  
end

require "pinker/print_rule"