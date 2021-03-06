local http = {
  cookies = require("http.cookies"),
  headers = require("http.headers")
}
local Response
do
  local _class_0
  local _base_0 = {
    add_cookie = function(self, cookie)
      assert(cookie.max_age, "Missing cookie.max_age")
      assert(cookie.key, "Missing cookie.key")
      assert(cookie.value, "Missing cookie.value")
      self.cookies[cookie.key] = cookie.key
    end,
    remove_cookie = function(self, key)
      self.cookies[key] = nil
    end,
    _make_session_cookie = function(self, age)
      if age == nil then
        age = 60 * 60 * 24 * 28
      end
      if not self.session then
        return 
      end
      self.cookies.session = {
        key = "session",
        value = self.app.jwt:encode(self.session),
        max_age = age,
        http_only = true
      }
    end,
    write_headers = function(self, status, headers)
      if headers == nil then
        headers = http.headers.new()
      end
      assert(status)
      local headers_mt = getmetatable(headers)
      if headers_mt ~= http.headers.mt then
        local new_headers = http.headers.new()
        for k, v in pairs(headers) do
          new_headers:append(k, v)
        end
        headers = new_headers
      end
      if not headers:has("content-type") then
        headers:append("content-type", "text/plain")
      end
      self:_make_session_cookie()
      local _list_0 = self.cookies
      for _index_0 = 1, #_list_0 do
        local cookie = _list_0[_index_0]
        headers:append("set-cookie", http.cookies.bake_cookie(cookie))
      end
      headers:upsert(":status", tostring(status))
      return self.stream:write_headers(headers, self.method == "HEAD")
    end,
    write_body = function(self, text)
      if self.method == "HEAD" then
        return 
      end
      return self.stream:write_chunk(tostring(text), true)
    end,
    write_response = function(self, text, status, headers)
      if status == nil then
        status = 200
      end
      self:write_headers(status, headers)
      return self:write_body(text)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, stream, tbsp_app, request)
      assert(stream)
      assert(tbsp_app)
      self.stream = stream
      self.app = tbsp_app
      self.cookies = { }
      self.session = request.session
    end,
    __base = _base_0,
    __name = "Response"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Response = _class_0
  return _class_0
end
