require "pinker/rule"

module Pinker
  
  class Grammar
    include ValueEquality
    
    # GRAMMAR_GRAMMAR = 
    #   Grammar.new(Grammar) do
    #     rule(Grammar) do
    #       condition("@rules", rule(Rules))
    #     end
    #     
    #     rule(Rules) do
    #       condition(__object__, Not(Empty?), "A Grammar must have at least one Rule.\n#{actual_object.inspect}")
    #     end
    #   end
    # 
    
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
      # result = GRAMMAR_GRAMMAR.apply_to(self)
      # unless result.well_formed?
      #   raise InvalidGrammarError.new(result.problems.first)
      # end
      ResultOfGrammarApplication.new(@rules.first.apply_to(object).problems)
    end
    
  end
  
  class InvalidGrammarError < StandardError
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