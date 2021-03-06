--- Module for Turbospoon data serialization and MIME type assistance
-- @module tbsp.response

http =
	headers: require "http.headers"

import json, yaml, toml from require "cereal"

_make_filetype_for = (headers, mime_type)->
	headers\upsert "content-type", mime_type
	return headers

--- Generate an HTML response with proper MIME type
-- @tparam body content
-- @tparam string status Numeric string, HTTP status code
-- @tparam http.headers headers Optional HTTP headers
html_response = (content, status, headers = http.headers.new!)->
	return content, status, _make_filetype_for headers, "text/html"

--- Generate a JSON serialized response from Lua table with proper MIME type
-- @tparam table content
-- @tparam string status Numeric string, HTTP status code
-- @tparam http.headers headers Optional HTTP headers
json_response = (content, status, headers = http.headers.new!)->
	return json.encode(content), status, _make_filetype_for(headers,
		"application/json")

--- Generate a YAML serialized response from Lua table with proper MIME type
-- @tparam table content
-- @tparam string status Numeric string, HTTP status code
-- @tparam http.headers headers Optional HTTP headers
yaml_response = (content, status, headers = http.headers.new!)->
	return yaml.encode(content), status, _make_filetype_for(headers,
		"text/x-yaml")

--- Generate a TOML serialized response from Lua table with proper MIME type
-- @tparam table content
-- @tparam string status Numeric string, HTTP status code
-- @tparam http.headers headers Optional HTTP headers
toml_response = (content, status, headers = http.headers.new!)->
	return toml.encode(content), status, _make_filetype_for(headers,
		"text/x-toml")

return {:html_response, :json_response, :yaml_response, :toml_response,
	:_make_filetype_for}
