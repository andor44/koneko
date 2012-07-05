package ;

// builtins
import haxe.Md5;
import haxe.Serializer;
import haxe.Stack;
import haxe.Unserializer;
import neko.Boot;
import neko.FileSystem;
import neko.io.File;
import neko.io.FileOutput;
import neko.io.Path;
import neko.Lib;
import neko.net.Host;
import neko.Sys;
import neko.vm.Gc;
import neko.vm.Loader;
import neko.vm.Module;

// my stuff, lol
import irc.IRCReplies;
import irc.IRCSocket;
import IRCPlugin; // needed for trigger, no idea why
import AccessSettings;
import Channel;
import Settings;
import SettingsParser;

// because we like if it's shorter
using Main;
using Lambda;
using StringTools;

/**
 * @author Andor Uhlar
 * 
 * koneko - a rather dumb haXe/neko irc bot
 * (c) 2011 Andor Uhlar et al
 * 
 */

// TODO: maybe implement wildcard matching?
class UserInfo
{
	public var access : Int;
	public var hosts : List<String>;
	public var password : String;
	public function new (pwd:String, acc:Int)
	{
		password = pwd;
		access = acc;
		hosts = new List<String>();
	}
}

class Main 
{
	// currently loaded modules
	static var modules : Hash<IRCPlugin>;
	// bot users (not channel members, but people who have access to the bot)
	static var users : Hash<UserInfo>;
	// list of channels the bot is on, hash is the channel name since that doesn't change
	static var channels : Hash<Channel>;
	// SINGLE SERVER, for now....
	static var conn : IRCSocket; // TECHNICALLY, these could be exploited... 
										// i don't think the neko/haxe compiler checks for... bah, fuck this shit
										// if you're loading a harmful module, well, good fucking job
										// (just submit a pull req if you feel like explaining this...
	
	static var accessSettings : AccessSettings;
	static var ircSettings : Settings;
	
	public static var config_dir = "./servers";
	
	static function rawHandler(rawLine : String) : Void
	{
		Lib.println(rawLine);
	}
	
	static function joinHandler(user : IRCUser, channel : String)
	{
		try 
		{
			if (!channels.get(channel).hasUser(user.nick)) channels.get(channel).users.push(new ChannelUser(user));
		}
		catch (e : Dynamic)
 		{
			trace(e); // shit happens
		}
	}
	
	static function leaveHandler(user : IRCUser, channel : String, message : String)
	{
		channels.get(channel).users.remove(new ChannelUser(user));
	}
	
	static function privMsgHandler(user:IRCUser, target:String, msg:String) 
	{
		Lib.println("(" + target + ")" + "<" + user.nick + ">:" + msg);
		var inChannel = target.startsWith("#");
		var split = msg.split(" ");
		
		// oh god what in the fuck is this? D:
		// no srsly what was i thinking when i wrote this, i oughta rewrite this with dat builtincommands (NOPE)
		// maybe some later date
		// TODO: implement builtin generics and clean up this mess
		try	
		{
			switch (split[0])
			{
				case ":writeconf":
				if (getAccess(user.host) > accessSettings.writeconf_access) 
				{
					SettingsParser.serialize_config(ircSettings, split.length > 1 ? split[1] : "settings.koneko");
				}
				case ":dumpchan":
				var str = "";
				if (channels.keys().has(split[1])) 
				{
					for (i in channels.get(split[1]).users) 
					{
						str += i.nick + " " + i.mode + " ";
					}
					conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + split[1] + ": " + str);
				}
				case ":loadmod", ":loadmodule":
				{
					if (getAccess(user.host) >= accessSettings.loadmod_access)
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + Builtins.loadmod(user, target, msg, load_module, modules));
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "you weren't serious about that, were you?"); 
				}
				case ":rmmod", ":unload":
				{
					if (modules.keys().has(split[1]))
					{
						if (getAccess(user.host) >= modules.get(split[1]).accessLevel) // per-level wise
						{
							if (modules.remove(split[1])) conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "unloaded module " + split[1]);
							else                          conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "failed to unload module " + split[1] + " (maybe misspelled? silly " + user.nick + ")");
						}
					}
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "no such module");
				}
				case ":listmods", ":listmodules", ":lsmod":
				{
					if (getAccess(user.host) >= accessSettings.listmodules_access)
					{
						var modules_str = "";
						for (i in modules.keys())
							modules_str += i + ", ";
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + modules_str.substr(0,modules_str.length - 2));
					}
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "nope.avi");
				}
				case ":setaccess":
				{					
					if (modules.exists(split[1]))
					{
						if (getAccess(user.host) >= modules.get(split[1]).accessLevel) 
						{
							modules.get(split[1]).accessLevel = Std.parseInt(split[2]);
						}
					}
				}
				case ":adduser":
				{
					if (getAccess(user.host) >= accessSettings.adduser_access)
					{
						if (split.length < 4)
							conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "not enough params, use: :adduser <username> <md5 pass> <access>");
						else
						{
							if (users.exists(split[1]))
								conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "user '" + split[1] + "' already exists");
							else
							{
								users.set(split[1], new UserInfo(split[2], Std.parseInt(split[3])));
								conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "added user '" + split[1] + "' with access level " + split[3] );
							}
						}
					}
				}
				case ":md5":
				{
					conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + Md5.encode(split.slice(1).join(" ")));
				}
				case ":identify":
				{
					var res = identify(split[1], split[2]);
					if (res == 0)
					{
						conn.doPrivMsg(user.nick, "you're identified for '" + split[1] + "' :>");
						if (!users.get(split[1]).hosts.has(user.host)) // if (!Lambda.has(users.get(split[1]).hosts, user.host))
							users.get(split[1]).hosts.push(user.host);
					}
					else if (res == 1)
						conn.doPrivMsg(user.nick, "no such user, silly " + user.nick + "~");
					else if (res == 2)
						conn.doPrivMsg(user.nick, "invalid pw :|");
				}
				case ":resync", ":flush":
				{
					if (getAccess(user.host) >= accessSettings.resync_access) resync();
				}
				case ":join":
				{
					if (getAccess(user.host) >= accessSettings.join_access)
					{
						conn.doJoin(split[1]);
						var chan = new Channel(split[1]);
						channels.set(split[1], chan); // let's hope it DOES work this way (YOU'RE AN IDIOT LOUIS)
					}
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "nodoesfine");
				}
				case ":nick":
				{
					if (getAccess(user.host) >= accessSettings.nick_access)
						conn.doNick(split[1]);
					else 
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "gaaaaaaaaaaaaaaaay");
				}
				case ":raw":
				{
					if (getAccess(user.host) >= accessSettings.raw_access)
						conn.doRaw(split.slice(1).join(" "));
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "HAHA OH WOW.   no");
				}
				case ":leave", ":part":
				{
					if (getAccess(user.host) >= accessSettings.part_access)
						conn.doPart(split[1]);
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "i don't plan on doing that");
				}
				case ":quit", ":die", "get out":
				{
					if (getAccess(user.host) >= accessSettings.quit_access || user.host == "wat.wat.wat") // lol
						conn.doQuit(split.length >= 2 ? split.slice(1).join(" ") : "beep boop son, beep boop");
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "maybe some other day");
				}
				case ":getacc", ":details":
				{
					if (users.exists(split[1]))
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "user '" + split[1] + "' has access level " + users.get(split[1]).access + ". their hosts are " + users.get(split[1]).hosts.toString());
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "i've got no clue who " + split[1] + " is");
				}
				case ":say", ":msg":
				{
					if (getAccess(user.host) >= accessSettings.say_access)
					{
						if (split.length < 3)
						{
							if (inChannel)
								conn.doPrivMsg(target, "baka " + user.nick + ", you didn't tell me what to say");
							else
								conn.doPrivMsg(user.nick, "you didn't tell me what to say :(");
						}
						else
							conn.doPrivMsg(split[1], split.slice(2).join(" "));
					}
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "i cowardly refuse");
				}
				case ":listchans":
				{
					if (getAccess(user.host) >= accessSettings.listchans_access)
					{
						var chans = "";
						for (i in channels) 
							chans += i.name + ", ";
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "channels I'm currently on: " + chans.substr(0, chans.length - 2));
					}
				}
				case ":topic":
				if (inChannel) 
				{
					conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + channels.get(target).topic); // this'll probably break a whole. damn. lot.
				}
				case ":claim":
				if (users.empty() && ircSettings.claim != null && ircSettings.claim != "") 
				{
					if (split.length > 3 && (split[1] == ircSettings.claim)) 
					{
						users.set(split[2], new UserInfo(split[3], 11)); // we can assume level 11 here, highest access requirement by default is 10
						conn.doPrivMsg(user.nick, "Claim accepted. Added you as the new master user.");
					}
					else
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "Syntax is :claim <claim pw> <username> <md5 of password>");
				}
				case ":vm", ":neko":
				{
					if (split.length < 2)
						conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "usage: vm [stats|gc|modules|moduleinfo <modulename>]");
					else
					{
						switch (split[1])
						{
							case "stats":
								var stats = Gc.stats();
								conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "free: " + (stats.free / 1024) + "kB || heap: " + (stats.heap / 1024) + "kB");
							case "gc":
								if (split.length > 1)
								{
									if (split[2] == "yes" || split[2] == "true" || split[2] == "major")
										Gc.run(true);
								}
								else
									Gc.run(false);
							case "modules":
								var str = "";
								for (i in Loader.local().getCache())
									str += "[name:" + i.name + " codesize: " + i.codeSize() + " globals count: " + i.globalsCount() + "]";  
								conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + str);
							case "moduleinfo":
								if (split.length < 3) conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "y u no give module name :<");
								else
								{
									if (Loader.local().getCache().exists(split[2]))
									{
										var mod = Loader.local().getCache().get(split[2]);
										var strn = "";
										strn += "[name: " + mod.name + " codesize: " + mod.codeSize() + " globals count: " + mod.globalsCount() + " exports table fields: " + Reflect.fields(mod.exportsTable()).join(" ") + "]";
										
										conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + strn);
									}
									else
										conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + "module '" + split[2] + "' not found");
								}
						}
					}
				}
				default:
					for (i in modules) 
					{
						if ((Std.string(i.trigger) == "Privmsg") && (i.accessLevel <= getAccess(user.host))) // why 
						{
							i.getResult(user, conn.myself, conn, msg, target);
						}
						
					}	
			}
		}
		// TODO: maybe something less obnoxious?
		catch (e:Dynamic)
		{
			trace(e);
			trace("Exception stack:");
			for (i in Stack.exceptionStack())
			{
				trace(i);
			}
			trace("Call stack:");
			for (i in Stack.callStack())
			{
				trace(i);
			}
			conn.doPrivMsg(inChannel ? target : user.nick, (inChannel?user.nick + ": " : "") + e); 
		}
	}
	static function numericHandler(number : Int, server : String, line : String)
	{
		// NOTE: most of these are optimized for rizon, edit for your own needs
		// enough for now
		var split = line.split(" ");
		switch (number) 
		{
			case IRCReplies.RPL_WELCOME:
				for (i in ircSettings.autojoin_channels) 
					conn.doJoin(i);
				if (ircSettings.auth_nick != "@@noauth") 
					conn.doPrivMsg(ircSettings.auth_nick, ircSettings.auth_command + " " + ircSettings.auth_password);
			case IRCReplies.RPL_TOPIC: // first is nick, second channel name, third is topic with colon, at least on 
				if (channels.keys().has(split[1]))   //errything, joined by " ", remove semicolon
					channels.get(split[1]).topic = split.slice(2).join(" ").substr(1);
			case IRCReplies.RPL_NOTOPIC:
				if (channels.keys().has(split[1])) 
					channels.get(split[1]).topic = "No topic set for " + split[1];
			case IRCReplies.RPL_TOPICWHOTIME:
				if (channels.keys().has(split[1])) 
					channels.get(split[1]).topic_setby = { user:split[2], timestamp:Std.parseInt(split[3]) }; // this could be logged channel wise... how about i make events for every parsed event? :O
			case IRCReplies.RPL_NAMEREPLY:
				if (channels.keys().has(split[2])) // also done
				{
					var names = split.slice(3);
					names[0] = names[0].substr(1);
					for (i in names) 
					{
						var nick = ChannelUser.modesigns.contains(i.charAt(0)) ? i.substr(1) : i; // this is pretty darn slow beacause we look through the entire user list every time OR we could sacrifice this and risk that user list falls out of sync, maybe implement checking sync loop?
						if (!channels.get(split[2]).hasUser(nick))	channels.get(split[2]).users.push(new ChannelUser(new IRCUser(nick))); // Whoa.
					}
				}
			case IRCReplies.RPL_WHOREPLY:						// i can't believe this two shit actually works and channels are in sync (APPARENTLY IT'S BROKEN SOMEWHERE, LOL)
				var mode = 0;
				if (split[6].length > 1) // thefuck is the H?
					mode = (1 << ChannelUser.modesigns.indexOf(split[6].substr(1)));
				if (split[2].charAt(0) == "~") 
					split[2] = split[2].substr(1);
				// 0: own nick, 1: channel, 2: name with ident tilde, 3: hostname, 4: *????, 5: nick, 6: H<chanmode> 7: :0, 8-: the rest is realname
				channels.get(split[1]).setUserByNick(split[5], split[2], split[3], split.slice(8).join(" "), mode); 
			default:
				//Lib.println("default NUM: " + number + " LINE:" + line);
		}
	}
	
	// TODO: fix this, and in the irc implementation as well
	static function ctcpHandler(user : IRCUser, line : String)
	{
		Lib.println("CTCP REQUEST FROM: " + user.nick + " COMMAND: " + line);
		switch (line)
		{
			case "VERSION":
				conn.doCTCP(user.nick, "VERSION koneko-chan by andor/nef"); //should suffice for now, i shoulda wrap my head around reloading modules
			case "TIME":
				conn.doCTCP(user.nick, "TIME " + Date.now().toString()); 
			default:
				Lib.println("Unknown CTCP from '" + user.toString() + "' line: " + line);
		}
	}
	
	static function nickHandler(user : IRCUser, newnick : String)
	{
		for (i in channels) 
		{
			if (i.hasUser(user.nick)) 
				i.getUserByNick(user.nick).nick = newnick;
		}
	}
	
	static function quitHandler(user : IRCUser, reason : String)
	{
		for (i in channels) 
		{
			if (i.hasUser(user.nick)) 
			{
				i.users.remove(i.getUserByNick(user.nick));
			}
		}
	}
	
	static function kickHandler(kicker : IRCUser, chan : String, nick : String, reason : String)
	{
		if (ircSettings.autorejoin_enabled && (conn.myself.nick == nick)) 
		{
			conn.doJoin(chan);
		}
	}
	
	static function resync(channel : String = "all")
	{
		if (channel == "all") 
		{
			// BUG: do not use, causes floodkick on most servers
			for (i in channels) // let's hope this'll put an end to random quits for now >:(
			{
				i.users = new Array<ChannelUser>();
				conn.doRaw("NAMES " + i.name);
				conn.doRaw("WHO " + i.name);
			}
		}
		else
		{
			switch (channel.charAt(0)) 
			{
				case "#", "&":
					channels.get(channel).users = new Array<ChannelUser>();
					conn.doRaw("NAMES " + channel);
					conn.doRaw("WHO " + channel); 
				default:
					return;
			}
		}
	}

	static function load_module(name : String) : IRCPlugin
	{
		var loader = Loader.local();
		loader.addPath(Sys.getCwd());
		loader.addPath(Sys.executablePath());
		var modname = name; var modcache = loader.getCache(); var old_path = ""; var new_path = "";
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
		
		for (i in Reflect.fields(classes)) 
		{
			if (i == "IRCPlugin") continue;
			try 
			{
				var class_proto = Reflect.field(classes, i);
				if (Type.getClassName(Type.getSuperClass(class_proto)) == "IRCPlugin") 
					return Type.createInstance(class_proto, []);
			}
			catch (e: Dynamic) { }
		}
		trace("Error! Module '" + modname + "' contains no IRC plugin class.");
		return null;
	}
	
	static function die(message : String)
	{
		trace(message);
		Sys.exit(1);
	}
	
	static function main() 
	{
		if (Sys.args().length >= 1) // did the user specify a config file?
		{
			if (FileSystem.exists("./" + Sys.args()[0]))
			{
				try 
				{
					var filename = Sys.args()[0];
					if (Path.extension(filename) == "koneko") // serialized config file
					{
						trace("Loading serialized config file");
						ircSettings = SettingsParser.unserialize_config(filename);
					}
					else if (Path.extension(filename) == "conf" || Path.extension(filename) == "json")
					{
						trace("Parsing config file");
						var parser = new SettingsParser(filename);
						ircSettings = parser.run_parser();
					}
					else
						die("Unknown file format, quitting");
				}
				catch (e : Dynamic)
				{
					die("Error in config file. Check your syntax or see if your file is a valid config file.");
				}
			}
			else
				die("Specified config file doesn't exist, quitting");
		}
		else // nah, try to load a default config
		{
			if (!FileSystem.exists("settings.koneko")) 
				die("No config file specified and no default config file found, quitting");
			try 
			{
				ircSettings = SettingsParser.unserialize_config("settings.koneko");
			}
			catch (e : Dynamic)
				die("Invalid default config file");
		}
		
		if (!SettingsParser.validate_config(ircSettings)) 
			die("Invalid config file or missing default parameters");
		
		var config_subdir = config_dir + "/" + ircSettings.server_address + "_" + ircSettings.nicks[0];
		
		if (!FileSystem.exists(config_dir)) 
			FileSystem.createDirectory(config_dir);
		
		if (!FileSystem.exists(config_subdir))
			FileSystem.createDirectory(config_subdir);
		
		if (!FileSystem.exists(config_subdir)) // i think neko throws an exception when it can't write a directory, but let's be safe
			die("Unable to write directory '" + config_subdir + "'. Exiting"); // maybe i should make this graceful like module loading?
		
		modules = new Hash<IRCPlugin>();
		users = if (FileSystem.exists(config_subdir + "/" + "owners.dat")) 
					Unserializer.run(File.getContent(config_subdir + "/" + "owners.dat")); 
				else 
					new Hash<UserInfo>();
		accessSettings = if (FileSystem.exists(config_subdir + "/" + "access_settings.dat"))
							Unserializer.run(File.getContent(config_subdir + "/" + "access_settings.dat"));
						else 
							new AccessSettings();
		channels = new Hash<Channel>();
		
		for (i in ircSettings.autoload_modules) 
		{
			var module : IRCPlugin = null;
			try 
			{
				module = load_module(i);
			}
			catch (e : Dynamic)
			{
				trace("Couldn't load module '" + i + "', going on...");
			}
			modules.set(module.name, module);
		}
		
		conn = new irc.IRCSocket(new Host(ircSettings.server_address), ircSettings.server_port, new IRCUser(ircSettings.nicks[0], ircSettings.name, ircSettings.realname, "koneko"));
		
		// replacing inline function definitions because they seem to break autocompletion in FD4 :(
		conn.onRaw = rawHandler;
		conn.onJoin = joinHandler;
		conn.onCTCP = ctcpHandler;	
		conn.onPrivMsg = privMsgHandler;
		conn.onPart = leaveHandler;
		conn.onNumericEvent = numericHandler;
		conn.onNick = nickHandler;
		conn.onQuit = quitHandler;
		conn.onKick = kickHandler;
		
		conn.start();
		
		while (conn.isConnected)
		{
			try 
			{
				conn.listen(); // magic
			}
			catch(e : Dynamic)
			{
				// Server dropped connection, shikatanai
				// TODO: implement reconnect mechanism
				if (Std.string(e).contains("EOF")) 
					break;
				Lib.println("OHSHI- " + e);
			}
		}
		
		var serializedOwners = Serializer.run(users);
		var ownersWriter = File.write(config_subdir + "/" + "owners.dat", false);
		ownersWriter.writeString(serializedOwners);
		ownersWriter.close();
		
		var serializedAccess = Serializer.run(accessSettings);
		var accessWriter = File.write(config_subdir + "/" + "access.dat", false);
		accessWriter.writeString(serializedAccess);
		accessWriter.close();
		
		Lib.println("it's over, i can rest finally");
	}
	public static function identify (name:String, pwd:String) : Int
	{
		if (!users.exists(name))
			return 1; // no such user
		
		pwd = Md5.encode(pwd);
		if (pwd == users.get(name).password)
			return 0; // gotcha
		else return 2; // wrong pw
	}
	public static function setAccess (name:String, access:Int) : Int
	{
		if (users.exists(name))
		{	
			users.get(name).access = access;
			return 0; // success
		}
		return 1; // no such user
	}
	public static function getAccess (host:String) : Int
	{
		for (i in users)
		{
			if (i.hosts.has(host))
				return i.access;
		}
		return 0;
	}
	public static function contains (val:String, what:String) : Bool
	{
		return val.split(what).length > 1;
	}
	
	public static function has (iter : Iterator<Dynamic>, o : Dynamic) : Bool
	{
		for (i in iter) if (i == o) return true;
		return false;
	}
}