local StaticFileNotFoundError
do
  local _class_0
  local _base_0 = {
    __tostring = function(self)
      return ("%q: File not found"):format(self.file)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, file, request)
      self.file, self.request = file, request
    end,
    __base = _base_0,
    __name = "StaticFileNotFoundError"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  StaticFileNotFoundError = _class_0
  return _class_0
end
