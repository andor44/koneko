package irc;

import neko.net.Host;
import neko.net.Poll;
import neko.net.Socket;

/**
 * A sloppy RFC 1459 implementation
 * Use with care, stuff may break with or without warning
 * Licensed under the (old) 4 clause BSD license, which is attached in the LICENSE file. If you did not receive one with
 * this file, please refer to http://en.wikipedia.org/wiki/BSD_licenses (4-clause license (original "BSD License")) 
 * NOTE: I'm quite new to haxe, and this code is very immature, also, it's not catching any exceptions, that's left to you
 * 
 * @author Andor
 */

class IRCUser
{
	public var nick : String;
	public var name : String;
	public var realname : String;
	public var host : String;
	
	public function new (nick:String, name:String = "", realname:String = "", host:String = "")
	{
		this.nick = nick;
		if (name != "") this.name = name;
		if (realname != "") this.realname = realname;
		this.host = host;
	}
	
	public function toString() : String
	{
		return nick + "!" + name + "@" + host;
	}
}

class IRCSocket
{
	// endline character required by RFC1459 :(
	private static var ENDL : String = "\r\n";
	
	// internal stuff
	private var send_queue : Array<String>;
	private var timeout : Float;
	private var serverData : { server:Host, port:Int };
	private var sock : Socket;
	private var modebits : Int;
	
	public var myself : IRCUser;
	// "events" NOTE: irc handles channel messages as privmsgs (their recepient is a channel instead of a usr)
	public var onRaw : String -> Void;
	public var onNumericEvent : Int -> String -> String -> Void; // event num -> server name -> message
	public var onPrivMsg : IRCUser -> String -> String -> Void; // user, channel, message
	public var onTopic : IRCUser -> String -> String -> Void; // user, channel, new topic
	public var onPing : String -> Void; // NOTE: this is server ping, CTCP ping handling is currently not part of this library
	public var onCTCP : IRCUser -> String -> Void;
	public var onJoin : IRCUser -> String -> Void;
	public var onPart : IRCUser -> String -> String -> Void;
	public var onQuit : IRCUser -> String -> Void;
	public var onNick : IRCUser -> String -> Void;
	public var onKick : IRCUser -> String -> String -> String -> Void;
	
	public var isConnected : Bool;
	public var autoPing : Bool; // determines wheter we do auto ping reply

	public function new(ircserver:Host, port:Int, me:IRCUser, modebits:Int = 0 , ?autoping:Bool = true, ?network_timeout = 1.0) 
	{				
		myself = me;
		send_queue = new Array<String>();
		timeout = network_timeout;
		serverData = { server:ircserver, port:port };
		sock = new Socket();
		isConnected = false;
		autoPing = autoping;
		this.modebits = modebits;
	}
	public function start() : Void
	{
		sock.connect(serverData.server, serverData.port);
		register();
		isConnected = true;
	}
	public function register(details : IRCUser = null, modebits : Int = null) : Void
	{
		if (details == null) 
			details = myself;
		if (modebits == null) 
			modebits = this.modebits;
		
		sock.output.writeString("NICK " + details.nick + ENDL);
		sock.output.writeString("USER " + details.nick + " " + Std.string(modebits) + " " + details.nick + " :" + details.realname + ENDL); // RFC says the server and host params are unimportant (in client mode?)
	}
	public function listen() : Void
	{
		if (!isConnected) return; // no exceptions (okay, this is a horrible pun)
		
		// continously read socket, and send if we have something in the send buffer, then call the necessary methods, null/sanity check yay!
		send_queue.reverse(); // eh, the first message should be sent first
		while (send_queue.length > 0)
			sock.output.writeString(send_queue.pop());
		Socket.select([sock], [sock], null, timeout);
		var line = sock.input.readLine(); // if (StringTools.isEOF(line.charCodeAt(0))) connection broken??? should be handled by the user
		
		if (onRaw != null)
			onRaw(line.toString());
		
		switch (getAction(line))
		{
			case "PRIVMSG":
				if (onPrivMsg != null)
				{
					var split = line.split(" ");
					var user = split[0].substr(1); // let's remove the colon
					var target = split[2];
					var message = split.slice(3).join(" "); // the message could be possibly empty, causing an exception here, too bad
					if ((message.charCodeAt(1) == 1) && (message.charCodeAt(message.length - 1) == 1)) // CTCP messages start and end with a \001
						onCTCP(new IRCUser(user.split("!")[0], user.split("!")[1].split("@")[0], null, user.split("@")[1]), message.substr(2, message.length - 3));
					else
						onPrivMsg(new IRCUser(user.split("!")[0], user.split("!")[1].split("@")[0], null, user.split("@")[1]), target, message.substr(1)); // msg begins with a colon
				}
			case "JOIN":
				if (onJoin != null)
				{
					var split = line.split(" ");
					var user = split[0].substr(1);
					var channel = split[2].substr(1); // son of a...
					onJoin(new IRCUser(user.split("!")[0], user.split("!")[1].split("@")[0], null, user.split("@")[1]), channel); // BUG: throws Segmentation fault originating from external C function on random, don't know what's causing it
				}
			case "QUIT":
				if (onQuit != null)
				{
					var split = line.split(" ");
					var user = split[0].substr(1);
					var reason = split[2].substr(1);
					onQuit(new IRCUser(user.split("!")[0], user.split("!")[1].split("@")[0], null, user.split("@")[1]), reason);
				}
			case "NICK":
				if (onNick != null)
				{
					var split = line.split(" ");
					var user = split[0].substr(1);
					var newnick = split[2].substr(1);
					onNick(new IRCUser(user.split("!")[0], user.split("!")[1].split("@")[0], null, user.split("@")[1]), newnick); 
				}
			case "PART":
				if (onPart != null)
				{
					var split = line.split(" ");
					var user = split[0].substr(1);
					var channel = split[2];
					var reason : String = "";
					if (split.length >= 4) reason = split.slice(3).join(" ");
					onPart(new IRCUser(user.split("!")[0], user.split("!")[1].split("@")[0], "", user.split("@")[1]), channel, reason); // BUG: same as join bug, i've yet to trace this bug
				}
			case "TOPIC":
				if (onTopic != null)
				{
					var split = line.split(" ");
					var user = split[0].substr(1);
					var channel = split[2];
					var topic = split.slice(3).join(" ").substr(1);
					onTopic(new IRCUser(user.split("!")[0], user.split("!")[1].split("@")[0], null, user.split("@")[1]), channel, topic);
				}
			case "KICK":
				if (onKick != null) 
				{
					var split = line.split(" ");
					var kicker_pre = split[0].substr(1);
					var kicker = new IRCUser(kicker_pre.split("!")[0], kicker_pre.split("!")[1].split("@")[0], null, kicker_pre.split("@")[1]);
					var chan = split[2];
					var nick = split[3];
					var reason = split.slice(4).join(" ").substr(1);
					onKick(kicker, chan, nick, reason);
				}
			default:
				var numericReply = getNumericReply(line);
				if (numericReply != null && numericReply != 0 && onNumericEvent != null)
				{
					var split = line.split(" "); //no, we're never calling it twice! and we're nice and remove that colon
					onNumericEvent(numericReply, split[0], split.slice(2).join(" "));
				}
		}
		
		if (StringTools.startsWith(line, "PING")) // ping reply, who wants a library that drops itself!? 
		{
			if (autoPing)
				send_queue.push("PONG " + line.split(" ")[1] + ENDL);
			if (onPing != null)
				onPing(line.split(" ")[1]);
		}
	}
	public function doCTCP(target:String, command:String)
	{
		send_queue.push("NOTICE " + target + " :" + String.fromCharCode(1) + command + String.fromCharCode(1) + ENDL); 
	}
	public function doNotice(target:String, msg:String)
	{
		send_queue.push("NOTICE " + target + " " + msg + ENDL);
	}
	public function doNames(chan:String = "")
	{
		send_queue.push("NAMES " + chan + ENDL);
	}
	public function doChanMode(chan:String, modes:String, modeParams:String = "")
	{
		send_queue.push("MODE " + chan + " " + modes + " " + modeParams + ENDL);
	}
	public function doUserMode(nick:String, modes:String) // NOTE: this function is kind of obsolete in "modern" irc
	{
		send_queue.push("MODE " + nick + " " + modes + ENDL);
	}
	public function doPass(password:String)
	{
		send_queue.push("PASS " + password + ENDL);
	}
	public function doOper(name:String, password:String)
	{
		send_queue.push("OPER " + name + " " + password + ENDL);
	}
	public function doInvite(nick:String, channel:String)
	{
		send_queue.push("INVITE " + nick + " " + channel + ENDL);
	}
	public function doKick(nick:String, channel:String, ?reason:String)
	{
		send_queue.push("KICK " + channel + " " + nick + (reason != null ? " :" + reason : "") + ENDL); 
	}
	public function doNick(newnick:String) : Void
	{
		send_queue.push("NICK " + newnick + ENDL);
	}
	public function doTopic(channel:String, ?newtopic:String) // NOTE: not using = "" because one may want to set an empty topic, so pass null if you want to get the topic
	{
		send_queue.push("TOPIC " + channel + (newtopic != null ? " :" + newtopic : "") + ENDL); // fix'd, it would've attemped something else
	}
	public function doPrivMsg(target:String, msg:String)
	{
		send_queue.push("PRIVMSG " + target + " :" + msg + ENDL);
	}
	public function doPart(channel:String) : Void // many servers support a part message, but this is not part of this library (just do channel = "#channel :reason")
	{
		send_queue.push("PART " + channel + ENDL);
	}
	public function doJoin(channel:String, ?key:String) : Void
	{
		if (key != null && key.length > 0)
			send_queue.push("JOIN " + channel + " " + key + ENDL);
		else
			send_queue.push("JOIN " + channel + ENDL);
	}
	public function doQuit(message:String = " : IRCHax by andor") : Void // it somehow fixed itself :o
	{
		sock.output.writeString("QUIT :" + message + "\r\n");
		sock.output.flush();
		sock.close();
		isConnected = false;
	}
	public function doRaw(rawLine:String)
	{
		send_queue.push(rawLine + ENDL);
	}
	// some internal tools, they're not exactly pretty, but i saw no haxe implementation for them
	private static function contains (val:String, what:String) : Bool
	{
		return val.split(what).length > 1;
	}
	private static function getAction(line:String) : String
	{
		return line.split(" ")[1];
	}
	private static function getNumericReply(line:String) : Null<Int>
	{
		return Std.parseInt(line.split(" ")[1]);
	}
}