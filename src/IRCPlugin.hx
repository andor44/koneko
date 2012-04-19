package ;

import irc.IRCSocket;

/**
 * ...
 * @author Andor
 */

enum Trigger
{
	Privmsg;
	CTCP;
	Join;
	Topic;
	Part;
	Quit;
	Raw;
	Nick;
}
 
class IRCPlugin 
{
	public function new ()
	{
		
	}
	public var trigger : Trigger;
	public var name : String;
	public var accessLevel : Int;
	public function getResult(sender:IRCUser, me:IRCUser, sock:IRCSocket, message:String, target:String) : Void
	{
	
	}
}