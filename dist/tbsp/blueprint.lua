local Blueprint
do
  local _class_0
  local _base_0 = {
    handlers = { },
    errorhandlers = { },
    route = function(self, path, handler)
      return table.insert(self.routes, 1, {
        path = path,
        handler = handler
      })
    end,
    add_blueprint = function(self, blueprint)
      return table.insert(self.blueprints, 1, {
        path = blueprint.path,
        blueprint = blueprint
      })
    end,
    error_handler = function(self, err, handler)
      self.errorhandlers[err] = handler
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, path)
      if path == nil then
        path = "/"
      end
      self.blueprints = { }
      self.routes = { }
      self.errorhandlers = setmetatable({ }, {
        __index = Blueprint.errorhandlers
      })
      self.path = path
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
