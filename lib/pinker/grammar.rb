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
    
    #have to have at least one rule...
    
    def apply_to(object, path=[])
      i_am_well_formed!      
      apply_to_without_self_validation(object, path)
    end
    
    private
    def i_am_well_formed!
      result = grammar_grammar.send(:apply_to_without_self_validation, self, [self])
      unless result.well_formed?
        raise InvalidGrammarError.new(result.problems.first.message)
      end
    end
    
    def apply_to_without_self_validation(object, path=[])
      path.push(self)
      ResultOfGrammarApplication.new(@rules.first.apply_to(object, path).problems)
    end
    
    def grammar_grammar
      Grammar.new(Grammar) do
        rule(Grammar) do
          condition("@rules", rule(Rules))
        end
        
        rule(Rules) do
          condition(_object_, Not(Empty?), 
                    :custom_message_template => 'A Grammar must have at least one Rule.\n#{path.first.inspect}')
        end
      end
    end
    
  end
  
  class InvalidGrammarError < StandardError; end
  
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
  
  class RuleDeclaration < AbstractDeclaration
    def initialize(rule_key, &block)
      @rule_key = rule_key
      @block = block
    end
  end
  
  module DeclarationContext
    def with_rule(rule_key, &block)
      other_rules = @other_rules
      declaration = RuleDeclaration.new(rule_key){self.instance_exec(other_rules[rule_key], &block)}
      @conditions << declaration
      declaration
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

end

require "pinker/print_grammar"