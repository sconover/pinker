module Pinker

  class Grammar
    def to_s(indent="")
      str = @rules.to_s(indent, "Grammar(#{@name_or_class.inspect})")
      str << "\n" if indent.empty?
      str
    end
    
    def inspect
      "Grammar(#{@name_or_class.inspect})#{@rules.inspect}"
    end
  end
  
  class Rules
    include ArrayPrintSupport
  end

  
end