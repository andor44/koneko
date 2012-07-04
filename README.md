# Koneko

Koneko is a fairly small, extensible IRC bot written in Haxe and compiled to 
neko. Configuration happens with simple plaintext or json files. Koneko can
store "sessions". Right now, it's single-server only, so you have to run 
multiple Koneko instances for different servers, but Koneko respects this
and writes to different files accordingly. 

Plugins are arbitary, can be configured to do anything. 
See github/andor44/old_scraper for example. 

Example config files can be found in the repo (test.conf and test.json)

# Compilation and usage:
Compile using:
haxe -cp src -main Main -neko koneko.n
Then run:
neko koneko.n test.conf	
If you specified a claim password, you can claim it from the bot by messaging
:claim <claim password> <username> <md5 of your password>

# Support
If you need support, contact me here on github, ask me in #koneko@freenode or
feel free to support a pull request!

Licensed under the zlib/png license, I also won't refuse donations, lol

# NOTE:
The code is undergoing a general overhaul, expect things to break at random.