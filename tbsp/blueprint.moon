--- Class to provide routing information
-- @author RyanSquared <vandor2012@gmail.com>
-- @classmod Blueprint

class Blueprint
	handlers: {}
	errorhandlers: {}

	--- Create a new blueprint
	-- @tparam string path Relative (to blueprint) path to start blueprint
	new: (path = "/")=>
		@blueprints = {}
		@routes = {}
		@errorhandlers = setmetatable {}, __index: Blueprint.errorhandlers
		@path = path

	--- Subscribe a callback to requests, first-come last-serve
	-- @tparam string path Lua pattern for matching URL paths
	-- @tparam function handler Function for processing requests
	route: (path, handler)=>
		table.insert @routes, 1, {:path, :handler}

	--- Add a Blueprint to a path; takes priority over routes
	-- @tparam Blueprint blueprint
	add_blueprint: (blueprint)=>
		table.insert @blueprints, 1,
			path: blueprint.path
			:blueprint

	--- Subscribe a callback to handle errors
	-- @tparam object err Error class to track
	-- @tparam function handler Function for processing errors
	error_handler: (err, handler)=>
		@errorhandlers[err] = handler
