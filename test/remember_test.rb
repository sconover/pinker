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
      Rule.new(Request) do
        declare("Path must have at least three sections"){@path_info.split("/").length>=3}
        
        remember do |memory|
          memory[:resource_type] = @path_info.split("/")[2]
        end
      end
      
    assert{ rule.apply_to(Request.new("/v1/widgets/foo")).memory == 
      {:resource_type => "widgets"} 
    }
  end
  
  test "cache useful things across calls using context" do
    rule =
      Rule.new(Request) do
        declare("Path must have at least three sections") do |call, context|
          (context[:path_parts]=@path_info.split("/")).length>=3
        end
        
        remember do |memory, context|
          memory[:resource_type] = context[:path_parts][2]
        end
      end
      
    assert{ rule.apply_to(Request.new("/v1/widgets/foo")).memory == 
      {:resource_type => "widgets"} 
    }
  end
  
  
  test "if a remember fails and nothing else has, bubble up the error" do
  end
  
  test "if something else has already failed, swallow the exception.  this is a 'best effort'/completeness failure strategy." do
  end
end
