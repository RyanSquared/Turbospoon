import Request from require "tbsp.data"

http =
	headers: require "http.headers"

tbsp = require "tbsp"

class MockStream
	new: (session)=>
		@headers = http.headers.new()
		@populate session

	populate: (session)=>
		-- give some completely valid headers
		@headers\upsert ":path", "/test.html"
		@headers\upsert ":method", "GET"
		@headers\upsert "content-type", "text/html"
		@headers\upsert "cookie", "random_key=value"
		@headers\append "cookie", "key1=val1; key2=val2"
		@headers\append "cookie", "session=#{session}"

	get_headers: =>
		return @headers

describe "tbsp.data.request", ->
	it "can replicate a container", ->
		app = tbsp.App logger_enabled: false
		session = app.jwt\encode a: "b"
		stream = MockStream session
		headers = http.headers.new!
		headers\upsert ":path", "/test.html"
		headers\upsert ":method", "GET"
		headers\upsert "content-type", "text/html"
		headers\upsert "cookie", "random_key=value"
		headers\append "cookie", "key1=val1; key2=val2"
		headers\append "cookie", "session=#{session}"
		test_response =
			:app
			:stream
			:headers
			cookies:
				random_key: "value"
				key1: "val1"
				key2: "val2"
				:session
			method: "GET"
			session: a: "b"

		assert.same test_response, Request stream, app
