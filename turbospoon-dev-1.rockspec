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
		["tbsp"] = "dist/tbsp/init.lua";
		["tbsp.blueprint"] = "dist/tbsp/blueprint.lua";
		["tbsp.data"] = "dist/tbsp/data.lua";
		["tbsp.response"] = "dist/tbsp/response.lua";
		["tbsp.errors"] = "dist/tbsp/errors/init.lua";
		["tbsp.errors.route_not_found"] = "dist/tbsp/errors/route_not_found.lua";
		["tbsp.errors.static_file_not_found"] = "dist/tbsp/errors/static_file_not_found.lua";
		["tbsp.data"] = "dist/tbsp/data/init.lua";
		["tbsp.data.request"] = "dist/tbsp/data/request.lua";
	};
}
