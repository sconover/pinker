module Pinker
  module RuleBuilderAddons
    module InRange
      def in_range(failure_message_proc=nil, &block)
        declare(failure_message_proc) { |call|
          range_results = self.instance_eval(&block)
          range_results = {:allowed => range_results} if range_results.is_a?(Range)
          range_results[:actual] ||= self
          
          InRange::RANGE_RESULTS_RULE.apply_to(range_results).satisfied!
        
          allowed_range = range_results[:allowed]
          actual = range_results[:actual]
          
          if allowed_range.include?(actual)
            true
          else
            
            failure_message_proc ||= 
              proc do |actual, allowed|
                "'#{actual}' is out of range.  " +
                "Value must be between #{allowed_range.begin} and #{allowed_range.end}."
              end
              
            call.fail(failure_message_proc.call(actual, allowed_range),
                      {:actual => actual, :allowed => allowed_range})
          end
        }
      end
      
      
      #how do we turn this off?
        #(this is intended for the designer, after all)
      #should it be a constant?
      
      RANGE_RESULTS_RULE =
        RuleBuilder.new(:range_results) {
          declare("Bad in_range.  You must return a hash containing the :allowed range and :actual value.") {
            self.key?(:actual) && self.key?(:allowed)
          }
        }.build

    end
  end
end