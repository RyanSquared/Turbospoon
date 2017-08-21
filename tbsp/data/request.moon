--- Store data from incoming requests
-- @author RyanSquared <vandor2012@gmail.com>
-- @classmod data.Request

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
