require "pinker/condition"

module Pinker
  class Problems < Array
    def initialize(&block)
      compose(&block) if block
    end    
  
    def compose(&block)
      problems = self
      Module.new do
        extend ProblemContext
        @conditions = []
        @problems = problems
        instance_eval(&block)
      end
    end
  end

  module ProblemContext
    include ConditionContext
  
    def problem(condition, actual_object, options={})
      problem = Problem.new(condition, actual_object, options)
      @problems << problem
      problem
    end
  end

  class Problem
    include ValueEquality
  
    def initialize(condition, actual_object, options={})
      @condition = condition
      @actual_object = actual_object
      @options = options
    end
    
    def message
      if @options[:custom_message_template]
        actual_object = @actual_object
        path = @options[:path]
        eval( '"' + @options[:custom_message_template] + '"' )
      else
        inspect
      end
    end
  end
end

require "pinker/print_problem"