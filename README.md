# Koneko

For now, everything is hardcoded (identity, server info, etc.), if you don't know how to recompile some haXe sources yourself, you shouldn't be using Koneko anyway.
For the really tryhards:
haxe -neko koneko.n -cp src/ -main Main
neko koneko.n
For plugins, create a new .hx file, include any necessary sources and name your class 'External' and implement the IRCPlugin class (not necessary, but it saves you some work). Sample plugins soon (tm)

Licensed under the zlib/png license

# NOTE:
The code is undergoing a general overhaul, expect things to break at random.