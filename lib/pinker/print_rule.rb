module Pinker
  module PrintSupport
    def to_s(indent="")
      indent + inspect
    end
  end
  
  module ArrayPrintSupport
    def to_s(indent="", prefix="")
      str = indent + prefix + "[\n"
      
      each_with_index do |item, i|
        str << item.to_s(indent + "  ")
        str << "," unless i==length-1
        str << "\n"
      end
      
      str << indent + "]"
      str
    end
    
    def inspect
      "[" + collect{|item|item.inspect}.join(",") + "]"
    end  
  end
  
  
  class Rule
    def to_s(indent="")
      str = @expressions.to_s(indent, "Rule(#{@name_or_class.inspect})")
      str << "\n" if indent.empty?
      str
    end
    
    def inspect
      "Rule(#{@name_or_class.inspect})#{@expressions.inspect}"
    end
  end
  
  class Expressions
    include ArrayPrintSupport
  end
    
  class Expression
    def to_s(indent="")
      @finder.to_s(indent) + "->" + @constraint.to_s(indent).lstrip
    end
    
    def inspect
      @finder.inspect + "->" + @constraint.inspect
    end
  end

  class RuleReference
    include PrintSupport
    
    def inspect
      "rule(#{@rule_key.inspect})"
    end
  end
  
  class RuleHolder
    def to_s(indent="")
      @rule.to_s(indent)
    end
    
    def inspect
      @rule.inspect
    end
  end
  
  class TemplatedPredicateHolder
    include PrintSupport
    
    def inspect
      @templated_predicate.inspect
    end
  end
    
  class InstanceVariableFinder
    include PrintSupport
    
    def inspect
      @instance_variable_symbol.to_s
    end
  end
  
  class MethodFinder
    include PrintSupport
    
    def inspect
      @method_symbol.inspect
    end
  end
  
end