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
    
    #have to have at least one rule...
    
    def apply_to(object)
      ResultOfGrammarApplication.new(@rules.first.apply_to(object).problems)
    end
  end
  
  class ResultOfGrammarApplication
    include ValueEquality
    
    attr_reader :problems
    
    def initialize(problems)
      @problems = problems
    end
    
    def well_formed?
      @problems.empty?
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
    
    def problems_with(object)
      problems = Problems.new
      problems.push(*collect{|rule|rule.apply_to(object).problems}.flatten)
      problems
    end
  end

  module RuleContext
    def rule(name_or_class, &block)
      rule = Rule.new(name_or_class, :other_rules => @rules, &block)
      @rules << rule
      rule
    end
  end
  
end

require "pinker/print_grammar"