class StaticFileNotFoundError
	new: (file, request)=>
		@file, @request = file, request
	
	__tostring: =>
		return ("%q: File not found")\format @file
