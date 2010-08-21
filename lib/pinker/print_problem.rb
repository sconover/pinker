require "pinker/print_support"
require "pinker/print_condition"

module Pinker
  class Problems
    include ArrayPrintSupport
    
    def inspect(indent="")
      "Problems" + super.lstrip
    end
    
    def to_s
      "Problems" + super
    end
  end

  class Problem
    def inspect(indent="")
      indent + "'" + @condition.failure_message + "'" + "\n" + 
      indent + "  ==> " + @actual_object.inspect
    end    
    
    def to_s
      "'" + @condition.failure_message + "'" + ":" + @actual_object.inspect
    end
  end
end