package utils;

/*
    This is some cool system shit!
	lordRyan wrote this :D
    Shoutout to him :D
*/

import haxe.io.Bytes;

class CoolSystemStuff
{
	public static function getUsername():String
	{
		// uhh this one is self explanatory
		#if sys
		#if windows
		return Sys.getEnv("USERNAME");
		#else
		return Sys.getEnv("USER");
		#end
		#else
		return "";
		#end
	}

	public static function getUserPath():String
	{
		// this one is also self explantory
		#if sys
		#if windows
		return Sys.getEnv("USERPROFILE");
		#else
		return Sys.getEnv("HOME");
		#end
		#else
		return "";
		#end
	}

	public static function getTempPath():String
	{
		// gets appdata temp folder lol
		#if sys
		#if windows
		return Sys.getEnv("TEMP");
		#else
		// most non-windows os dont have a temp path, or if they do its not 100% compatible, so the user folder will be a fallback
		return Sys.getEnv("HOME");
		#end
		#else
		return "";
		#end
	}
	public static function executableFileName()
	{
		#if sys
		#if windows
		var programPath = Sys.programPath().split("\\");
		#else
		var programPath = Sys.programPath().split("/");
		#end
		return programPath[programPath.length - 1];
		#else
		return "game";
		#end
	}
}
