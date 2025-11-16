package;

#if DISCORD_ALLOWED
#if cpp
import cpp.ConstCharStar;
import cpp.Function;
import cpp.RawConstPointer;
#end

import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types;
import lime.app.Application;
import sys.thread.Thread;


class DiscordClient
{
	public static var isInitialized:Bool = false;
	private inline static final _defaultID:String = "1192736165472784445";
	public static var clientID(default, set):String = _defaultID;
	private static var presence:DiscordRichPresence = new DiscordRichPresence(); // I think for now we don't need DiscordPresence.create();
	// hides this field from scripts and reflection in general
	@:unreflective private static var __thread:Thread;
	private static var closeHandlerRegistered:Bool = false;

	public static function check()
	{
		if(ClientPrefs.discordRPC) initialize();
		else if(isInitialized) shutdown();
	}

	public static function prepare()
	{
		if (!isInitialized && ClientPrefs.discordRPC)
			initialize();

		if (!closeHandlerRegistered)
		{
			closeHandlerRegistered = true;
			Application.current.window.onClose.add(function() {
				if(isInitialized) shutdown();
			});
		}
	}

	public dynamic static function shutdown()
	{
		isInitialized = false;
		Discord.Shutdown();
	}

	private static function onReady(request:RawConstPointer<DiscordUser>):Void
	{
		final user = cast (request[0].username, String);
		final discriminator = cast (request[0].discriminator, String);

		var message = '(Discord) Connected to User ';
		if (discriminator != '0') //Old discriminators
			message += '($user#$discriminator)';
		else //New Discord IDs/Discriminator system
			message += '($user)';

		trace(message);
		changePresence();
	}

	private static function onError(errorCode:Int, message:ConstCharStar):Void
	{
		trace('Discord: Error ($errorCode: ${cast(message, String)})');
	}

	private static function onDisconnected(errorCode:Int, message:ConstCharStar):Void
	{
		trace('Discord: Disconnected ($errorCode: ${cast(message, String)})');
	}

	public static function initialize()
	{
		final discordHandlers:DiscordEventHandlers = #if (hxdiscord_rpc > "1.2.4") new DiscordEventHandlers(); #else DiscordEventHandlers.create(); #end
		discordHandlers.ready = Function.fromStaticFunction(onReady);
		discordHandlers.disconnected = Function.fromStaticFunction(onDisconnected);
		discordHandlers.errored = Function.fromStaticFunction(onError);
		Discord.Initialize(clientID, cpp.RawPointer.addressOf(discordHandlers), #if (hxdiscord_rpc > "1.2.4") false #else 1 #end, null);

		if(!isInitialized) trace("Discord Client initialized");

		if (__thread == null)
		{
			__thread = Thread.create(() ->
			{
				while (true)
				{
					if (isInitialized)
					{
						#if DISCORD_DISABLE_IO_THREAD
						Discord.UpdateConnection();
						#end
						Discord.RunCallbacks();
					}

					// Wait 1 second until the next loop...
					Sys.sleep(1.0);
				}
			});
		}
		isInitialized = true;
	}

	public static function changePresence(details:String = 'Jaime te persige...', ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Null<Float>, largeImageKey:String = 'icon')
	{
		var startTimestamp:Float = (hasStartTimestamp == true) ? Date.now().getTime() : 0;
		var endTimestampValue:Float = 0;
		if (endTimestamp != null && endTimestamp > 0)
		{
			if (startTimestamp <= 0)
				startTimestamp = Date.now().getTime();
			endTimestampValue = startTimestamp + endTimestamp;
		}

		presence.state = state;
		presence.details = details;
		presence.smallImageKey = smallImageKey;
		presence.largeImageKey = largeImageKey;
		presence.largeImageText = "SR Engine Version: " + MainMenuState.psychEngineJSVersion;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		presence.startTimestamp = startTimestamp > 0 ? Std.int(startTimestamp / 1000) : 0;
		presence.endTimestamp = endTimestampValue > 0 ? Std.int(endTimestampValue / 1000) : 0;

		final button:DiscordButton = new DiscordButton();
		button.label = "SR Engine Source Code";
		button.url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
		presence.buttons[0] = button;
		updatePresence();
	}

	public static function updatePresence()
	{
		if (!isInitialized)
			return;
		Discord.UpdatePresence(RawConstPointer.addressOf(presence));
	}

	inline public static function resetClientID()
	{
		clientID = _defaultID;
	}

	private static function set_clientID(newID:String)
	{
		var change:Bool = (clientID != newID);
		clientID = newID;

		if(change && isInitialized)
		{
			shutdown();
			initialize();
			updatePresence();
		}
		return newID;
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State)
	{
		Lua_helper.add_callback(lua, "changeDiscordPresence", changePresence);
		Lua_helper.add_callback(lua, "changeDiscordClientID", function(?newID:String) {
			if(newID == null) newID = _defaultID;
			clientID = newID;
		});
	}
	#end
}
#end
