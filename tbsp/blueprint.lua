local Blueprint
do
  local _class_0
  local _base_0 = {
    handlers = { },
    errorhandlers = { },
    route = function(self, path, handler)
      self.logger:debug(1, "Registering route %q", path)
      return table.insert(self.routes, 1, {
        path = path,
        handler = handler
      })
    end,
    error_handler = function(self, err, handler)
      self.logger:debug(1, "Registering error handler %s", err.__name or err)
      self.errorhandlers[err] = handler
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self.routes = { }
      self.handlers = setmetatable({ }, {
        __index = Blueprint.handlers
      })
      self.errorhandlers = setmetatable({ }, {
        __index = Blueprint.errorhandlers
      })
    end,
    __base = _base_0,
    __name = "Blueprint"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Blueprint = _class_0
  return _class_0
end
