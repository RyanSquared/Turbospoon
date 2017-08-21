--- Handle outgoing responses
-- @author RyanSquared <vandor2012@gmail.com>
-- @classmod data.Response

http =
	cookies: require "http.cookies"
	headers: require "http.headers"

class Response
	--- Return a Response handler
	-- @tparam http.stream stream lua-http server -> client stream
	-- @tparam App tbsp_app Turbospoon app
	-- @tparam Request request Associated request object
	new: (stream, tbsp_app, request)=>
		assert stream
		assert tbsp_app
		@stream = stream
		@app = tbsp_app
		@cookies = {}
		@session = request.session

	--- Add a cookie to be sent back to the client
	-- @tparam table cookie
	-- **Must have the following fields:**
	--
	-- - `max_age` - Amount of seconds for the cookie to live (`0` == session)
	-- - `key` - Name to store the cookie by
	-- - `value` - Value for the cookie, can be any RFC-safe string
	--
	-- **Can also have the following fields:**
	--
	-- - `domain` - PSL-compatible domain name where the cookie is valid
	-- - `path` - URI path where the cookie is valid
	-- - `secure` - Whether a cookie can be sent over unencrypted connections
	-- - `http_only` - Whether browsers, etc. should be able to read the cookie
	-- - `same_site` (`"strict"` or `"lax"`) - Same Site cookie policy
	add_cookie: (cookie)=>
		assert cookie.max_age, "Missing cookie.max_age"
		assert cookie.key, "Missing cookie.key"
		assert cookie.value, "Missing cookie.value"
		@cookies[cookie.key] = cookie.key

	--- Remove a cookie based on key
	-- @tparam string key
	remove_cookie: (key)=>
		@cookies[key] = nil

	--- Create session cookies and set it as a header
	-- @tparam number age Age for cookie (default 28 days)
	_make_session_cookie: (age = 60 * 60 * 24 * 28)=>
		-- no need to worry about optimizing ^ because most Lua interpreters
		-- implement folding of static values automatically
		return if not @session
		@cookies.session =
			key: "session"
			value: @app.jwt\encode @session
			max_age: age
			http_only: true

	-- ::TODO:: redirect()

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

		@_make_session_cookie!

		for cookie in *@cookies
			headers\append "set-cookie", http.cookies.bake_cookie cookie

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
