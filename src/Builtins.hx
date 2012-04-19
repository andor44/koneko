package ;

import neko.FileSystem;
import neko.Sys;
import neko.vm.Loader;

import IRCPlugin;
import irc.IRCSocket;

/**
 * ...
 * @author Andor
 */

class Builtins 
{
	// NOTE: these methods are the built in commands (see privMsgHandler)
	// they take the same vars as parameters as the privmsg handler and return a Null<String>, string to reply and null if there's nothing to reply
	// these ONLY and EXCLUSIVELY do what they're supposed to do, eg. no access level checking and the sorts...
	public static function loadmod(user : IRCUser, target : String, msg:String, mod_loader : String -> IRCPlugin, modcache : Hash<IRCPlugin>) : Null<String>
	{
		var module = mod_loader(msg.split(" ")[1]);
		
		// old stuff, also found in loadmod
		/*var loader = Loader.local();
		loader.addPath(Sys.getCwd());
		loader.addPath(Sys.executablePath());
		var modname = msg.split(" ")[1]; var modcache = loader.getCache(); var old_path = ""; var new_path = "";
		if (modcache.exists(modname))
		{
			var count = 1;
			while (modcache.exists(modname + Std.string(count)))
				count++;
			if (FileSystem.exists(Sys.getCwd() + modname) || FileSystem.exists(Sys.getCwd() + modname + ".n"))
			{
				FileSystem.rename(Sys.getCwd() + modname + ".n", Sys.getCwd() + modname + count + ".n");
				old_path = Sys.getCwd() + modname + ".n";
				new_path = Sys.getCwd() + modname + count + ".n";
			}
			modname += count;
		}
		var mod = loader.loadModule(modname);
		if (old_path != "")
			FileSystem.rename(new_path, old_path);
		var classes : Dynamic = mod.exportsTable().__classes;
		var obj = Type.createInstance(classes.External, []);
		var final_plugin : IRCPlugin = obj;
		Main.modules.set(final_plugin.name, final_plugin);
		return ("loaded module " + final_plugin.name);*/
		
		modcache.set(module.name, module);
		return "loaded module '" + module.name + "'";
	}
}