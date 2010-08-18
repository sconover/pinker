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
  
    def problem(condition, actual_object, custom_failure_message=nil)
      problem = Problem.new(condition, actual_object, custom_failure_message)
      @problems << problem
      problem
    end
  end

  class Problem
    include ValueEquality
  
    def initialize(condition, actual_object, custom_message_template=nil)
      @condition = condition
      @actual_object = actual_object
      @custom_message_template = custom_message_template
    end
    
    def fill_in_predicate(predicate)
      Condition.new(finder, constraint, custom_failure_message_template=nil)
      Problems.new{problem(condition(finder, templated_predicate), object)}
      @condition = condition
    end
  end
end