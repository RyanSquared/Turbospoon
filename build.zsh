#!/usr/bin/zsh -e

alias stat='stat -c %Y'
for file in $(find tbsp -type f -name '*.moon'); do
	if ! [ -e dist/${file%.moon}.lua ]; then
		moonc -t dist $file
	elif ! grep "^spec" <<<$file; then
		[ $(stat $file) -gt $(stat dist/${file%.moon}.lua) ] && moonc $file
	fi
done
ldoc .
luarocks make --local
busted -o plainTerminal .
