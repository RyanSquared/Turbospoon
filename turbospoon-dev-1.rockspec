package = "turbospoon"
version = "dev-1"

source = {
	url = "git://github.com/RyanSquared/turbospoon";
}

description = {
	summary = "A web framework written in MoonScript";
}

dependencies = {
	"bassoon";
	"cereal";
	"lumberjack";
	"http";
}

build = {
	type = "builtin";
	modules = {
		["tbsp"] = "tbsp/init.lua";
		["tbsp.blueprint"] = "tbsp/blueprint.lua";
		["tbsp.data"] = "tbsp/data.lua";
		["tbsp.response"] = "tbsp/response.lua";
		["tbsp.errors"] = "tbsp/errors/init.lua";
		["tbsp.errors.route_not_found"] = "tbsp/errors/route_not_found.lua";
		["tbsp.errors.static_file_not_found"] = "tbsp/errors/static_file_not_found.lua";
		["tbsp.data"] = "tbsp/data/init.lua";
		["tbsp.data.request"] = "tbsp/data/request.lua";
	};
}
