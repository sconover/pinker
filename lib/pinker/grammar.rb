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
      self
    end
    
    def apply_to(object)
      i_am_well_formed!      
      apply_to_without_self_validation(object)
    end
    
    private
    def i_am_well_formed!
      grammar_grammar.send(:apply_to_without_self_validation, self).well_formed!
    end
    
    def apply_to_without_self_validation(object)
      first_rule_result = @rules.first.apply_to(object)
      ResultOfGrammarApplication.new(first_rule_result.problems, first_rule_result.memory)
    end
    
    def grammar_grammar
      Grammar.new(Grammar) do
        rule(Grammar) do
          with_rule(Rules){|rule|rule.apply_to(@rules)}
        end
        
        rule(Rules) do
          declare('A Grammar must have at least one Rule.'){!self.empty?}
        end
      end
    end
    
  end
  
  class InvalidGrammarError < StandardError; end
  
  class ResultOfGrammarApplication
    include ValueEquality
    
    attr_reader :problems, :memory
    
    def initialize(problems, memory={})
      @problems = problems
      @memory = memory
    end
    
    def well_formed?
      @problems.empty?
    end
    
    def well_formed!
      unless well_formed?
        raise InvalidGrammarError.new(problems.first.message)
      end
    end

  end
  
  module RuleContext
    def rule(name_or_class, &block)
      rule = Rule.new(name_or_class, :other_rules => @rules, &block)
      @rules << rule
      rule
    end
  end
  
  class RuleDeclaration < AbstractDeclaration
    attr_reader :rule_key
    
    def initialize(rule_key, &block)
      @rule_key = rule_key
      @block = block
    end
    
    def ==(other)
      @rule_key == other.rule_key
    end
  end
  
  module DeclarationContext
    def with_rule(rule_key, &block)
      other_rules = @other_rules
      declaration = 
        RuleDeclaration.new(rule_key) do 
          self.instance_exec(other_rules[rule_key], &block)
        end
      @declarations << declaration
      declaration
    end
  end
  
  class Rules < Array
    def [](key)
      #test for error condition - not found
      find{|rule|rule.name_or_class==key}
    end
    
    def problems_with(object)
      collect{|rule|rule.apply_to(object).problems}.flatten
    end
  end

end

require "pinker/print/print_grammar"