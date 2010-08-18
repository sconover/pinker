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
      @condition.inspect(indent) + "\n" + 
      indent + "  ==> " + @actual_object.inspect
    end    
    
    def to_s
      @condition.to_s + ":" + @actual_object.inspect
    end
  end
end