# Turbospoon - A MoonScript Web Framework

Turbospoon implements an interface that is functionally pure, but also makes
use of metamethods allowing for syntax-assisted querying and other neat
quirks. Everything is still available by a function interface, however.

```moon
import App from require "tbsp"
import html_response from require "tbsp.response"

app\route "/hello/(%S+)", (page)=>
	@write_response html_response("Hello world, you loaded #{page}", 200)

app\set "certfile", "ssl/cert.pem"
app\set "keyfile", "ssl/key.pem"
app\bind "::", "4443"
app\run!
```

## Purpose

While [Lapis](https://github.com/leafo/lapis) acts like a "Django for Lua",
Turbospoon is similar to Flask. Everything is configured up to the user with
no magic, and is - for the most part - self-contained. Turbospoon is also built
and developed using Lua 5.3, which - while later, Lapis might fill this hole
as well - as of right now is a plus.

The web framework is built off of many modules that are not contained in the
web framework, so that they could instead be used elsewhere. The modules were
developed with Turbospoon in mind, however, and work best when paired with the
framework. Unlike some other frameworks, the script itself can act as an
executable that starts an HTTP server.

## Documentation

... can be found in ./docs, or compiled with LDoc.
