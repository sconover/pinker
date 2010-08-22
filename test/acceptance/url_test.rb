require "./test/test_helper"

require "uri"

require "pinker"
include Pinker

regarding "a grammar for the structure of a url" do
  
  test "first part of path needs to be a version number" do
    assert{ grammar.apply_to(URI::parse("/v1/apples?a=1")).well_formed? }
    assert{ grammar_error("/foo").message == "The first element of the path must be a version number, in the form /vX.  ex: /v2" }
    assert{ grammar_error("/vZZ/foo").message == "The first element of the path must be a version number, in the form /vX.  ex: /v2" }
  end
  
  test "the second part of the path needs to be a valid resource type" do
    assert{ grammar.apply_to(URI::parse("/v1/apples?a=1")).well_formed? }
    assert{ grammar_error("/v1/zzzzz?a=1").message == "The second element of the path must be a resource.  Valid resources are apples, bananas, carrots." }
  end
  
  test "'a' is a required query param" do
    assert{ grammar.apply_to(URI::parse("/v1/apples?a=1")).well_formed? }
    assert{ grammar_error("/v1/apples").message == "'a' is a required query parameter" }
  end
  
  test "it can only have 'a', 'b', and 'c' query params." do
    assert{ grammar.apply_to(URI::parse("/v1/apples?a=1&b=2&c=3")).well_formed? }
    assert{ grammar_error("/v1/apples?x=4&a=1&y=5").message == 
              "x, y are not allowed as query parameters.  Valid parameters are: a, b, c." }
  end
  
  def grammar_error(url)
    catch_raise{grammar.apply_to(URI::parse(url)).well_formed!}
  end
  
  def grammar
    @grammar ||=
      Grammar.new(:uri_example) do
        rule(URI::Generic) do
          
          declare("The first element of the path must be a version number, in the form /vX.  ex: /v2"){
            path && path.split("/")[1] =~ /v[0-9]+/
          }
          
          declare do |call|
            allowed_resource_types = %w{apples bananas carrots}
            path && allowed_resource_types.include?(path.split("/")[2]) || 
              call.fail("The second element of the path must be a resource.  Valid resources are #{allowed_resource_types.join(', ')}.")
          end
          
          declare("'a' is a required query parameter"){query && query.include?("a=")}
          
          declare do |call|
            if query
              allowed = %w{a b c}
              actual = query.split("&").collect{|pair|pair.split("=").first}
              bad = actual - allowed
            
              query && bad==[] || call.fail("#{bad.join(", ")} are not allowed as query parameters.  Valid parameters are: #{allowed.join(", ")}.")
            end
          end
          
        end
        
      end
  end
  
end