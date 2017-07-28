Request = require "tbsp.data.request"

http =
	headers: require "http.headers"

class MockStream
	new: =>
		@headers = http.headers.new()
		@populate!

	populate: =>
		-- give some completely valid headers
		@headers\upsert ":path", "/test.html"
		@headers\upsert ":status", "200"
		@headers\upsert "content-type", "text/html"

	get_headers: =>
		return @headers

describe "tbsp.data.request", ->
	it "can replicate a container", ->
		stream = MockStream!
		test_response =
			stream: MockStream!
			headers:
				[":path"]: "/test.html"
				[":status"]: "200"
				["content-type"]: "text/html"
			method: "200"

		assert.same test_response, Request stream
