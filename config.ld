-- luacheck: ignore
-- vim:set noet sts=0 sw=3 ts=3 filetype=lua:
dir = 'docs'
project = 'Turbospoon'
description = 'A web framework written in MoonScript'
title = 'Turbospoon &middot; Documentation'
style = 'docs/style'
topics = {
	'.topics/Turbospoon.md';
}
file = {
	'tbsp';
	exclude = {'tbsp/errors/init.moon'}
}
all = true
format = 'markdown'
