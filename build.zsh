#!/usr/bin/zsh -e

alias stat='stat -c %Y'
for file in $(find . -type f -name '*.moon' | grep -v '_spec'); do
	if ! [ -e ${file%.moon}.lua ]; then
		moonc $file
	elif ! grep "^spec" <<<$file; then
		[ $(stat $file) -gt $(stat ${file%.moon}.lua) ] && moonc $file
	fi
done
ldoc .
luarocks make --local
busted -o plainTerminal .
