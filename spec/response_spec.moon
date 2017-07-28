cereal = require "cereal"

tbsp =
	response: require "tbsp.response"

describe "tbsp.response", ->
	describe "_make_filetype_for", ->
		it "can insert header filetype into headers", ->
			headers =
				["potato-header-1"]: "test"
				["content-type"]: "text/plain"
			assert.same headers, tbsp.response._make_filetype_for {
				["potato-header-1"]: "test"
			}, "text/plain"

	describe "html_response", ->
		it "can produce a correct response", ->
			body = tostring {}
			test_response = {
				body
				200
				{["content-type"]: "text/html"}
			}
			assert.same test_response, {tbsp.response.html_response(body, 200)}
	
	describe "json_response", ->
		it "can produce a correct response", ->
			test_response = {cereal.json.encode({a: 1}), 200, {
				["content-type"]: "application/json"}}
			assert.same test_response, {tbsp.response.json_response {a: 1},
				200}
	
	describe "yaml_response", ->
		it "can produce a correct response", ->
			test_response = {cereal.yaml.encode({{a: 1}}), 200, {
				["content-type"]: "text/x-yaml"}}
			assert.same test_response, {tbsp.response.yaml_response {{a: 1}},
				200}

	describe "toml_response", ->
		it "can produce a correct response", ->
			test_response = {cereal.toml.encode({a: 1}), 200, {
				["content-type"]: "text/x-toml"}}
			assert.same test_response, {tbsp.response.toml_response {a: 1},
				200}
