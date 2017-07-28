local json, yaml, toml
do
  local _obj_0 = require("cereal")
  json, yaml, toml = _obj_0.json, _obj_0.yaml, _obj_0.toml
end
local _make_filetype_for
_make_filetype_for = function(headers, mime_type)
  headers["content-type"] = mime_type
  return headers
end
local html_response
html_response = function(content, status, headers)
  if headers == nil then
    headers = { }
  end
  return content, status, _make_filetype_for(headers, "text/html")
end
local json_response
json_response = function(content, status, headers)
  if headers == nil then
    headers = { }
  end
  return json.encode(content), status, _make_filetype_for(headers, "application/json")
end
local yaml_response
yaml_response = function(content, status, headers)
  if headers == nil then
    headers = { }
  end
  return yaml.encode(content), status, _make_filetype_for(headers, "text/x-yaml")
end
local toml_response
toml_response = function(content, status, headers)
  if headers == nil then
    headers = { }
  end
  return toml.encode(content), status, _make_filetype_for(headers, "text/x-toml")
end
return {
  html_response = html_response,
  json_response = json_response,
  yaml_response = yaml_response,
  toml_response = toml_response,
  _make_filetype_for = _make_filetype_for
}
