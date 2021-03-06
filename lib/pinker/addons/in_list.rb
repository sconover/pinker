module Pinker
  module RuleBuilderAddons
    module InList
      def in_list(failure_message_proc=nil, &block)
        declare(failure_message_proc) { |call|
          list_results = self.instance_eval(&block)
          list_results = {:allowed => list_results} if list_results.is_a?(Array)
          list_results[:actual] ||= self
          
          InList::LIST_RESULTS_RULE.apply_to(list_results).satisfied!
        
          allowed = list_results[:allowed]
          actual = Array(list_results[:actual])
          
          not_allowed = (actual - allowed)
          
          if not_allowed.empty?
            true
          else
            failure_message_proc ||= 
              proc do |not_allowed, allowed|
                InList.list_to_str(not_allowed) +
                (not_allowed.length > 1 ? " are" : " is") +
                " not allowed.  Valid values are " +
                InList.list_to_str(allowed) + 
                "."
              end
              
            call.fail(failure_message_proc.call(not_allowed, allowed),
                      {:actual => actual, :allowed => allowed, :not_allowed => not_allowed})
          end
        }
      end
      
      
      def self.list_to_str(list)
        str = ""
        list.each_with_index do |item, i|
          str << "'#{item}'"
          if i == list.length - 2
            str << " and "
          elsif i < list.length - 2
            str << ", "
          end
        end
        str
      end
      #how do we turn this off?
        #(this is intended for the designer, after all)
      #should it be a constant?
      
      LIST_RESULTS_RULE =
        RuleBuilder.new(:list_results) {
          declare("Bad in_list.  You must return a hash containing the :allowed and :actual lists.") {
            self.key?(:actual) && self.key?(:allowed)
          }
      
          declare("Bad in_list.  :allowed was nil.  The expression of nothing should be an empty array.") {
            !self[:allowed].nil?
          }

          declare("Bad in_list.  :actual was nil.  The expression of nothing should be an empty array.") {
            !self[:actual].nil?
          }
        }.build

    end
  end
end