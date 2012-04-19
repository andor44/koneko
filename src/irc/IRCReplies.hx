package irc;

/**
 * ...
 * @author Andor
 */

class IRCReplies
{
	public static var RPL_WELCOME 	= 	001;
	public static var RPL_YOURHOST 	= 	002;
	public static var RPL_CREATED 	= 	003;
	public static var RPL_MYINFO 	=	004;
	public static var RPL_BOUNCE 	=	005;
	public static var RPL_USERHOST 	= 	302;
	public static var RPL_ISON		=	303;
	public static var RPL_AWAY		=	301;
	public static var RPL_UNAWAY	=	305;
	public static var RPL_NOWAWAY	=	306;
	public static var RPL_WHOISUSER	=	311;
	public static var RPL_WHOISSERVER	=	312;
	public static var RPL_WHOISOPERATOR	=	313;
	public static var RPL_WHOISIDLE	=	317;
	public static var RPL_ENDOFWHOIS	=	318;
	public static var RPL_WHOISCHANNELS	=	319;
	public static var RPL_WHOWASUSER	=	314;
	public static var RPL_ENDOFWHOWAS	=	369;
	public static var RPL_LISTSTART	=	321; // RFC says obsolete?
	public static var RPL_LIST		=	322;
	public static var RPL_LISTEND	=	323;
	public static var RPL_UNIQOPIS	=	325;
	public static var RPL_CHANNELMODEIS	=	324;
	public static var RPL_NOTOPIC	=	331;
	public static var RPL_TOPIC		=	332;
	public static var RPL_TOPICWHOTIME =	333; // on Rizon (and probably most modern ircds)
	public static var RPL_INVITING	=	341;
	public static var RPL_SUMMONING	=	342; // what is this, warcraft!?
	public static var RPL_INVITELIST	=	346;
	public static var RPL_ENDOFINVITELIST	=	347;
	public static var RPL_EXCEPTLIST	=	348;
	public static var RPL_ENDOFEXCEPTLIST	=	349;
	public static var RPL_VERSION	=	351;
	public static var RPL_WHOREPLY	=	352;
	public static var RPL_ENDOFWHO	=	315;
	public static var RPL_NAMEREPLY	=	353;
	public static var RPL_ENDOFNAMES	=	366;
	public static var RPL_LINKS		=	364;
	public static var RPL_ENDOFLINKS	=	365;
	public static var RPL_BANLIST	=	367;
	public static var RPL_ENDOFBANLIST	=	368;
	public static var RPL_INFO		=	371;
	public static var RPL_ENDOFINFO	=	374;
	public static var RPL_MOTDSTART	=	375;
	public static var RPL_MOTD		=	372;
	public static var RPL_ENDOFMOTD	=	376;
	public static var RPL_YOUREOPER	=	381; // welcome to the twilight zone :p
	public static var RPL_REHASHING	=	382;
	public static var RPL_YOURESERVICE	=	383;
	public static var RPL_TIME		=	391;
	public static var RPL_USERSSTART	=	392;
	public static var RPL_USERS		=	393;
	public static var RPL_ENDOFUSERS	=	394;
	public static var RPL_NOUSERS	=	395;
	public static var RPL_TRACELINK	=	200;
	public static var RPL_TRACECONNECTING	=	201;
	public static var RPL_TRACEHANDSHAKE	=	202;
	public static var RPL_TRACEUNKNOWN	=	203;
	public static var RPL_TRACEOPERATOR	=	204;
	public static var RPL_TRACEUSER	= 205;
	public static var RPL_TRACESERVER	=	206;
	public static var RPL_TRACESERVICE	=	207;
	public static var RPL_TRACENEWTYPE	=	208;
	public static var RPL_TRACECLASS	=	209;
	public static var RPL_TRACECONNECT	=	210; // unused?
	public static var RPL_TRACELOG	=	261;
	public static var RPL_TRACEEND	=	262;
	public static var RPL_STATSLINKINFO	=	211;
	public static var RPL_STATSCOMMANDS	=	212;
	public static var RPL_ENDOFSTATS	=	219;
	public static var RPL_STATSUPTIME	=	242;
	public static var RPL_STATSOLINE	=	243;
	public static var RPL_UMODEIS	=	221;
	public static var RPL_SERVLIST	=	234;
	public static var RPL_SERVLISTEND	=	235;
	public static var RPL_LUSERCLIENT	=	251;
	public static var RPL_LUSERHOP	=	252;
	public static var RPL_LUSERUNKNOWN	=	253;
	public static var RPL_LUSERCHANNEL	=	254;
	public static var RPL_LUSERME	=	255;
	public static var RPL_ADMINME	=	256;
	public static var RPL_ADMINLOC1	=	257;
	public static var RPL_ADMINLOC2	=	258;
	public static var RPL_ADMINEMAIL	=	259;
	public static var RPL_TRYAGAIN	=	263; // YEAH I DID IT
}