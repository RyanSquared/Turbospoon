--- Data classes module
-- @author RyanSquared <vandor2012@gmail.com>
-- @classmod tbsp.data.Request

http =
	cookies: require "http.cookies"
	headers: require "http.headers"

class Request
	--- Return a new Request container
	-- @tparam http.stream stream lua-http server -> client stream
	-- @tparam App tbsp_app Turbospoon app
	new: (stream, tbsp_app)=>
		assert stream
		assert tbsp_app
		@app = tbsp_app
		@stream = stream
		@headers = stream\get_headers!
		@method = @headers\get ":method"

		for header, value in @headers\each!
			if header == "cookie"
				cookies = http.cookies.parse_cookies(value)
				if not @cookies
					@cookies = {cookie[1], cookie[2] for cookie in *cookies}
				else
					for cookie in *cookies
						{key, value} = cookie
						@cookies[key] = value

		if @cookies and @cookies.session
			@session = @app.jwt\decode @cookies.session
		else
			@session = {}

	--- Create session cookies and set it as a header
	-- @tparam table cookie JSON data for baked cookie
	-- @tparam number age Age for cookie (default 28 days)
	make_session_cookie: (cookie, age = 60 * 60 * 24 * 28)=>
		-- no need to worry about optimizing ^ because most Lua interpreters
		-- implement folding of static values automatically
		@cookies.session =
			key: "session"
			value: @app.jwt\encode @cookies.session
			max_age: age
			http_only: true

	--- Send HTTP headers to the client
	-- @tparam number status HTTP status code
	-- @tparam http.headers headers Optional headers to send to client
	write_headers: (status, headers = http.headers.new!)=>
		assert status
		-- if headers are *not* of http.headers, they should be instead a
		-- key-value mapping of tables
		headers_mt = getmetatable headers
		if headers_mt != http.headers.mt
			new_headers = http.headers.new!
			for k, v in pairs headers
				new_headers\append k, v
			headers = new_headers
		if not headers\has "content-type" then
			headers\append "content-type", "text/plain"
		headers\upsert ":status", tostring status
		@stream\write_headers headers, @method == "HEAD"
	
	-- ::TODO:: write_chunk()

	--- Send text as the body of the message
	-- @tparam string text
	write_body: (text)=>
		return if @method == "HEAD"
		@stream\write_chunk tostring(text), true

	--- Send HTTP headers and body text at the same time
	-- @tparam string text
	-- @tparam number status HTTP status
	-- @tparam http.headers headers HTTP headers
	write_response: (text, status = 200, headers)=>
		@write_headers status, headers
		@write_body text
