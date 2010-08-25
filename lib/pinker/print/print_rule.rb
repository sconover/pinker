require "pinker/print/print_support"

module Pinker
  
  class Rule
    def inspect(indent="")
      str = @declarations.inspect(indent, "Rule(#{@name_or_class.inspect})")
      str << "\n" if indent.empty?
      str
    end
    
    def to_s
      "Rule(#{@name_or_class.inspect})#{@declarations.to_s}"
    end
  end
  
  class Declarations
    include ArrayPrintSupport
  end

  class Declaration
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