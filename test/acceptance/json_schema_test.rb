require "./test/test_helper"

require "jsonschema"
require "json"

require "pinker"
include Pinker

regarding "replicate json schema example in pinker" do
  
  it "fails if the product is not an associative array" do
    json = []

    #the ruby json schema library doesn't actually fail here
    assert{ json_schema_error(json) == nil }

    assert{ grammar_error(json).message == "Product must be an associative array" }
  end
  
  it "fails if the name is missing" do
    json = good_json
    json.delete("name")
    
    assert{ json_schema_error(json).message == "Required field 'name' is missing" }
    assert{ grammar_error(json).message == "Required field 'name' is missing" }
  end
  
  it "fails if the id is missing" do
    json = good_json
    json.delete("id")

    assert{ json_schema_error(json).message == "Required field 'id' is missing" }
    assert{ grammar_error(json).message == "Required field 'id' is missing" }
  end
  
  it "fails if the price is missing" do
    json = good_json
    json.delete("price")

    assert{ json_schema_error(json).message == "Required field 'price' is missing" }
    assert{ grammar_error(json).message == "Required field 'price' is missing" }
  end
  
  it "doesn't fails if tags are missing, because tags is an optional field" do
    json = good_json
    json.delete("tags")

    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }
  end
  
  it "no failure on superfluous fields" do
    json = good_json
    json["foo"] = 1
    json["bar"] = 2

    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }
  end
  
  def good_json
    {"id" => 101, "name" => "Jane", "price" => 19.99, "tags" => ["hot", "onsale"]}
  end
  
  def grammar_error(json)
    catch_raise{grammar_equivalent.apply_to(json).well_formed!}
  end
  
  def json_schema_error(json)
    catch_raise{JSON::Schema.validate(json, json_schema_rfc_example)}
  end
  
  def grammar_equivalent
    @grammar ||=
      Grammar.new(:json_schema_rfc_example) do
        rule(:product) do
          declare("Product must be an associative array"){is_a?(Hash)}
          %w{id name price}.each do |property_name|
            declare("Required field '#{property_name}' is missing"){key?(property_name)}
          end
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