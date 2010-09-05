require "./test/test_helper"

require "jsonschema"
require "json"

require "pinker"
include Pinker

regarding "replicate json schema example in pinker WHAT'S THE DEAL?  DID JSONSCHEMA CHANGE?  The error messages are much more primitive now.  Figure this out." do
  
  test "fails if the product is not an associative array" do
    json = []

    #the ruby json schema library doesn't actually fail here
    assert{ json_schema_error(json) == nil }

    assert{ grammar_error(json).message == "Product must be an associative array" }
  end
  
  test "fails if the name is missing" do
    json = good_json
    json.delete("name")
    
    assert{ json_schema_error(json).message == "Required field 'name' is missing" }
    assert{ grammar_error(json).message == "Required field 'name' is missing" }
  end
  
  test "fails if the id is missing" do
    json = good_json
    json.delete("id")

    assert{ json_schema_error(json).message == "Required field 'id' is missing" }
    assert{ grammar_error(json).message == "Required field 'id' is missing" }
  end
  
  test "fails if the price is missing" do
    json = good_json
    json.delete("price")

    assert{ json_schema_error(json).message == "Required field 'price' is missing" }
    assert{ grammar_error(json).message == "Required field 'price' is missing" }
  end
  
  test "doesn't fails if tags are missing, because tags is an optional field" do
    json = good_json
    json.delete("tags")

    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }
  end
  
  test "no failure on presence of extra fields" do
    json = good_json
    json["foo"] = 1
    json["bar"] = 2

    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }
  end

  test "fails if id is not a number" do
    json = good_json
    
    json["id"] = 101
    
    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }

    json["id"] = "abc"

    assert{ json_schema_error(json).message == "Value abc for field 'id' is not of type number" }
    assert{ grammar_error(json).message == "Value abc for field 'id' is not of type number" }
  end

  test "fails if name is not a string" do
    json = good_json
    
    json["name"] = "Jane"
    
    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }

    json["name"] = 101

    assert{ json_schema_error(json).message == "Value 101 for field 'name' is not of type string" }
    assert{ grammar_error(json).message == "Value 101 for field 'name' is not of type string" }
  end

  test "fails if the name is nil, because nil is not a string" do
    json = good_json
    json["name"] = nil
    
    assert{ json_schema_error(json).message == "Value  for field 'name' is not of type string" }
    assert{ grammar_error(json).message == "Value  for field 'name' is not of type string" }
  end
  
  test "fails if price is not a number" do
    json = good_json
    
    json["price"] = 19.99
    
    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }

    json["price"] = "ZZZ"

    assert{ json_schema_error(json).message == "Value ZZZ for field 'price' is not of type number" }
    assert{ grammar_error(json).message == "Value ZZZ for field 'price' is not of type number" }
  end

  test "fails if tags is not an array" do
    json = good_json
    
    json["tags"] = ["hot", "onsale"]
    
    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }

    json["tags"] = 101

    assert{ json_schema_error(json).message == "Value 101 for field 'tags' is not of type array" }
    assert{ grammar_error(json).message == "Value 101 for field 'tags' is not of type array" }
  end
  
  xtest "fails if tags items are not all strings" do
    json = good_json
    
    json["tags"] = ["hot", "onsale"]
    
    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }

    json["tags"] = ["hot", 101]

    assert{ json_schema_error(json).message == 
              "Failed to validate field 'tags' list schema: Value 101 for field '_data' is not of type string" }
    assert{ grammar_error(json).message == 
              "Failed to validate field 'tags' list schema: Value 101 for field '_data' is not of type string" }
  end
  
  test "price must be at least zero" do
    json = good_json
    
    json["price"] = 19.99
    
    assert{ json_schema_error(json) == nil }
    assert{ grammar_error(json) == nil }

    json["price"] = -2.22

    assert{ json_schema_error(json).message == 
              "Value -2.22 for field 'price' is less than minimum value: 0" }
    assert{ grammar_error(json).message == 
              "Value -2.22 for field 'price' is less than minimum value: 0" }
  end


  
  def good_json
    {"id" => 101, "name" => "Jane", "price" => 19.99, "tags" => ["hot", "onsale"]}
  end
  
  def grammar_error(json)
    rescuing{grammar_equivalent.apply_to(json).satisfied!}
  end
  
  def json_schema_error(json)
    rescuing{JSON::Schema.validate(json, json_schema_rfc_example)}
  end
  
  def grammar_equivalent
    @grammar ||=
      RuleBuilder.new(:json_schema_rfc_example) {
        rule(:product) {
          
          declare("Product must be an associative array"){is_a?(Hash)}
          
          %w{id name price}.each do |property_name|
            declare("Required field '#{property_name}' is missing"){key?(property_name)}
          end
          
          [
            ["id", "number", Numeric, false], 
            ["name", "string", String, false],
            ["price", "number", Numeric, false],
            ["tags", "array", Array, true]
          ].
            each do |property_name, json_schema_primitive_type, is_a_class_check, nil_allowed|
              
            declare { |call|
              value = self[property_name]
              (value.is_a?(is_a_class_check) || nil_allowed && value.nil?) ||
                call.fail("Value #{value} for field '#{property_name}' is not of type #{json_schema_primitive_type}")
            }
            
          end
          
          declare('Value #{actual_object["price"]} for field \'price\' is less than minimum value: 0') {
            self["price"] >= 0.0
          }
          
          with_rule(:string_tags) { |rule|
            self["tags"] ? self["tags"].collect{|tag|rule.apply_to(tag).problems}.flatten : []
          }
        }
        
        rule(:string_tags) {
          declare('Failed to validate field \'tags\' list schema: Value #{actual_object} for field \'_data\' is not of type string') {
            self.is_a?(String)
          }
        }
      }.build
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