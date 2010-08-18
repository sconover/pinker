require "pinker/print_rule"

module Pinker

  class Grammar
    def inspect(indent="")
      str = @rules.inspect(indent, "Grammar(#{@name_or_class.inspect})")
      str << "\n" if indent.empty?
      str
    end
    
    def to_s
      "Grammar(#{@name_or_class.inspect})#{@rules.to_s}"
    end
  end
  
  class Rules
    include ArrayPrintSupport
  end

  class ResultOfGrammarApplication
    def inspect(indent="")
      if well_formed?
        indent + "Result:Well-Formed"
      else
        indent + "Result:Not-Well-Formed:\n" + indent + "  " + @problems.inspect(indent + "  ")
      end
    end

    def to_s
      if well_formed?
        "Result:Well-Formed"
      else
        "Result:Not-Well-Formed:#{@problems.to_s}"
      end
    end
  end  
end