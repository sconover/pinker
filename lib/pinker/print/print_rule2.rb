require "pinker/print/print_support"

module Pinker
  
  class Rule2
    def inspect(indent="")
      str = ArrayPrintSupport.inspect_array(@parts, indent, "Rule(#{@rule_key.inspect})")
      str << "\n" if indent.empty?
      str
    end
    
    def to_s
      "Rule(#{@rule_key.inspect})#{ArrayPrintSupport.to_s_array(@parts)}"
    end
  end
  
  class Declaration2
    include PrintSupport
    
    def to_s
      msg = @failure_message ? "'" + @failure_message + "'" : "<no message>"
      "declare:#{msg}"
    end
  end
  
  class Problem
    def inspect(indent="")
      indent + "'" + (@declaration.failure_message || "") + "'" + "\n" + 
      indent + "  ==> " + @actual_object.inspect
    end    
    
    def to_s
      "'" + @declaration.failure_message + "'" + ":" + @actual_object.inspect
    end
  end
  
end