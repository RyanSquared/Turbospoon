local cqueues = setmetatable({ }, {
  __index = require("cqueues")
})
cqueues.socket = require("cqueues.socket")
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
local Signer
Signer = require("bassoon").Signer
local Logger
Logger = require("lumberjack").Logger
local Request = require("tbsp.data.request")
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
    handle_error = function(self, err, request)
      self.logger:debug(2, "Error found: %s - processing for %s", err, request)
      if type(err) == "table" then
        local cls = err.__class
        while cls do
          if self.errorhandlers[cls] then
            self:flush_response(request, self.errorhandlers[cls](self, err))
            return 
          end
          cls = cls.__parent
        end
      end
      return self:flush_response(request, html_response(tostring(err), 500))
    end,
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
    end,
    flush_response = function(self, request, body, status, headers)
      if body == nil then
        body = ""
      end
      local response_headers = http.headers.new()
      for k, v in pairs(default_headers) do
        self.logger:debug(3, "Setting default header %q = %q", k, v)
        response_headers:upsert(k, v)
      end
      if headers then
        for k, v in pairs(headers) do
          self.logger:debug(2, "Upserting header %q = %q", k, v)
          response_headers:upsert(k, v)
        end
      end
      if status then
        self.logger:debug(1, "Upserting status to %s", status)
        response_headers:upsert(":status", tostring(status))
      end
      local is_head = request.headers[':method'] == "HEAD"
      self.logger:debug(1, "Sending headers for %s", tostring(request))
      request.stream:write_headers(response_headers, is_head)
      if is_head then
        self.logger:debug(2, "Not sending body - Client requested HEAD")
        return 
      end
      self.logger:debug(1, "Sending body for %s", tostring(request))
      return request.stream:write_chunk(tostring(body), true)
    end,
    process = function(self, stream)
      local request = Request(stream)
      local ok, err = pcall(function()
        local path = request.headers[':path']
        local _list_0 = self.routes
        for _index_0 = 1, #_list_0 do
          local route = _list_0[_index_0]
          if path:match(route.path) then
            self:flush_response(request, route.handler(request, path:match(route.path)))
            break
          end
        end
        return error(RouteNotFoundError(path, request))
      end)
      if not ok then
        return self:handle_error(err, request)
      end
    end,
    run = function(self)
      return self.cq:loop()
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.logger = Logger({
        debug_level = opts.debug_level or 0,
        enabled = opts.logger_enabled
      })
      self.logger:info("Initializing new application")
      self.logger:debug(1, "Generating random key")
      self.secret_key = random_key()
      self.logger:debug(1, "Done generating random key")
      self.signer = Signer(self.secret_key)
      self.config = {
        tls = false,
        static_dir = "static"
      }
      self.servers = { }
      self.cq = opts.cq or cqueues.new()
      self.logger:debug(2, "Generating routes and error handlers")
      self.routes = { }
      self.handlers = setmetatable({ }, {
        __index = App.handlers
      })
      self.errorhandlers = setmetatable({ }, {
        __index = App.errorhandlers
      })
      self:route("^/static/(.+)", function(request, requested_file)
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
      return self.logger:debug(2, "Done generating routes and error handlers")
    end,
    __base = _base_0,
    __name = "App"
  }, {
    __index = _base_0,
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
  App = _class_0
end
App:register_handler("certfile", function(self, certfile)
  do
    local file = io.open(certfile)
    if file then
      if not self.tls_ctx then
        self.tls_ctx = context.new("TLS", true)
      end
      self.tls_ctx:setCertificate(x509.new(file:read("a")), "PEM")
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
        self.tls_ctx = context.new("TLS", true)
      end
      self.tls_ctx:setPrivateKey(pkey.new(file:read("a")), "PEM")
      self.config.tls = true
    else
      return error("Key file not found: " .. tostring(keyfile))
    end
  end
end)
App:error_handler(RouteNotFoundError, function(self, err)
  return html_response("<h1>" .. tostring(err) .. "</h1>", 404)
end)
App:error_handler(StaticFileNotFoundError, function(self, err)
  return html_response("<h1>" .. tostring(err) .. "</h1>", 404)
end)
return {
  App = App
}
