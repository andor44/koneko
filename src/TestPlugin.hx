package ;

import irc.IRCSocket;
import IRCPlugin;

/**
 * ...
 * @author Andor
 */
 
class TestHerpDerp extends IRCPlugin
{
	public function new ()
	{
		super();
		name = "testplugin";
		accessLevel = 0;
		trigger = Trigger.Privmsg;
	}
	public override function getResult(sender:IRCUser, me:IRCUser, sock:IRCSocket, message:String, target:String) : Void
	{
		if (message.charAt(0) == "a") 
		{
			sock.doPrivMsg(target, "herpderp");
		}
	}
}