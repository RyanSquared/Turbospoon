--- Class to provide routing information
-- @author RyanSquared <vandor2012@gmail.com>
-- @classmod Blueprint

class Blueprint
	handlers: {}
	errorhandlers: {}

	new: =>
		@routes = {}
		@handlers = setmetatable {}, __index: Blueprint.handlers
		@errorhandlers = setmetatable {}, __index: Blueprint.errorhandlers
	
	--- Subscribe a callback to requests, first-come last-serve
	-- @tparam string path Lua pattern for matching URL paths
	-- @tparam function handler Function for processing requests
	route: (path, handler)=>
		@logger\debug 1, "Registering route %q", path
		table.insert @routes, 1, {:path, :handler}

	--- Subscribe a callback to handle errors
	-- @tparam object err Error class to track
	-- @tparam function handler Function for processing errors
	error_handler: (err, handler)=>
		@logger\debug 1, "Registering error handler %s", err.__name or err
		@errorhandlers[err] = handler
