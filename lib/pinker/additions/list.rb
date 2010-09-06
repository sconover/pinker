module Pinker
  module RuleBuilderAdditions
    module DeclareList
      def declare_list(failure_message=nil, &block)
        declare(failure_message) {
          list_results = self.instance_eval(&block)

          DeclareList::RULE.apply_to(list_results).satisfied!
        
          allowed = list_results[:allowed]
          actual = list_results[:actual]
        
          (actual - allowed) == []
        }
      end
      
      RULE =
        RuleBuilder.new(DeclareList) {
          declare("Bad declare_list.  You must return a hash containing the :allowed and :actual lists.") {
            self.key?(:actual) && self.key?(:allowed)
          }
      
          declare("Bad declare_list.  :allowed was nil.  The expression of nothing should be an empty array.") {
            !self[:allowed].nil?
          }

          declare("Bad declare_list.  :actual was nil.  The expression of nothing should be an empty array.") {
            !self[:actual].nil?
          }
        }.build

    end
  end
end