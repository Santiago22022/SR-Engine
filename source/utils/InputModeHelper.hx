package utils;

import ClientPrefs;
import StringTools;

private typedef InputModeConfig =
{
	var name:String;
	var normalized:String;
	var antiMash:Bool;
	var antiSpam:Bool;
	var spamWindow:Float;
	var allowStackAssist:Bool;
}

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

	static final MODE_CONFIGS:Array<InputModeConfig> = [
		buildConfig('Psych Engine', false, false, 0.04, false),
		buildConfig('Psych Engine (Anti-Mash)', true, false, 0.04, false),
		buildConfig('Psych Engine (Anti-Spam)', false, true, 0.05, false),
		buildConfig('Codename Engine', true, true, 0.045, false),
		buildConfig('OS Engine', false, false, 0.04, true),
		buildConfig('SR Engine', true, true, 0.06, true),
		buildConfig('SR Engine Input', true, true, 0.06, true)
	];
	static final CONFIG_BY_NAME:Map<String, InputModeConfig> = buildConfigMap();

	static var cachedModeName:String = null;
	static var cachedConfig:InputModeConfig = null;

	static inline function buildConfig(name:String, antiMash:Bool, antiSpam:Bool, spamWindow:Float, allowStackAssist:Bool):InputModeConfig
	{
		return {
			name: name,
			normalized: normalize(name),
			antiMash: antiMash,
			antiSpam: antiSpam,
			spamWindow: spamWindow,
			allowStackAssist: allowStackAssist
		};
	}

	static function buildConfigMap():Map<String, InputModeConfig>
	{
		final map = new Map<String, InputModeConfig>();
		for (config in MODE_CONFIGS)
		{
			if (!map.exists(config.normalized))
				map.set(config.normalized, config);
		}
		return map;
	}

	static inline function currentConfig():InputModeConfig
	{
		final normalized = normalize(ClientPrefs.inputMode);
		if (cachedConfig == null || cachedModeName != normalized)
		{
			cachedModeName = normalized;
			cachedConfig = CONFIG_BY_NAME.get(cachedModeName);
			if (cachedConfig == null)
				cachedConfig = MODE_CONFIGS[0];
		}
		return cachedConfig;
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
		final modes:Array<String> = [];
		for (config in MODE_CONFIGS)
			modes.push(config.name);
		return modes;
	}

	public static inline function usesAntiMash():Bool
	{
		return currentConfig().antiMash;
	}

	public static inline function usesAntiSpam():Bool
	{
		return currentConfig().antiSpam;
	}

	public static inline function allowsStackHitAssist():Bool
	{
		return ClientPrefs.ezSpam || currentConfig().allowStackAssist;
	}

	public static inline function getSpamWindow():Float
	{
		return currentConfig().spamWindow;
	}
}
