import App from require "tbsp"
import _set_entropy_file from require "bassoon.util"
_set_entropy_file "/dev/urandom"

cqueues = require "cqueues"

describe "tbsp.App", ->
	it "forms an application correctly", ->
		app = App logger_enabled: false
		assert app.logger
		assert.same {tls: false, static_dir: "static"}, app.config
		assert.same {}, app.servers
		assert app.cq
		assert next app.routes
		assert.same {}, app.handlers
		assert.same {}, app.errorhandlers
	
	it "can set config values properly", ->
		app = App logger_enabled: false
		app\set "key", "value"
		assert.is "value", app.config.key
	
	it "can register handlers triggered when setting values", ->
		app = App logger_enabled: false
		func = spy.new ->
		app\register_handler "test_value", func
		app\set "test_value", true
		assert.spy(func).was.called()
	
	it "can bind to an address and port without errors", ->
		app = App logger_enabled: false
		app\bind "::", "8000"
		assert.errors ->
			-- will fail because address is in use
			socket = require "cqueues.socket"
			socket.listen("::", "8000")\accept(0)
	
	it "can add and call routes", ->
		socket_http = require "http.compat.socket"
		cq = cqueues.new!
		app = App logger_enabled: false, cq: cq

		app\route "/close", ->
			app.servers[1]\close!
		
		s = spy.on(app.routes[1], "handler")
		app\bind "::", "8081"
		cq\wrap ->
			socket_http.request "http://localhost:8081/close"
		app\run!
		assert.spy(s).was.called!
	
	it "can add and call an error handler", ->
		socket_http = require "http.compat.socket"
		cq = cqueues.new!
		app = App logger_enabled: false, cq: cq
		class GenericError
			new: =>
			__tostring: => "Generic Error"

		app\error_handler GenericError, ->
			app.servers[1]\close!
		s = spy.on(app.errorhandlers, GenericError)
		app\route "/err", ->
			error GenericError!
		app\bind "::", "8081"
		cq\wrap ->
			socket_http.request "http://localhost:8081/err"
		--socket_http.request "http://localhost:8081/close"
		app\run!
		assert.spy(s).was.called!
	
	it "can return a proper response", ->
		socket_http = require "http.compat.socket"
		cq = cqueues.new!
		app = App logger_enabled: false, cq: cq

		app\route "/data", ->
			"message", 200, ["content-type"]: "text/plain"
		app\route "/close", ->
			app.servers[1]\close!
		
		s = spy.on(app.routes[1], "handler")
		app\bind "::", "8081"
		local test_data

		cq\wrap ->
			test_data = {socket_http.request "http://localhost:8081/data"}
			socket_http.request "http://localhost:8081/close"
		app\run!
		assert.same {
			"message",
			200
			{
				["content-type"]: "text/plain"
				connection: "transfer-encoding"
				["transfer-encoding"]: "chunked"
			}
			"OK"
		}, test_data
		assert.spy(s).was.called!
