package ;

/**
 * ...
 * @author Andor
 */

class AccessSettings 
{
	public var loadmod_access : Int;
	public var listmodules_access : Int;
	public var adduser_access : Int;
	public var join_access : Int;
	public var nick_access : Int;
	public var raw_access : Int;
	public var part_access : Int;
	public var quit_access : Int;
	public var say_access : Int;
	public var listchans_access : Int;
	public var resync_access : Int;
	public var writeconf_access : Int;
	
	public function new()
	{
		loadmod_access = 10;
		listmodules_access = 10;
		adduser_access = 10;
		join_access = 4;
		nick_access = 4;
		raw_access = 10;
		part_access = 4;
		quit_access = 10;
		say_access = 10;
		listchans_access = 5;
		resync_access = 10;
		writeconf_access = 10;
	}
}