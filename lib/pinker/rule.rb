require "pinker/core"

module Pinker
  
  class Rule
    attr_reader :name_or_class, :declarations
    def initialize(name_or_class, options={}, &block)
      @name_or_class = name_or_class
      @other_rules = options[:other_rules]
      
      @declarations = Declarations.new
      
      add(&block) if block
    end
    
    def add(&block)
      other_rules = @other_rules
      declarations = @declarations
      Module.new do
        extend DeclarationContext
        @other_rules = other_rules
        @declarations = declarations
        instance_eval(&block)
      end
    end
    
    def apply_to(object)
      problems = []
      unless object.nil? || !name_or_class.is_a?(Class) || object.is_a?(name_or_class)
        problems.push(Problem.new(Declaration.new("Must be type #{name_or_class.name}"), object, context={}))
      end
      
      already_failed = false
      context = {}
      memory = {}
      @declarations.each do |declaration|
        if already_failed
          begin
            problems.push(*declaration.problems_with(object, context, memory))
          rescue StandardError => e
          end
        else
          current_problems = declaration.problems_with(object, context, memory)
          problems.push(*current_problems)
          already_failed = !current_problems.empty?
        end
      end
      
      ResultOfRuleApplication.new(problems, memory)
    end
    
    def ==(other)
      @name_or_class == other.name_or_class &&
      @declarations == other.declarations
    end
  end
  
  class ResultOfRuleApplication
    include ValueEquality
    
    attr_reader :problems, :memory
    
    def initialize(problems, memory)
      @problems = problems
      @memory = memory
    end
    
    def satisfied?
      @problems.empty?
    end
  end

  class Declarations < Array
    def problems_with(object, context, memory)
      collect do |declaration|
        declaration.problems_with(object, context, memory)
      end.flatten
    end
  end

  module DeclarationContext
    def declare(failure_message=nil, &block)
      declaration = Declaration.new(failure_message, &block)
      @declarations << declaration
      declaration
    end
    
    def remember(&block)
      remembering = Remembering.new(&block)
      @declarations << remembering
      remembering
    end
  end
  
  class AbstractDeclaration
    def call(actual_object, context, block=@block)
      if block.arity<=0
        call(actual_object, context,
          proc do |call, context|
            call.result(self.instance_eval(&block))
          end
        )
      else
        call = DeclarationCall.new(self, actual_object)
        if block.arity==1
          actual_object.instance_exec(call, &block)
        elsif block.arity==2
          actual_object.instance_exec(call, context, &block)
        else
          raise "invalid block arity"
        end
        call
      end
    end
    
    def problems_with(actual_object, context, memory)
      call(actual_object, context).problems
    end 
  end
  
  class DeclarationCall
    attr_reader :problems
    
    def initialize(declaration, actual_object)
      @declaration = declaration
      @actual_object = actual_object
      @problems = []
    end
    
    def fail(failure_message=nil)
      declaration = 
        failure_message ? 
          @declaration.with_new_failure_message(failure_message) :
          @declaration
          
      @problems.push(Problem.new(declaration, @actual_object, {}))
    end
    
    def result(block_output)
      if block_output.is_a?(Array)
        @problems.push(*block_output)
      elsif block_output.is_a?(ResultOfRuleApplication)
        @problems.push(*block_output.problems)
      elsif !block_output
        fail
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
  end
  
  class Remembering    
    def initialize(&block)
      @block = block
    end
    
    def problems_with(actual_object, context, memory)
      if @block.arity == 1
        actual_object.instance_exec(memory, &@block)
      elsif @block.arity == 2
        actual_object.instance_exec(memory, context, &@block)
      else 
        raise "invalid block arity"
      end
    end 
  end
  
  class Problem
    attr_reader :declaration, :actual_object, :context
  
    def initialize(declaration, actual_object, context={})
      @declaration = declaration
      @actual_object = actual_object
      @context = context
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