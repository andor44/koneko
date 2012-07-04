package ;

/**
 * ...
 * @author Andor
 */

import haxe.Serializer;
import haxe.Unserializer;
import neko.FileSystem;
import neko.io.File;
import Settings;

using StringTools;

class SettingsParser 
{
	var filename : String;
	public function new(filename : String) 
	{
		this.filename = filename;
	}
	
	public function run_parser() : Settings
	{
		var settings = new Settings();
		var file_contents = File.getContent(filename);
		if (file_contents.indexOf("\r\n") > 0) 
			file_contents.replace("\r\n", "\n"); // because fuck line endings :(
		for (i in file_contents.split("\n")) 
		{
			if (i.charAt(i.length-1) == "\r" || i.charAt(i.length-1) == "\n") // god i sure hate line endings
				i = i.substr(0, i.length - 1); // something about line endings too, ┐('～`；)┌
			
			if (i.length == 0 && i.charAt(0) == '//') continue; // empty line or entire line is comment
			if (i.indexOf("//") > 0) 
				i = i.substr(0, i.indexOf("//")); // line contains a comment
			var split = i.split(" ");
			switch (split[0]) 
			{
				case "nicks":
					for (i in split.slice(1)) 
						settings.nicks.push(i);
				case "name":
					settings.name = split[1];
				case "realname":
					settings.name = split.slice(1).join(" ");
				case "auth_nick":
					settings.auth_nick = split[1];
				case "auth_command":
					settings.auth_command = split.slice(1).join(" ");
				case "auth_password":
					settings.auth_password = split[1];
				case "server_address":
					settings.server_address = split[1];
				case "server_port":
					var port = Std.parseInt(split[1]);
					settings.server_port = port == null ? 6667 : port;
				case "autojoin_channels":
					for (i in split.slice(1)) 
						settings.autojoin_channels.add(i);
				case "autoload_modules":
					for (i in split.slice(1)) 
						settings.autoload_modules.add(i);
				case "autorejoin_enabled":
					if (split[1] == "true" || split[1] == "yes")
						settings.autorejoin_enabled = true; // defaults to false in config file
				case "claim":
					settings.claim_pw = split[1];
				default:
					trace("unknown config variable '" + split[0] + "', skipping");
			}
		}
		return settings;
	}
	public static function validate_config(settings : Settings) : Bool
	{
		if (settings.nicks.length <= 0) 
			return false; // not enough default nicks 
		if (settings.name == null || settings.name == "") 
			return false; // empty name
		if (settings.realname == null) 
			settings.realname = ""; // realname can be empty, but let's initialize the var to make sure it's good
		if (settings.auth_nick != null && settings.auth_nick != "") // the user DID specify a nick to auth to, let's see if the rest of the auth params are good, otherwise don't bother
		{
			if (settings.auth_command == null) // maybe it requires no special params 
				settings.auth_command = ""; 
			if (settings.auth_password == null || settings.auth_password == "") 
				return false;
		}
		else
			settings.auth_nick = "@@noauth";
		if (settings.server_address == null || settings.server_address == "") 
			return false;
		if (settings.server_port > 65536 || settings.server_port < 0) 
			settings.server_port = 6667;
		
		
		//autojoin channels/modules needn't be validated
		return true; // config good, ready to run
	}
	public static function serialize_config(settings : Settings, filename : String = "settings.koneko")
	{
		var serializedSettings = Serializer.run(settings);
		var settingsWriter = File.write(filename, false);
		settingsWriter.writeString(serializedSettings);
		settingsWriter.close();
	}
	public static function unserialize_config(filename : String = "settings.koneko") : Settings
	{
		if (!FileSystem.exists(filename)) throw "no such file";
		return Unserializer.run(File.getContent(filename));
	}
}