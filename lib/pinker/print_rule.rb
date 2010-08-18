require "pinker/print_support"
require "pinker/print_condition"
require "pinker/print_problem"

module Pinker
  
  class Rule
    def inspect(indent="")
      str = @conditions.inspect(indent, "Rule(#{@name_or_class.inspect})")
      str << "\n" if indent.empty?
      str
    end
    
    def to_s
      "Rule(#{@name_or_class.inspect})#{@conditions.to_s}"
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

end