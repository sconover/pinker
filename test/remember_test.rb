require "./test/test_helper"

require "pinker/rule"
include Pinker

regarding "remember helps gather up things that get returned if the rule is valid." do

  class Request
    def initialize(path_info, query_string=nil)
      @path_info = path_info
      @query_string = query_string
    end
  end

  test "stick things in memory, return them with a successful result" do
    rule =
      RuleBuilder.new(Request) {
        declare("Path must have at least three sections"){@path_info.split("/").length>=3}
        
        remember { |memory|
          memory[:resource_type] = @path_info.split("/")[2]
        }
      }.build
      
    assert{ rule.apply_to(Request.new("/v1/widgets/foo")).memory == 
      {:resource_type => "widgets"} 
    }
  end
  
  test "disregard the results of remembers" do
    rule =
      RuleBuilder.new(Request) {
        remember { |memory, context|
          memory[:x] = "y"
          nil #caused explosions at one time
        }
      }.build
      
    assert{ rule.apply_to(Request.new("/v1/widgets/foo")).memory == 
      {:x => "y"} 
    }
  end
  
  test "cache useful things across calls using context" do
    the_rule =
      RuleBuilder.new(Request) {
        declare("Path must have at least three sections") { |call, context|
          (context[:path_parts]=@path_info.split("/")).length>=3
        }
        
        with_rule(:text_is_widgets){|rule, context|rule.apply_to(context[:path_parts][2])}
        
        rule(:text_is_widgets) {
          declare("Must be widgets"){self=="widgets"}
        }
        
        remember { |memory, context|
          memory[:resource_type] = context[:path_parts][2]
        }
      }.build
      
    assert{ the_rule.apply_to(Request.new("/v1/widgets/foo")).satisfied? }
    assert{ the_rule.apply_to(Request.new("/v1/widgets/foo")).memory == 
      {:resource_type => "widgets"} 
    }
  end
  
  
  test "if a remember fails and nothing else has, bubble up the error" do
    rule =
      RuleBuilder.new(Request) {
        declare { |call, context|
          (context[:path_parts]=@path_info.split("/")).length>=3 || call.fail("Path must have at least three sections")
        }
        
        remember { |memory, context|
          raise StandardError.new("blam!")
        }
      }.build    
      
    assert{ rescuing{ rule.apply_to(Request.new("/v1/widgets/foo")) }.message == 
      "blam!"
    }
  end
  
  test "if something else has already failed, swallow the exception.  this is a 'best effort'/completeness failure strategy." do
    rule =
      RuleBuilder.new(Request) {
        declare { |call, context|
          @path_info.split("/").length>=99 || call.fail("Path must have at least 99 sections")
        }
        
        remember { |memory, context|
          raise StandardError.new("blam!")
        }
      }.build    
    
    assert{ rescuing{ rule.apply_to(Request.new("/v1/widgets/foo")) }.nil? }
    assert{ rule.apply_to(Request.new("/v1/widgets/foo")).problems.first.message == "Path must have at least 99 sections" }
  end
  
  test "merge together memory hashes from rules" do
    grammar = 
      RuleBuilder.new(:foo) {
        rule(:a) {
          remember{|memory|memory[:a] = 1}
          with_rule(:b){|rule|rule.apply_to("y")}
        }

        rule(:b) {
          remember{|memory|memory[:b] = 2}
        }
      }.build
      
    assert{ grammar.apply_to("x").memory == {:a => 1, :b => 2} }
  end    

end
