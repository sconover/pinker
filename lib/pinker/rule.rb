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
    
    def apply_to(object, path=[])
      problems = []
      unless object.nil? || object.is_a?(name_or_class)
        problems.push(Problem.new(Declaration.new("Must be type #{name_or_class.name}"), object))
      end
      
      path.push(self)
      problems.push(*@declarations.problems_with(object, path.dup, {:rule => @other_rules}))
      
      ResultOfRuleApplication.new(problems)
    end
    
    def ==(other)
      @name_or_class == other.name_or_class &&
      @declarations == other.declarations
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

  class Declarations < Array
    def problems_with(object, path, context)
      collect do |declaration|
        declaration.problems_with(object, path.dup, context)
      end.flatten
    end
    
    def evaluate_all(object)
      problems_with(object).empty?
    end
  end

  module DeclarationContext
    def declare(failure_message=nil, &block)
      declaration = Declaration.new(failure_message, &block)
      @declarations << declaration
      declaration
    end
  end
  
  class AbstractDeclaration
    def problems_with(object, path, context)
      path.push(self)

      result = object.instance_eval(&@block)
      
      if result.is_a?(Array)
        result
      elsif result.is_a?(ResultOfRuleApplication)
        result.problems
      elsif !result
        [Problem.new(self, object)]
      else
        []
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
    
  end
  
  class Problem
    attr_reader :declaration, :actual_object, :options
  
    def initialize(declaration, actual_object, options={})
      @declaration = declaration
      @actual_object = actual_object
      @options = options
    end
    
    def message
      inspect
    end
    
    def ==(other)
      @declaration == other.declaration &&
      @actual_object == other.actual_object &&
      @options[:custom_message_template] == other.options[:custom_message_template]
    end
  end


end

require "pinker/print/print_rule"