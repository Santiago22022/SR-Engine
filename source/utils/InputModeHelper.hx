package utils;

import ClientPrefs;
import StringTools;

class InputModeHelper
{
	inline static final DEFAULT_MODE:String = 'Psych Engine';

	static inline function normalize(mode:String):String
	{
		if (mode == null)
			return DEFAULT_MODE;
		final trimmed:String = StringTools.trim(mode);
		return trimmed.length <= 0 ? DEFAULT_MODE : trimmed;
	}

	static inline function isSREngine(mode:String):Bool
	{
		final normalized = normalize(mode);
		return normalized == 'SR Engine' || normalized == 'SR Engine Input';
	}

	static inline function isOSEngine(mode:String):Bool
	{
		return normalize(mode) == 'OS Engine';
	}

	public static inline function defaultMode():String
	{
		return DEFAULT_MODE;
	}

	public static function getAvailableModes():Array<String>
	{
		return [
			'Psych Engine',
			'Psych Engine (Anti-Mash)',
			'Psych Engine (Anti-Spam)',
			'Codename Engine',
			'OS Engine',
			'SR Engine'
		];
	}

	public static inline function usesAntiMash():Bool
	{
		return switch (normalize(ClientPrefs.inputMode))
		{
			case 'Psych Engine (Anti-Mash)', 'Codename Engine', 'SR Engine', 'SR Engine Input': true;
			default: false;
		}
	}

	public static inline function usesAntiSpam():Bool
	{
		return switch (normalize(ClientPrefs.inputMode))
		{
			case 'Psych Engine (Anti-Spam)', 'Codename Engine', 'SR Engine', 'SR Engine Input': true;
			default: false;
		}
	}

	public static inline function allowsStackHitAssist():Bool
	{
		return ClientPrefs.ezSpam || isOSEngine(ClientPrefs.inputMode) || isSREngine(ClientPrefs.inputMode);
	}

	public static inline function getSpamWindow():Float
	{
		return switch (normalize(ClientPrefs.inputMode))
		{
			case 'Psych Engine (Anti-Spam)': 0.05;
			case 'Codename Engine': 0.045;
			case 'SR Engine' | 'SR Engine Input': 0.06;
			default: 0.04;
		}
	}
}
