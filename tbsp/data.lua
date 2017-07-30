local Request
do
  local _class_0
  local _base_0 = { }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, stream)
      assert(stream)
      self.stream = stream
      do
        local _tbl_0 = { }
        for k, v in stream:get_headers():each() do
          _tbl_0[k] = v
        end
        self.headers = _tbl_0
      end
      self.method = self.headers[':status']
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
