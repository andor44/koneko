package ;

import irc.IRCSocket;

/*
 * ...
 * @author Andor
 */


// TODO: store channel modes? not that relevant really, but whatever
class Channel
{
	// we _do_ store the hash sign here
	public var name : String;
	public var users : Array<ChannelUser>;
	public var topic : String;
	public var topic_setby : { user : String, timestamp : Int }; // not ircuser, because... i don't know, and Int timestamp should suffice
	public function new(name : String)
	{
		this.name = name;
		this.users = new Array<ChannelUser>(); // chances are we don't get the user list on join right away :( maybe intialize instance after complete channel sync? saa ne
		this.topic = ""; // same deal, except topic can be empty, but whatever
	}
	//public function setUserByNick(nick : String, name : String = "", hostname : String = "", realname : String = "")
	// BUG: reimplement ALL of this, it's not very dynamic and it'll get very messy later

	public function setUserByNick(nick : String, name : String = "", hostname : String = "", realname : String = "", mode : Int)
	{
		for (i in users) 
		{
			if (i.nick == nick) 
			{
				
				i.name = name;
				i.host = hostname;
				i.realname = realname;
				i.mode = mode;
			}
		}
		
	}
	public function getUserByNick(nick : String) : Null<ChannelUser> // whatever
	{
		for	(i in users)
		{
			if (i.nick == nick) return i;
		}
		return null;
	}
	public function hasUser(nick : String) : Bool 
	{
		for (i in users) 
		{
			if (i.nick == nick) return true;
		}
		return false;
	}
}

class ChannelUser extends IRCUser
{
	public static var modesigns = "+%@&~"; // voice, halfop, op, protected, channel owner/creator (only voice, and op are part of the specification)
	public static var modechars = "vhoaq "; // check'd
	public static var MODE_VOICE = 		1;
	public static var MODE_HALFOP =		1 << 1;
	public static var MODE_OP =			1 << 2;
	public static var MODE_PROTECTED =	1 << 3;
	public static var MODE_OWNER =		1 << 4; // looks good i guess ? wait actually, i think that's protected... duh :( i'll figure out when i have internets again ~_~
	
	public var mode : Int;
	public function new(user : IRCUser) // copy ctor
	{
		super(user.nick); // seriously? 
		this.nick = user.nick;
		this.name = user.name;
		this.host = user.host;
		this.realname = user.realname;
	}
	
	public function getHighest() : String
	{
		if (mode == 0) return "";
		if (mode >= MODE_OWNER) return modesigns.charAt(4);
		if (mode >= MODE_PROTECTED) return modesigns.charAt(3);
		if (mode >= MODE_OP) return modesigns.charAt(2);
		if (mode >= MODE_HALFOP) return modesigns.charAt(1);
		if (mode >= MODE_VOICE) return modesigns.charAt(0);
		return ""; // shouldn't be possible but whatever
	}
	public override function toString() : String
	{
		return this.getHighest() + nick + "!" + name + "@" + host;
	}
}