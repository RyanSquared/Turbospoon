local http = {
  cookies = require("http.cookies"),
  headers = require("http.headers")
}
local Request
do
  local _class_0
  local _base_0 = {
    make_session_cookie = function(self, cookie, age)
      if age == nil then
        age = 60 * 60 * 24 * 28
      end
      self.cookies.session = {
        key = "session",
        value = self.app.jwt:encode(self.cookies.session),
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
    __init = function(self, stream, tbsp_app)
      assert(stream)
      assert(tbsp_app)
      self.app = tbsp_app
      self.stream = stream
      self.headers = stream:get_headers()
      self.method = self.headers:get(":method")
      for header, value in self.headers:each() do
        if header == "cookie" then
          local cookies = http.cookies.parse_cookies(value)
          if not self.cookies then
            do
              local _tbl_0 = { }
              for _index_0 = 1, #cookies do
                local cookie = cookies[_index_0]
                _tbl_0[cookie[1]] = cookie[2]
              end
              self.cookies = _tbl_0
            end
          else
            for _index_0 = 1, #cookies do
              local cookie = cookies[_index_0]
              local key
              key, value = cookie[1], cookie[2]
              self.cookies[key] = value
            end
          end
        end
      end
      if self.cookies and self.cookies.session then
        self.session = self.app.jwt:decode(self.cookies.session)
      else
        self.session = { }
      end
    end,
    __base = _base_0,
    __name = "Request"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Request = _class_0
  return _class_0
end
