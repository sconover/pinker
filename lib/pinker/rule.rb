require "pinker/core"

module Pinker
  
  #grammar grammar:
    #block arity
    #intermingling of declares and rules.
      #what about warnings?
  
  class RuleBuilder
    attr_reader :rule_key
    def initialize(rule_key, all_rules={}, &block)
      @rule_key = rule_key
      @parts = []
      @all_rules = all_rules
      @local_rule_list = []
      
      instance_eval(&block) if block
    end
    
    def <<(part)
      @parts << part
    end
    
    def declare(failure_message=nil, &block)
      self << Declaration.new(failure_message, &block)
    end

    def remember(&block)
      self << Remembering.new(&block)
    end    

    def with_rule(rule_key, &block)
      self << RuleDeclaration.new(rule_key, @all_rules, &block)
    end

    def rule(rule_key, &block)
      rule = self.class.new(rule_key, @all_rules, &block).build
      add_rule(rule_key, rule)
    end

    def add_rule(rule_key, rule)
      @all_rules[rule_key] = rule
      @local_rule_list << rule
      self
    end

    def build
      @parts.empty? && !@local_rule_list.empty? ? 
        @local_rule_list.first : 
        Rule.new(@rule_key, @parts)
    end
  end
  
  class Rule
    include ValueEquality
    
    def initialize(rule_key, parts=[])
      @rule_key = rule_key
      @parts = parts
    end

    def apply_to(object, context={})
      result = ResultOfRuleApplication.new
      
      check_type(object, result) if @rule_key.is_a?(Class)
      
      @parts.each do |part|
        if result.satisfied?
          result.merge!(part.apply_to(object, context))
        else
          begin
            result.merge!(part.apply_to(object, context))
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
  
  class AbstractDeclaration
    def _handle_result(result, actual_object)
      if result.is_a?(ResultOfRuleApplication)
        result
      elsif result
        ResultOfRuleApplication.new([], {})
      else
        ResultOfRuleApplication.new([Problem.new(self, actual_object)], {})
      end
    end
  end
  
  class Declaration < AbstractDeclaration
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
    
    
    #not elegant.  RF.
    
    def apply_to(actual_object, context={})
      call = DeclarationCall.new(self, actual_object)
      
      result = 
        if @block.arity<=0
          actual_object.instance_eval(&@block)
        elsif @block.arity==1
          result_from_block = actual_object.instance_exec(call, &@block)
          handle_call_and_result(call, result_from_block)
        elsif @block.arity==2
          result_from_block = actual_object.instance_exec(call, context, &@block)
          handle_call_and_result(call, result_from_block)
        else
          raise "invalid arity" #use a grammar for this?
        end
      
      _handle_result(result, actual_object)
    end
    
    private
    def handle_call_and_result(call, result_from_block)
      if call.failed?
        call.result
      else
        result_from_block  
      end
    end
  end

  
  class DeclarationCall
    attr_reader :result
    
    def initialize(declaration, actual_object)
      @declaration = declaration
      @actual_object = actual_object
      @result = ResultOfRuleApplication.new([], {})
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

  
  class RuleDeclaration < AbstractDeclaration
    attr_reader :rule_key
    
    def initialize(rule_key, all_rules, &block)
      @rule_key = rule_key
      @all_rules = all_rules
      @block = block
    end
    
    def apply_to(actual_object, context={})
      if @block.arity==1
        _handle_result(actual_object.instance_exec(@all_rules[@rule_key], &@block), actual_object)
      elsif @block.arity==2
        _handle_result(actual_object.instance_exec(@all_rules[@rule_key], context, &@block), actual_object)
      else
        raise "invlid arity"
      end
    end
    
    def ==(other)
      @rule_key == other.rule_key
    end
  end

  class Remembering
    def initialize(&block)
      @block = block
    end
    
    def apply_to(actual_object, context={})
      memory = {}
      
      if @block.arity == 1
        actual_object.instance_exec(memory, &@block)
      elsif @block.arity == 2
        actual_object.instance_exec(memory, context, &@block)
      else
        raise "invalid arity"
      end
      ResultOfRuleApplication.new(problems=[], memory)
    end        
  end


  class ResultOfRuleApplication
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

  class Problem
    attr_reader :declaration, :actual_object, :context, :details
  
    def initialize(declaration, actual_object, context={}, details={})
      @declaration = declaration
      @actual_object = actual_object
      @context = context
      @details = details
    end
    
    def message
      context_str = %{
        actual_object = @actual_object
        #{@context.keys.collect{|k|"#{k} = @context[:#{k}]"}.join("\n")}
        
      }
    
      if @declaration.failure_message
        eval(context_str + '"' + @declaration.failure_message + '"')
      else
        inspect
      end
    end
    
    def ==(other)
      @declaration == other.declaration &&
      @actual_object == other.actual_object &&
      @context == context
    end
  end



end

require "pinker/print/print_rule"