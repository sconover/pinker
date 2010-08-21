module Pinker
  class Problems < Array
  end

  module ProblemContext
    def problem(declaration, actual_object, options={})
      problem = Problem.new(declaration, actual_object, options)
      @problems << problem
      problem
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

require "pinker/print_problem"