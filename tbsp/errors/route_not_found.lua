local RouteNotFoundError
do
  local _class_0
  local _base_0 = {
    __tostring = function(self)
      return ("%q: No route found to resolve to path"):format(self.path)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, path, request)
      self.path, self.request = path, request
    end,
    __base = _base_0,
    __name = "RouteNotFoundError"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  RouteNotFoundError = _class_0
  return _class_0
end
