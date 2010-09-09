require "pinker/print/print_support"

module Pinker
  
  class Rule
    def inspect(indent="")
      str = ArrayPrintSupport.inspect_array(@parts, indent, "Rule(#{@rule_key.inspect})")
      str << "\n" if indent.empty?
      str
    end
    
    def to_s
      "Rule(#{@rule_key.inspect})#{ArrayPrintSupport.to_s_array(@parts)}"
    end
  end
  
  class Declaration
    include PrintSupport
    
    def to_s
      msg = @failure_message ? "'" + @failure_message + "'" : "<no message>"
      "declare:#{msg}"
    end
  end
  
  class RuleDeclaration
    include PrintSupport
    
    def to_s
      "with_rule:#{rule_key.to_s}"
    end
  end
  
  class Remembering
    include PrintSupport
    
    def to_s
      "remember"
    end
  end
  
  class Problem
    def inspect(indent="")
      indent + "'" + (@declaration.respond_to?(:failure_message) && @declaration.failure_message || "") + "'" + "\n" + 
      indent + "  ==> " + @actual_object.inspect
    end    
    
    def to_s
      "'" + @declaration.failure_message + "'" + ":" + @actual_object.inspect
    end
  end
  
end