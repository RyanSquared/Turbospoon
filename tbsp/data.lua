local http = {
  cookies = require("http.cookies")
}
local Request
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, stream, tbsp_app)
      assert(stream)
      assert(tbsp_app)
      self.app = tbsp_app
      self.stream = stream
      self.headers = stream:get_headers()
      self.method = self.headers:get(":status")
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
end
return {
  Request = Request
}
