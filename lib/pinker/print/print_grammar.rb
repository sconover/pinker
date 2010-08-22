require "pinker/print/print_rule"

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
  
  class RuleDeclaration < AbstractDeclaration
    include PrintSupport
    
    def to_s
      "declare:Rule(#{@rule_key.inspect})"
    end
  end

  class ResultOfGrammarApplication
    def inspect(indent="")
      if well_formed?
        indent + "Result:Well-Formed"
      else
        problems.extend(ArrayPrintSupport)
        indent + "Result:Not-Well-Formed:" + @problems.inspect(indent).lstrip
      end
    end

    def to_s
      if well_formed?
        "Result:Well-Formed"
      else
        "Result:Not-Well-Formed:[#{@problems.collect{|p|p.to_s}.join(",")}]"
      end
    end
  end  
end