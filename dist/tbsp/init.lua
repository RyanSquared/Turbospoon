local cqueues = setmetatable({ }, {
  __index = require("cqueues")
})
cqueues.socket = require("cqueues.socket")
local tbsp = {
  Blueprint = require("tbsp.blueprint")
}
local http = {
  headers = require("http.headers"),
  server = require("http.server")
}
local openssl = {
  context = require("openssl.ssl.context"),
  pkey = require("openssl.pkey"),
  x509 = require("openssl.x509")
}
local random_key
random_key = require("bassoon.util").random_key
local JWTSerializer
JWTSerializer = require("bassoon.jwt").JWTSerializer
local Logger
Logger = require("lumberjack").Logger
local Request, Response
do
  local _obj_0 = require("tbsp.data")
  Request, Response = _obj_0.Request, _obj_0.Response
end
local html_response
html_response = require("tbsp.response").html_response
local StaticFileNotFoundError, RouteNotFoundError
do
  local _obj_0 = require("tbsp.errors")
  StaticFileNotFoundError, RouteNotFoundError = _obj_0.StaticFileNotFoundError, _obj_0.RouteNotFoundError
end
local App
do
  local _class_0
  local default_headers
  local _parent_0 = tbsp.Blueprint
  local _base_0 = {
    logger = Logger({
      debug_level = 2,
      enabled = false
    }),
    handlers = { },
    errorhandlers = { },
    set = function(self, key, value)
      if self.handlers[key] then
        self.logger:debug(2, "Running handler for config option %s", key)
        self.handlers[key](self, value)
      end
      self.logger:debug(1, "Setting key %s to %s", key, value)
      self.config[key] = value
    end,
    register_handler = function(self, key, callback)
      self.logger:debug(2, "Registering config handler for %s", key)
      self.handlers[key] = callback
    end,
    bind = function(self, host, port, tls)
      self.logger:log("info", "Binding server")
      local server = http.server.new({
        socket = cqueues.socket.listen(host, port),
        onstream = function(server, stream)
          return self:process(stream)
        end,
        tls = tls ~= nil and tls or self.config.tls,
        ctx = self.tls_ctx,
        max_concurrent = 200,
        cq = self.cq
      })
      self.logger:debug(1, "Server bound: " .. tostring(server))
      return table.insert(self.servers, server)
    end,
    handle_error = function(self, err, request, response)
      self.logger:debug(2, "Error found: %s - processing for %s", err, request)
      if type(err) == "table" then
        local cls = err.__class
        while cls do
          if self.errorhandlers[cls] then
            self.errorhandlers[cls](response, err, self)
            return 
          end
          cls = cls.__parent
        end
      end
      return response:write_response(html_response(tostring(err), 500))
    end,
    process = function(self, stream)
      local routes = self.routes
      local request = Request(stream, self)
      local response = Response(stream, self, request)
      local path = request.headers:get(":path")
      local blueprints = self.blueprints
      while true do
        local has_blueprint
        for _index_0 = 1, #blueprints do
          local route = blueprints[_index_0]
          local rt_path_len = #route.path
          if path:sub(1, rt_path_len) == route.path and path:sub(rt_path_len + 1, rt_path_len + 1) == "/" then
            has_blueprint = true
            path = path:sub(rt_path_len + 1)
            blueprints = route.blueprint.blueprints
            routes = route.blueprint.routes
          end
        end
        if not has_blueprint then
          break
        end
      end
      local ok, err = pcall(function()
        for _index_0 = 1, #routes do
          local route = routes[_index_0]
          if path:match(route.path) then
            route.handler(response, request, path:match(route.path))
            return 
          end
        end
        return error(RouteNotFoundError(path, request))
      end)
      if not ok then
        return self:handle_error(err, request, response)
      end
    end,
    run = function(self)
      return self.cq:loop()
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      _class_0.__parent.__init(self, "/")
      self.logger = Logger({
        debug_level = opts.debug_level or 0,
        enabled = opts.logger_enabled
      })
      self.logger:info("Initializing new application")
      self.logger:debug(1, "Generating JWT wtih random key")
      self.jwt = JWTSerializer()
      self.config = {
        tls = false,
        static_dir = "static"
      }
      self.servers = { }
      self.cq = opts.cq or cqueues.new()
      self.logger:debug(2, "Generating routes and error handlers")
      self.routes = { }
      self.errorhandlers = setmetatable({ }, {
        __index = App.errorhandlers
      })
      self.handlers = setmetatable({ }, {
        __index = App.handlers
      })
      return self:route("/static/(.+)", function(request, requested_file)
        local filename = "./" .. tostring(self.config.static_dir) .. "/" .. tostring(requested_file)
        do
          local file = io.open("./" .. tostring(self.config.static_dir) .. "/" .. tostring(filename))
          if file then
            local content = file:read("a")
            file:close()
            return content
          else
            return error(StaticFileNotFoundError(filename, request))
          end
        end
      end)
    end,
    __base = _base_0,
    __name = "App",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  default_headers = {
    ["content-type"] = "text/plain",
    [":status"] = "200"
  }
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  App = _class_0
end
App:register_handler("certfile", function(self, certfile)
  do
    local file = io.open(certfile)
    if file then
      if not self.tls_ctx then
        self.tls_ctx = openssl.context.new("TLS", true)
      end
      self.tls_ctx:setCertificate(openssl.x509.new(file:read("a")), "PEM")
      self.config.tls = true
    else
      return error("Certificate file not found: " .. tostring(certfile))
    end
  end
end)
App:register_handler("keyfile", function(self, keyfile)
  do
    local file = io.open(keyfile)
    if file then
      if not self.tls_ctx then
        self.tls_ctx = openssl.context.new("TLS", true)
      end
      self.tls_ctx:setPrivateKey(openssl.pkey.new(file:read("a")), "PEM")
      self.config.tls = true
    else
      return error("Key file not found: " .. tostring(keyfile))
    end
  end
end)
App:error_handler(RouteNotFoundError, function(self, err)
  return self:write_response(html_response("<h1>" .. tostring(err) .. "</h1>", 404))
end)
App:error_handler(StaticFileNotFoundError, function(self, err)
  return self:write_response(html_response("<h1>" .. tostring(err) .. "</h1>", 404))
end)
return {
  App = App
}
