cereal = require "cereal"

tbsp =
	response: require "tbsp.response"

http =
	headers: require "http.headers"

describe "tbsp.response", ->
	describe "_make_filetype_for", ->
		it "can insert header filetype into headers", ->
			test_headers = http.headers.new!
			test_headers\upsert "potato-header-1", "test"
			test_headers\upsert "content-type", "text/plain"

			case_headers = http.headers.new!
			case_headers\upsert "potato-header-1", "test"

			assert.same test_headers,
				tbsp.response._make_filetype_for(case_headers, "text/plain")

	describe "html_response", ->
		it "can produce a correct response", ->
			body = tostring {}
			test_headers = http.headers.new!
			test_headers\upsert "content-type", "text/html"
			test_response = {
				body
				200
				test_headers
			}
			assert.same test_response, {tbsp.response.html_response(body, 200)}
	
	describe "json_response", ->
		it "can produce a correct response", ->
			test_headers = http.headers.new!
			test_headers\upsert "content-type", "application/json"
			test_response = {
				cereal.json.encode({a: 1})
				200
				test_headers
			}
			assert.same test_response, {tbsp.response.json_response {a: 1},
				200}
	
	describe "yaml_response", ->
		it "can produce a correct response", ->
			test_headers = http.headers.new!
			test_headers\upsert "content-type", "text/x-yaml"
			test_response = {
				cereal.yaml.encode({{a: 1}})
				200
				test_headers
			}
			assert.same test_response, {tbsp.response.yaml_response {{a: 1}},
				200}

	describe "toml_response", ->
		it "can produce a correct response", ->
			test_headers = http.headers.new!
			test_headers\upsert "content-type", "text/x-toml"
			test_response = {
				cereal.toml.encode({a: 1})
				200
				test_headers
			}
			assert.same test_response, {tbsp.response.toml_response {a: 1},
				200}
