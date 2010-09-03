require "pinker/rule"

module Pinker
  class RuleBuilder
    def initialize(rule_key, &block)
      @rule_key = rule_key
      @parts = []
      @rules = {}
      
      instance_eval(&block) if block
    end
    
    def declare(failure_message=nil, &block)
      @parts << Declaration2.new(failure_message, &block)
    end

    def remember(&block)
      @parts << Remembering.new(&block)
    end    

    def with_rule(rule_key, &block)
      @parts << RuleDeclaration2.new(rule_key, @rules, &block)
    end

    def rule(rule_key, &block)
      rule = self.class.new(rule_key).instance_eval(&block).build
      @rules[rule_key] = rule
    end

    def build
      Rule2.new(@rule_key, @parts)
    end
  end
  
  class Rule2
    def initialize(id, parts=[])
      @id = id
      @parts = parts
    end

    def apply_to(object)
      result = ResultOfRuleApplication2.new
      problems = []
      @parts.each do |part|
        result.merge!(part.apply_to(object))
      end
      result
    end
  end
  
  class Declaration2 < AbstractDeclaration
    attr_reader :failure_message
    
    def initialize(failure_message=nil, &block)
      @failure_message = failure_message
      @block = block
    end
        
    def ==(other)
      @failure_message == other.failure_message
    end
    
    def with_new_failure_message(failure_message)
      self.class.new(failure_message, &@block)
    end
    
    def apply_to(actual_object)
      call = DeclarationCall2.new(self, actual_object)
      
      result = 
        if @block.arity<=0
          actual_object.instance_eval(&@block)
        elsif @block.arity==1
          result_from_block = actual_object.instance_exec(call, &@block)
          
          if call.failed?
            call.result
          else
            result_from_block  
          end
        else
          raise "invalid arity" #use a grammar for this?
        end
      
      if result.is_a?(ResultOfRuleApplication2)
        result
      elsif result
        ResultOfRuleApplication2.new([], {})
      else
        ResultOfRuleApplication2.new([Problem.new(self, actual_object)], {})
      end
    end
  end

  
  class DeclarationCall2
    attr_reader :result
    
    def initialize(declaration, actual_object)
      @declaration = declaration
      @actual_object = actual_object
      @result = ResultOfRuleApplication2.new([], {})
      @failed = false
    end
    
    def fail(failure_message=nil, details={})
      declaration = 
        failure_message ? 
          @declaration.with_new_failure_message(failure_message) :
          @declaration
          
      @failed = true
      @result.problems << Problem.new(declaration, @actual_object, {}, details)
    end
    
    def failed?
      @failed
    end
  end

  
  class RuleDeclaration2
    attr_reader :rule_key
    
    def initialize(rule_key, all_rules, &block)
      @rule_key = rule_key
      @all_rules = all_rules
      @block = block
    end
    
    def apply_to(actual_object)
      raise "boom"
      actual_object.instance_exec(@all_rules[@rule_key], &block)
    end
    
    def ==(other)
      @rule_key == other.rule_key
    end
  end

  class ResultOfRuleApplication2
    include ValueEquality
    
    attr_reader :problems, :memory
    
    def initialize(problems=[], memory={})
      @problems = problems
      @memory = memory
    end
    
    def satisfied?
      @problems.empty?
    end
    
    def merge!(other)
      @problems += other.problems
      @memory.merge!(other.memory)
      
      self
    end
  end
end