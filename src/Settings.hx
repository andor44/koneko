package ;

/**
 * ...
 * @author Andor
 */

class Settings 
{
	public var nicks : Array<String>;
	public var name : String;
	public var realname : String;
	public var auth_nick : String;
	public var auth_command : String;
	public var auth_password : String;
	public var server_address : String;
	public var server_port : Int;
	public var autorejoin_enabled : Bool;
	public var claim : String;
	
	public var autojoin_channels : Array<String>;
	public var autoload_modules : Array<String>;
	
	public function new() 
	{
		nicks = new Array<String>();
		autojoin_channels = new Array<String>();
		autoload_modules = new Array<String>();
		autorejoin_enabled = false;
		name = new String("");
		realname = new String("");
		auth_nick = new String("");
		auth_command = new String("");
		server_address = new String("");
		server_port = 6667;
		claim = new String("");
	}
	
}