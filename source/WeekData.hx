package;

import tjson.TJSON as Json;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var ?hiddenUntilUnlocked:Null<Bool>;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var ?difficulties:String;
}

private typedef CachedWeekEntry =
{
	var timestamp:Float;
	var data:WeekFile;
}

class WeekData {
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	static var cachedWeekFiles:Map<String, CachedWeekEntry> = new Map();
	public var folder:String = '';
	static final REQUIRED_WEEK_FIELDS:Array<String> = ["songs", "weekCharacters", "weekName"];

	// JSON variables
	public var songs:Array<Dynamic>;
	public var weekCharacters:Array<String>;
	public var weekBackground:String;
	public var weekBefore:String;
	public var storyName:String;
	public var weekName:String;
	public var freeplayColor:Array<Int>;
	public var startUnlocked:Bool;
	public var hiddenUntilUnlocked:Null<Bool>;
	public var hideStoryMode:Bool;
	public var hideFreeplay:Bool;
	public var difficulties:String;

	public var fileName:String;

	public static function createWeekFile():WeekFile {
		var weekFile:WeekFile = {
			songs: [["Bopeebo", "dad", [146, 113, 253]], ["Fresh", "dad", [146, 113, 253]], ["Dad Battle", "dad", [146, 113, 253]]],
			weekCharacters: ['dad', 'bf', 'gf'],
			weekBackground: 'stage',
			weekBefore: 'tutorial',
			storyName: 'Your New Week',
			weekName: 'Custom Week',
			freeplayColor: [146, 113, 253],
			startUnlocked: true,
			hiddenUntilUnlocked: false,
			hideStoryMode: false,
			hideFreeplay: false,
			difficulties: ''
		};
		return weekFile;
	}

	public function new(weekFile:WeekFile, fileName:String) {
		var template = createWeekFile();
		for (i in Reflect.fields(weekFile)) {
			if (Reflect.hasField(template, i)) { //just doing Reflect.hasField on itself doesnt work for some reason so we are doing it on a template
				Reflect.setProperty(this, i, Reflect.field(weekFile, i));
			}
		}

		if (hiddenUntilUnlocked == null) {
			hiddenUntilUnlocked = false;
		}

		this.fileName = fileName;
	}

	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var disabledMods:Array<String> = [];

		var modsListPath:String = 'modsList.txt';
		var directories:Array<String> = [Paths.mods(), Paths.getPreloadPath()];

		var originalLength:Int = directories.length;
		if(FileSystem.exists(modsListPath))
		{
			var stuff:Array<String> = CoolUtil.coolTextFile(modsListPath);
			for (i in 0...stuff.length)
			{
				var splitName:Array<String> = stuff[i].trim().split('|');
				if(splitName[1] == '0') // Disable mod
				{
					disabledMods.push(splitName[0]);
				}
				else // Sort mod loading order based on modsList.txt file
				{
					var path = haxe.io.Path.join([Paths.mods(), splitName[0]]);
					//trace('trying to push: ' + splitName[0]);
					if (sys.FileSystem.isDirectory(path) && !Paths.ignoreModFolders.contains(splitName[0]) && !disabledMods.contains(splitName[0]) && !directories.contains(path + '/'))
					{
						directories.push(path + '/');
						//trace('pushed Directory: ' + splitName[0]);
					}
				}
			}
		}

		var modsDirectories:Array<String> = Paths.getModDirectories();
		for (folder in modsDirectories)
		{
			var pathThing:String = haxe.io.Path.join([Paths.mods(), folder]) + '/';
			if (!disabledMods.contains(folder) && !directories.contains(pathThing))
			{
				directories.push(pathThing);
				//trace('pushed Directory: ' + folder);
			}
		}
		#else
		var directories:Array<String> = [Paths.getPreloadPath()];
		var originalLength:Int = directories.length;
		#end

		final baseWeekList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));
		for (weekName in baseWeekList)
		{
			if (weeksLoaded.exists(weekName))
				continue;

			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'weeks/' + weekName + '.json';
				var week:WeekFile = getWeekFile(fileToCheck);
				if (week == null)
					continue;

				var weekData:WeekData = new WeekData(week, weekName);

				#if MODS_ALLOWED
				if (j >= originalLength)
					assignModFolder(weekData, directories[j]);
				#end

				if (shouldIncludeWeek(weekData, isStoryMode))
					registerWeek(weekName, weekData);

				break;
			}
		}

		#if MODS_ALLOWED
		for (i in 0...directories.length) {
			var directory:String = directories[i] + 'weeks/';
			if(FileSystem.exists(directory)) {
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if(sys.FileSystem.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}

				for (file in FileSystem.readDirectory(directory))
				{
					var path = haxe.io.Path.join([directory, file]);
					if (!sys.FileSystem.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.substr(0, file.length - 5), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}

	private static function isValidWeekJson(data:Dynamic):Bool
	{
		if (data == null) return false;

		for (field in REQUIRED_WEEK_FIELDS)
		{
			if (!Reflect.hasField(data, field))
				return false;
		}

		final songs = Reflect.field(data, "songs");
		final chars = Reflect.field(data, "weekCharacters");
		if (songs == null || chars == null || songs.length <= 0 || chars.length <= 0)
			return false;

		return true;
	}

	inline static function shouldIncludeWeek(weekFile:WeekData, isStoryMode:Null<Bool>):Bool
	{
		if (isStoryMode == null)
			return true;
		return isStoryMode ? !weekFile.hideStoryMode : !weekFile.hideFreeplay;
	}

	inline static function registerWeek(weekName:String, data:WeekData):Void
	{
		weeksLoaded.set(weekName, data);
		weeksList.push(weekName);
	}

	#if MODS_ALLOWED
	inline static function assignModFolder(weekFile:WeekData, directory:String):Void
	{
		if (directory == null)
			return;
		final modsPath = Paths.mods();
		if (directory.length > modsPath.length)
			weekFile.folder = directory.substring(modsPath.length, directory.length - 1);
	}
	#end

	private static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if(!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if(week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if(i >= originalLength)
				{
					#if MODS_ALLOWED
					assignModFolder(weekFile, directory);
					#end
				}
				if(shouldIncludeWeek(weekFile, PlayState.isStoryMode))
				{
					registerWeek(weekToCheck, weekFile);
				}
			}
		}
	}

	private static function getWeekFile(path:String):WeekFile {
		#if MODS_ALLOWED
		if(FileSystem.exists(path)) {
			final timestamp = getModifiedTime(path);
			final cached = getCachedWeek(path, timestamp);
			if (cached != null)
				return cached;

			final rawJson = File.getContent(path);
			if (rawJson != null && rawJson.length > 0)
				return parseAndCacheWeek(path, rawJson, timestamp);
		} else {
			cachedWeekFiles.remove(path);
		}
		#else
		if(OpenFlAssets.exists(path)) {
			final cached = getCachedWeek(path, -1);
			if (cached != null)
				return cached;

			final rawJson = Assets.getText(path);
			if (rawJson != null && rawJson.length > 0)
				return parseAndCacheWeek(path, rawJson, -1);
		} else {
			cachedWeekFiles.remove(path);
		}
		#end

		return null;
	}

	inline static function getCachedWeek(path:String, timestamp:Float):WeekFile
	{
		final cached = cachedWeekFiles.get(path);
		if (cached == null)
			return null;

		if (timestamp >= 0 && cached.timestamp != timestamp)
		{
			cachedWeekFiles.remove(path);
			return null;
		}

		if (timestamp < 0 && cached.timestamp >= 0)
			return null;

		return copyWeekFile(cached.data);
	}

	static function parseAndCacheWeek(path:String, rawJson:String, timestamp:Float):WeekFile
	{
		try
		{
			final parsed:Dynamic = haxe.Json.parse(rawJson);
			if (isValidWeekJson(parsed))
			{
				final data:WeekFile = copyWeekFile(cast parsed);
				cachedWeekFiles.set(path, {timestamp: timestamp, data: data});
				return copyWeekFile(data);
			}
		}
		catch (e:Dynamic)
		{
			#if debug
			trace('Failed to parse week file $path: $e');
			#end
		}

		cachedWeekFiles.remove(path);
		return null;
	}

	#if MODS_ALLOWED
	inline static function getModifiedTime(path:String):Float
	{
		final stats = FileSystem.stat(path);
		return (stats != null && stats.mtime != null) ? stats.mtime.getTime() : -1;
	}
	#end

	private static function copyWeekFile(source:WeekFile):WeekFile
	{
		if (source == null)
			return null;

		return {
			songs: copySongEntries(source.songs),
			weekCharacters: source.weekCharacters != null ? source.weekCharacters.copy() : [],
			weekBackground: source.weekBackground,
			weekBefore: source.weekBefore,
			storyName: source.storyName,
			weekName: source.weekName,
			freeplayColor: source.freeplayColor != null ? source.freeplayColor.copy() : [],
			startUnlocked: source.startUnlocked,
			hiddenUntilUnlocked: source.hiddenUntilUnlocked,
			hideStoryMode: source.hideStoryMode,
			hideFreeplay: source.hideFreeplay,
			difficulties: source.difficulties
		};
	}

	private static function copySongEntries(source:Array<Dynamic>):Array<Dynamic>
	{
		if (source == null)
			return [];

		final result:Array<Dynamic> = [];
		for (entry in source)
		{
			if (Std.isOfType(entry, Array))
			{
				final data:Array<Dynamic> = cast entry;
				final copied:Array<Dynamic> = [];
				for (value in data)
				{
					if (Std.isOfType(value, Array))
						copied.push((cast value:Array<Dynamic>).copy());
					else
						copied.push(value);
				}
				result.push(copied);
			}
			else
				result.push(entry);
		}
		return result;
	}

	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE

	//To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String {
		return weeksList[PlayState.storyWeek];
	}

	//Used on LoadingState, nothing really too relevant
	public static function getCurrentWeek():WeekData {
		return weeksLoaded.get(weeksList[PlayState.storyWeek]);
	}

	public static function setDirectoryFromWeek(?data:WeekData = null) {
		Paths.currentModDirectory = '';
		if(data != null && data.folder != null && data.folder.length > 0) {
			Paths.currentModDirectory = data.folder;
		}
	}

	public static function loadTheFirstEnabledMod()
	{
		Paths.currentModDirectory = '';

		#if (MODS_ALLOWED)
		if (FileSystem.exists("modsList.txt"))
		{
			var list:Array<String> = CoolUtil.listFromString(File.getContent("modsList.txt"));
			var foundTheTop = false;
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1" && !foundTheTop)
				{
					foundTheTop = true;
					Paths.currentModDirectory = dat[0];
				}
			}
		}
		#end
	}
}
