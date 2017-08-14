--- Turbospoon: A MoonScript web framework
-- @author RyanSquared <vandor2012@gmail.com>
-- @classmod App

cqueues = setmetatable {}, __index: require "cqueues"
cqueues.socket = require "cqueues.socket"

http =
	headers: require "http.headers"
	server: require "http.server"

openssl =
	context: require "openssl.ssl.context"
	pkey: require "openssl.pkey"
	x509: require "openssl.x509"

import random_key from require "bassoon.util"
import JWTSerializer from require "bassoon.jwt"
import Logger from require "lumberjack"

import Request from require "tbsp.data"
import html_response from require "tbsp.response"
import StaticFileNotFoundError, RouteNotFoundError from require "tbsp.errors"

class App
	logger: Logger debug_level: 2, enabled: false

	handlers: {}
	errorhandlers: {}

	--- Spawn a new tbsp
	-- @tparam table opts
	-- - `opts.debug_level: number = 0` - Debug levels for Lumberjack logging
	-- - `opts.logger_enabled: bool = true` - Enable logging
	-- - `opts.cq: userdata = cqueues.new()` - cqueues controller
	-- @usage app = tbsp.App()
	new: (opts = {})=>
		@logger = Logger
			debug_level: opts.debug_level or 0
			enabled: opts.logger_enabled
		@logger\info "Initializing new application"
		@logger\debug 1, "Generating JWT wtih random key"
		@jwt = JWTSerializer!
		@config =
			tls: false
			static_dir: "static"
		@servers = {}
		@cq = opts.cq or cqueues.new()

		@logger\debug 2, "Generating routes and error handlers"
		@routes = {}
		@handlers = setmetatable {}, __index: App.handlers
		@errorhandlers = setmetatable {}, __index: App.errorhandlers
		
		@route "^/static/(.+)", (request, requested_file)->
			filename = "./#{@config.static_dir}/#{requested_file}"
			if file = io.open "./#{@config.static_dir}/#{filename}"
				content = file\read "a"
				file\close!
				return content
			else -- file opening failed, 404
				error(StaticFileNotFoundError(filename, request))

	--- Call a handler for a key, then set an appropriate config value
	-- @tparam string key
	-- @param value Value
	-- @usage app\set "config_option", "config_value"
	set: (key, value)=>
		if @handlers[key]
			@logger\debug 2, "Running handler for config option %s", key
			@handlers[key](self, value)
		@logger\debug 1, "Setting key %s to %s", key, value
		@config[key] = value
	
	--- Register a callback to handle configuration changes
	-- @tparam string key
	-- @tparam function callback
	-- @usage app\register_handler "config_option", (...)-> print ...
	register_handler: (key, callback)=>
		@logger\debug 2, "Registering config handler for %s", key
		@handlers[key] = callback

	--- Map server to an address and port
	-- @tparam string host Hostname for server to listen on. Set to '0.0.0.0' or
	-- '::' to listen on all available interfaces, '127.0.0.1' to listen on the
	-- local-only interface, or a custom interface
	-- @tparam number port Port for server to listen on. Most systems require
	-- this value to be above 1024. Use an iptables redirect to use ports below
	-- 1024.
	-- @tparam boolean tls Whether or not to use TLS for connections, defaults
	-- to @config.tls
	bind: (host, port, tls)=>
		@logger\log "info", "Binding server"
		server = http.server.new
			socket: cqueues.socket.listen host, port
			onstream: (server, stream)->
				@process stream
			tls: tls != nil and tls or @config.tls
			ctx: @tls_ctx
			max_concurrent: 200
			cq: @cq

		@logger\debug 1, "Server bound: #{server}"
		table.insert @servers, server

	--- Handle errors raised by @process
	-- @tparam object err Error object, should implement __tostring
	-- @tparam Request request Request object
	handle_error: (err, request)=>
		@logger\debug 2, "Error found: %s - processing for %s", err, request
		if type(err) == "table"
			cls = err.__class
			while cls
				if @errorhandlers[cls]
					@flush_response request, @errorhandlers[cls](self, err)
					return
				cls = cls.__parent
		@flush_response request, html_response(tostring(err), 500)

	--- Subscribe a callback to requests, first-come last-serve
	-- @tparam string path Lua pattern for matching URL paths
	-- @tparam function handler Function for processing requests
	route: (path, handler)=>
		@logger\debug 1, "Registering route %q", path
		table.insert @routes, 1, {:path, :handler}

	--- Subscribe a callback to handle errors
	-- @tparam object err Error class to track
	-- @tparam function handler Function for processing errors
	error_handler: (err, handler)=>
		@logger\debug 1, "Registering error handler %s", err.__name or err
		@errorhandlers[err] = handler

	default_headers =
		["content-type"]: "text/plain"
		[":status"]: "200"

	--- Flush values when given a body, status code, and headers
	-- @tparam Request request Request object
	-- @tparam string body (Optional) body to send to client
	-- @tparam string status (Optional) HTTP status to send to client
	-- @tparam http.headers headers (Optional) HTTP headers to send to client
	flush_response: (request, body = "", status, headers)=>
		response_headers = http.headers.new!
		for k, v in pairs default_headers
			@logger\debug 3, "Setting default header %q = %q", k, v
			response_headers\upsert k, v
		if headers
			for k, v in pairs headers
				@logger\debug 2, "Upserting header %q = %q", k, v
				response_headers\upsert k, v

		if status
			@logger\debug 1, "Upserting status to %s", status
			response_headers\upsert ":status", tostring(status)

		is_head = request.headers[':method'] == "HEAD"
		@logger\debug 1, "Sending headers for %s", tostring request
		request.stream\write_headers response_headers, is_head
		if is_head
			@logger\debug 2, "Not sending body - Client requested HEAD"
			return
		@logger\debug 1, "Sending body for %s", tostring request
		request.stream\write_chunk tostring(body), true
	
	--- Find page handler for a URL and process a request
	-- @tparam cqueues.socket stream Incoming stream to handle
	process: (stream)=>
		request = Request(stream, self)
		ok, err = pcall ->
			path = request.headers\get ":path"
			for route in *@routes
				if path\match route.path
					-- ::TODO:: get data from route.handler(), add JWT to the
					-- cookies, then flush response
					@flush_response request, route.handler(request
						path\match route.path)
					break

			error RouteNotFoundError(path, request)
		if not ok
			@handle_error(err, request)
	
	--- Start listening to incoming requests
	run: =>
		@cq\loop!

App\register_handler "certfile", (certfile)=>
	if file = io.open certfile
		@tls_ctx = openssl.context.new "TLS", true if not @tls_ctx
		@tls_ctx\setCertificate openssl.x509.new(file\read "a"), "PEM"
		-- ::TODO:: implement other formats than PEM
		@config.tls = true
	else
		error "Certificate file not found: #{certfile}"

App\register_handler "keyfile", (keyfile)=>
	if file = io.open keyfile
		@tls_ctx = openssl.context.new "TLS", true if not @tls_ctx
		@tls_ctx\setPrivateKey openssl.pkey.new(file\read "a"), "PEM"
		@config.tls = true
	else
		error "Key file not found: #{keyfile}"

App\error_handler RouteNotFoundError, (err)=>
	html_response "<h1>#{err}</h1>", 404

App\error_handler StaticFileNotFoundError, (err)=>
	html_response "<h1>#{err}</h1>", 404

return {:App}
