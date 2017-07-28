--- Static file not found class
-- @author RyanSquared <vandor2012@gmail.com>
-- @classmod errors.StaticFileNotFoundError

class StaticFileNotFoundError
	new: (file, request)=>
		@file, @request = file, request
	
	__tostring: =>
		return ("%q: File not found")\format @file
