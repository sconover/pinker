module Pinker
  module PrintSupport
    overridable do
      def inspect(indent="")
        indent + to_s
      end
    end
  end
  
  module ArrayPrintSupport
    overridable do
      def inspect(indent="", prefix="")
        str = indent + prefix + "[\n"
      
        each_with_index do |item, i|
          str << item.inspect(indent + "  ")
          str << "," unless i==length-1
          str << "\n"
        end
      
        str << indent + "]"
        str
      end
    end
    
    overridable do
      def to_s
        "[" + collect{|item|item.to_s}.join(",") + "]"
      end  
    end
  end
  
  
  class Rule
    def inspect(indent="")
      str = @expressions.inspect(indent, "Rule(#{@name_or_class.inspect})")
      str << "\n" if indent.empty?
      str
    end
    
    def to_s
      "Rule(#{@name_or_class.inspect})#{@expressions.to_s}"
    end
  end
  
  class Expressions
    include ArrayPrintSupport
  end
    
  class Expression
    def inspect(indent="")
      @finder.inspect(indent) + "->" + @constraint.inspect(indent).lstrip
    end
    
    def to_s
      @finder.to_s + "->" + @constraint.to_s
    end
  end

  class RuleReference
    include PrintSupport
    
    def to_s
      "rule(#{@rule_key.inspect})"
    end
  end
  
  class RuleHolder
    def inspect(indent="")
      @rule.inspect(indent)
    end
    
    def to_s
      @rule.to_s
    end
  end
  
  class TemplatedPredicateHolder
    def inspect(indent="")
      @templated_predicate.inspect(indent)
    end
    
    def to_s
      @templated_predicate.to_s
    end
  end
    
  class InstanceVariableFinder
    include PrintSupport
    
    def to_s
      @instance_variable_symbol.to_s
    end
  end
  
  class MethodFinder
    include PrintSupport
    
    def to_s
      @method_symbol.inspect
    end
  end
  
  class SelfFinder
    include PrintSupport
    
    def to_s
      "_object_"
    end
  end
  
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
      @expression.inspect(indent) + "\n" + 
      indent + "  ==> " + @actual_object.inspect
    end    
    
    def to_s
      @expression.to_s + ":" + @actual_object.inspect
    end
  end
end