require "pinker/print_support"

module Pinker
  class Conditions
    include ArrayPrintSupport
  end
    
  class Condition
    def inspect(indent="")
      @finder.inspect(indent) + "->" + @constraint.inspect(indent).lstrip
    end
    
    def to_s
      @finder.to_s + "->" + @constraint.to_s
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
end