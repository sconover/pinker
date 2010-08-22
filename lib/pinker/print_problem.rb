require "pinker/print_support"

module Pinker
  class Problem
    def inspect(indent="")
      indent + "'" + @declaration.failure_message + "'" + "\n" + 
      indent + "  ==> " + @actual_object.inspect
    end    
    
    def to_s
      "'" + @declaration.failure_message + "'" + ":" + @actual_object.inspect
    end
  end
end