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

  
end