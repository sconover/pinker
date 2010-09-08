module Pinker
  module RuleBuilderAddons
    module TypeIs
      def type_is(failure_message=nil, &block)
        declare(failure_message) { 
          type_result = self.instance_eval(&block)
          type, value = 
            if type_result.is_a?(Hash) && type_result.key?(:type) && type_result.key?(:value)
              [type_result[:type], type_result[:value]]
            else
              [type_result, self]
            end
          
          begin
            converted_value = eval("#{type.name}(value)")
          
            converted_value == value || converted_value.to_s == value.to_s
          rescue ArgumentError => e
            false
          end
        }
        
        change_self_to{
          type_result = self.instance_eval(&block)
          
          if type_result.is_a?(Hash) && type_result.key?(:type) && type_result.key?(:value)
            self
          else
            eval("#{type_result.name}(self)")
          end
        }
        
      end
      
    end
  end
end