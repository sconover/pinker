require "pinker/rule"

module Pinker
  class RuleBuilder
    def initialize(rule_key)
      @rule_key = rule_key
      @parts = parts
      @rules = {}
    end
    
    def declare(failure_message=nil, &block)
      @parts << Declaration.new(failure_message, &block)
    end

    def remember(&block)
      @parts << Remembering.new(&block)
    end    

    def with_rule(rule_key, &block)
      rules = @rules
      @parts << 
        RuleDeclaration2.new(rule_key) do 
          self.instance_exec(rules[rule_key], &block)
        end
    end

    def rule(rule_key, &block)
      #???????
      rule = self.class.new(rule_key).instance_eval(&block).create_rule
      @rules[rule_key] = rule
      # rule = Rule2.new(rule_key, :other_rules => @rules, &block)
      # @rules[rule_key] = rule
      # rule
    end

    def create_rule
      Rule2.new(@rule_key, @parts)
    end
  end
  
  class Rule2
    def initialize(id, parts=[])
      @id = id
      @parts = parts
    end

    def apply_to(object)
      result = ResultOfRuleApplication2.new
      problems = []
      @parts.each do |part|
        result.merge!(part.apply_to(object))
      end
      result
    end
  end

  class RuleDeclaration2 < AbstractDeclaration
    attr_reader :rule_key
    
    def initialize(rule_key, &block)
      @rule_key = rule_key
      @block = block
    end
    
    def ==(other)
      @rule_key == other.rule_key
    end
  end

  class ResultOfRuleApplication2
    include ValueEquality
    
    attr_reader :problems, :memory
    
    def initialize(problems=[], memory={})
      @problems = problems
      @memory = memory
    end
    
    def satisfied?
      @problems.empty?
    end
    
    def merge!(other)
      @problems += other.problems
      @memory.merge!(other.memory)
      
      self
    end
  end
end