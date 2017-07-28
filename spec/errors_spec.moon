import RouteNotFoundError, StaticFileNotFoundError from require "tbsp.errors"

describe "tbsp.errors", ->
	describe "RouteNotFoundError", ->
		mock_request = {}
		err = RouteNotFoundError "/test", mock_request
		it "produces the correct error", ->
			assert.same {path: "/test", request: mock_request}, err
		it "produces the correct tostring() result", ->
			assert.same '"/test": No route found to resolve to path',
				tostring err

describe "tbsp.errors", ->
	describe "StaticFileNotFoundError", ->
		mock_request = {}
		err = StaticFileNotFoundError "/static/test.html", mock_request
		it "produces the correct error", ->
			assert.same {file: "/static/test.html", request: mock_request}, err
		it "produces the correct tostring() result", ->
			assert.same '"/static/test.html": File not found',
				tostring err
