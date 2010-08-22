require "./test/test_helper"

require "uri"

require "pinker"
include Pinker

regarding "a grammar for the structure of a url" do
  
  test "'a' is a required query param" do
    assert{ grammar.apply_to(URI::parse("/foo?a=1")).well_formed? }
    assert{ grammar_error("/foo").message == "'a' is a required query parameter" }
  end
  
  test "it can only have 'a', 'b', and 'c' query params." do
    assert{ grammar.apply_to(URI::parse("/foo?a=1&b=2&c=3")).well_formed? }
    assert{ grammar_error("/foo?x=4&a=1&y=5").message == 
              "x, y are not allowed as query parameters.  Valid parameters are: a, b, c." }
  end
  
  def grammar_error(url)
    catch_raise{grammar.apply_to(URI::parse(url)).well_formed!}
  end
  
  def grammar
    @grammar ||=
      Grammar.new(:uri_example) do
        rule(URI::Generic) do
          
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