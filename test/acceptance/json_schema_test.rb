require "./test/test_helper"

require "jsonschema"
require "json"

require "pinker"
include Pinker

regarding "replicate json schema example in pinker" do
  
  it "fails if the product is not an associative array" do
    json = []
    #the ruby json schema library doesn't actually fail here
    assert{ catch_raise{JSON::Schema.validate(json, json_schema_rfc_example)} ==
      nil }
      
    assert{ catch_raise{grammar_equivalent.apply_to(json).well_formed!}.message ==
              "Product must be an associative array" }
  end
  
  
  def grammar_equivalent
    @grammar ||=
      Grammar.new(:json_schema_rfc_example) do
        rule(:product) do
          declare("Product must be an associative array"){is_a?(Hash)}
        end
      end
  end
  
  #example from json schema RFC: 
  #http://tools.ietf.org/html/draft-zyp-json-schema-02#section-3
  
  def json_schema_rfc_example
    #chopped down to what's supported in the ruby json schema library
    @schema ||=
      JSON.parse(%{{
       "properties":{
         "id":{
           "type":"number",
           "description":"Product identifier"
         },
         "name":{
           "description":"Name of the product",
           "type":"string"
         },
         "price":{
           "type": "number",
           "minimum":0
         },
         "tags":{
           "optional":true,
           "type":"array",
           "items":{
              "type":"string"
           }
         }
       }
     }})
  end
end