import App from require "tbsp"
import _set_entropy_file from require "bassoon.util"
_set_entropy_file "/dev/urandom"

cqueues = require "cqueues"
Blueprint = require "tbsp.blueprint"

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
		app = App logger_enabled: false, :cq

		app\route "/close", =>
			app.servers[1]\close!
		
		s = spy.on(app.routes[1], "handler")
		app\bind "::", "8081"
		cq\wrap ->
			socket_http.request "http://localhost:8081/close"
		assert app\run!
		assert.spy(s).was.called!
	
	it "can add and call an error handler", ->
		socket_http = require "http.compat.socket"
		cq = cqueues.new!
		app = App logger_enabled: false, :cq
		class GenericError
			new: =>
			__tostring: => "Generic Error"

		app\error_handler GenericError, ->
			app.servers[1]\close!
		s = spy.on(app.errorhandlers, GenericError)
		app\route "/err", =>
			error GenericError!
		app\bind "::", "8081"
		cq\wrap ->
			socket_http.request "http://localhost:8081/err"
			socket_http.request "http://localhost:8081/close"
		assert app\run!
		assert.spy(s).was.called!
	
	it "can return a proper response", ->
		socket_http = require "http.compat.socket"
		cq = cqueues.new!
		app = App logger_enabled: false, :cq

		app\route "/data", =>
			@write_response "message", 200, ["content-type"]: "text/plain"
		app\route "/close", =>
			app.servers[1]\close!
		
		s = spy.on(app.routes[1], "handler")
		app\bind "::", "8081"
		local test_data

		cq\wrap ->
			test_data = {socket_http.request "http://localhost:8081/data"}
			socket_http.request "http://localhost:8081/close"
		assert app\run!
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
	
	it "can properly process blueprints", ->
		socket_http = require "http.compat.socket"
		cq = cqueues.new!
		app = App logger_enabled: false, :cq

		blueprint = Blueprint "/base"
		blueprint\route "/test", =>
			"message", 200, ["content-type"]: "text/plain"

		app\add_blueprint blueprint
		app\route "/close", =>
			app.servers[1]\close!
		s = spy.on blueprint.routes[1], "handler"
		app\bind "::", "8081"

		local test_data
		cq\wrap ->
			test_data = {socket_http.request "http://localhost:8081/base/test"}
			socket_http.request "http://localhost:8081/close"
		assert app\run!
		assert.spy(s).was.called!

	it "can properly process recursive blueprints", ->
		socket_http = require "http.compat.socket"
		cq = cqueues.new!
		app = App logger_enabled: false, :cq

		first_blueprint = Blueprint "/base"

		second_blueprint = Blueprint "/second"
		second_blueprint\route "/test", =>
			"message", 200, ["content-type"]: "text/plain"

		first_blueprint\add_blueprint second_blueprint
		app\add_blueprint first_blueprint

		app\route "/close", =>
			app.servers[1]\close!
		s = spy.on second_blueprint.routes[1], "handler"
		app\bind "::", "8081"

		local test_data
		cq\wrap ->
			test_data = {
				socket_http.request "http://localhost:8081/base/second/test"}
			socket_http.request "http://localhost:8081/close"
		assert app\run!
		assert.spy(s).was.called!
