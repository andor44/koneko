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
	public var claim_pw : String;
	
	public var autojoin_channels : List<String>;
	public var autoload_modules : List<String>;
	
	public function new() 
	{
		nicks = new Array<String>();
		autojoin_channels = new List<String>();
		autoload_modules = new List<String>();
		autorejoin_enabled = false;
	}
	
}