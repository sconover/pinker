require "pinker/rule"

module Pinker
  
  class Grammar
    include ValueEquality
    
    def initialize(name_or_class, &block)
      @name_or_class = name_or_class
      @rules = Rules.new
      
      add(&block) if block
    end
    
    def add(&block)
      rules = @rules
      Module.new do
        extend RuleContext
        @rules = rules
        instance_eval(&block)
      end
    end
    
    def apply_to(object)
    end
    
    def well_formed?(object)
      # return false if @name_or_class.is_a?(Class) && 
      #                 !object.nil? && 
      #                 !object.is_a?(@name_or_class)
      
      @rules.satisfies_all?(object)
    end
  end
  
  module RuleContext
    def rule(name_or_class, &block)
      rule = Rule.new(name_or_class, :other_rules => @rules, &block)
      @rules << rule
      rule
    end
  end
  
  class Rules < Array
    def [](key)
      #test for error condition - not found
      find{|rule|rule.name_or_class==key}
    end
    
    def satisfies_all?(object)
      find{|rule|rule.satisfied_by?(object)==false}.nil?
    end
  end

  module RuleContext
    def rule(name_or_class, &block)
      rule = Rule.new(name_or_class, :other_rules => @rules, &block)
      @rules << rule
      rule
    end
  end
  
  class Problems < Array
    def initialize(&block)
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

require "pinker/print_grammar"