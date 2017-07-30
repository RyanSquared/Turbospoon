--- Data classes module
-- @author RyanSquared <vandor2012@gmail.com>

class Request
	--- Return a new Request container
	-- @function Request\new
	-- @tparam http.stream stream lua-http server -> client stream
	new: (stream)=>
		assert stream
		@stream = stream
		@headers = {k, v for k, v in stream\get_headers()\each!}
		@method = @headers[':status']

return {:Request}
