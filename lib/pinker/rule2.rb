require "pinker/rule"

module Pinker
  class RuleBuilder
    def initialize(rule_key, all_rules={}, &block)
      @rule_key = rule_key
      @parts = []
      @all_rules = all_rules
      @rule_list = []
      
      instance_eval(&block) if block
    end
    
    def declare(failure_message=nil, &block)
      @parts << Declaration2.new(failure_message, &block)
    end

    def remember(&block)
      @parts << Remembering.new(&block)
    end    

    def with_rule(rule_key, &block)
      @parts << RuleDeclaration2.new(rule_key, @all_rules, &block)
    end

    def rule(rule_key, &block)
      rule = self.class.new(rule_key, @all_rules, &block).build
      @all_rules[rule_key] = rule
      @rule_list << rule
      self
    end

    def build
      @parts.empty? && !@rule_list.empty? ? @rule_list.first : Rule2.new(@rule_key, @parts)
    end
  end
  
  class Rule2
    def initialize(rule_key, parts=[])
      @rule_key = rule_key
      @parts = parts
    end

    def apply_to(object)
      result = ResultOfRuleApplication2.new
      
      check_type(object, result) if @rule_key.is_a?(Class)
      
      @parts.each do |part|
        if result.satisfied?
          result.merge!(part.apply_to(object))
        else
          begin
            result.merge!(part.apply_to(object))
          rescue StandardError => intentionally_swallow_because_of_best_effort
          end  
        end
      end
      result
    end
    
    private
    def check_type(object, result)
      klass = @rule_key
      unless object.nil? || !klass.is_a?(Class) || object.is_a?(klass)
        result.problems << Problem.new(Declaration.new("Must be type #{klass.name}"), object, context={}) 
      end
    end
  end
  
  class AbstractDeclaration2
    def _handle_result(result, actual_object)
      if result.is_a?(ResultOfRuleApplication2)
        result
      elsif result
        ResultOfRuleApplication2.new([], {})
      else
        ResultOfRuleApplication2.new([Problem.new(self, actual_object)], {})
      end
    end
  end
  
  class Declaration2 < AbstractDeclaration2
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
      
      _handle_result(result, actual_object)
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

  
  class RuleDeclaration2 < AbstractDeclaration2
    attr_reader :rule_key
    
    def initialize(rule_key, all_rules, &block)
      @rule_key = rule_key
      @all_rules = all_rules
      @block = block
    end
    
    def apply_to(actual_object)
      _handle_result(actual_object.instance_exec(@all_rules[@rule_key], &@block), actual_object)
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
    
    def satisfied!
      unless satisfied?
        raise RuleViolationError.new(@problems.first.message, @problems)
      end
    end
    
    def merge!(other)
      @problems += other.problems
      @memory.merge!(other.memory)
      
      self
    end
  end
  
  class RuleViolationError < StandardError
    attr_reader :problems
    
    def initialize(message, problems)
      super(message)
      @problems = problems
    end
  end

end