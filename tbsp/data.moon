--- Data classes module
-- @author RyanSquared <vandor2012@gmail.com>

http =
	cookies: require "http.cookies"

-- @type Request
class Request
	--- Return a new Request container
	-- @function Request
	-- @tparam http.stream stream lua-http server -> client stream
	-- @tparam App tbsp_app Turbospoon app
	new: (stream, tbsp_app)=>
		assert stream
		assert tbsp_app
		@app = tbsp_app
		@stream = stream
		@headers = stream\get_headers!
		@method = @headers\get ":status"

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


return {:Request}
