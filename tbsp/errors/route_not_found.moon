--- Route not found classfile
-- @author RyanSquared <vandor2012@gmail.com>
-- @classmod errors.RouteNotFoundError

class RouteNotFoundError
	new: (path, request)=>
		@path, @request = path, request
	
	__tostring: =>
		return ("%q: No route found to resolve to path")\format @path
