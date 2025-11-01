package;

import flixel.util.typeLimit.NextState;
import lime.utils.AssetType;
#if html5
import lime.app.Future;
import lime.utils.AssetLibrary;
import openfl.utils.Assets as OpenFlAssets;
#end

class LoadingState extends MusicBeatState {
	// TO DO: Make this easier

	public static function loadAndSwitchState(target:NextState, stopMusic = false) {
		FlxG.switchState(getNextState(target, stopMusic));
	}

	static function getNextState(target:NextState, stopMusic = false):NextState {
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);

		#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (PlayState.SONG != null) {
			loaded = isSoundLoaded(Paths.inst(PlayState.SONG.song)) && (!PlayState.SONG.needsVoices || isSoundLoaded(Paths.voices(PlayState.SONG.song))) && isLibraryLoaded("shared") && isLibraryLoaded(directory);
		}

		if (!loaded)
			return new LoadingState(target, stopMusic, directory);
		#end
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		return target;
	}

	#if NO_PRELOAD_ALL
	static function isSoundLoaded(path:String):Bool {
		return Assets.cache != null && Assets.cache.exists(path, AssetType.SOUND);
	}

	static function isLibraryLoaded(library:String):Bool {
		return Assets.getLibrary(library) != null;
	}
	#end
	#if NO_PRELOAD_ALL
	var targetState:NextState;
	var shouldStopMusic:Bool;
	var pendingDirectory:String;

	public function new(target:NextState, stopMusic:Bool, directory:String)
	{
		targetState = target;
		shouldStopMusic = stopMusic;
		pendingDirectory = directory;
		super();
	}

	override public function create():Void
	{
		super.create();

		if (pendingDirectory != null && pendingDirectory.length > 0)
			Paths.setCurrentLevel(pendingDirectory);

		if (shouldStopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		#if html5
		if (tryLoadLibrariesAsync())
			return;
		#end

		switchToTarget();
	}

	function switchToTarget():Void
	{
		if (targetState != null)
			FlxG.switchState(targetState);
	}

	#if html5
	function tryLoadLibrariesAsync():Bool
	{
		var libs:Array<String> = [];

		if (pendingDirectory != null && pendingDirectory.length > 0)
			libs.push(pendingDirectory.toLowerCase());

		if (!libs.contains('shared'))
			libs.push('shared');

		var libsToLoad:Array<String> = [];

		for (lib in libs)
		{
			if (lib == null || lib.length == 0)
				continue;

			var lowered = lib.toLowerCase();
			if (!libsToLoad.contains(lowered))
				libsToLoad.push(lowered);
		}

		if (libsToLoad.length == 0)
			return false;

		var pendingLoads:Int = libsToLoad.length;
		var hasErrored:Bool = false;
		var hasSwitched:Bool = false;

		function triggerSwitch():Void
		{
			if (!hasSwitched)
			{
				hasSwitched = true;
				switchToTarget();
			}
		}

		function handleCompletion():Void
		{
			if (hasErrored)
				return;

			pendingLoads--;
			if (pendingLoads <= 0)
				triggerSwitch();
		}

		function handleError(libName:String, err:Dynamic):Void
		{
			if (hasErrored)
				return;

			hasErrored = true;
			trace('Failed to load library $libName: ' + Std.string(err));
			triggerSwitch();
		}

		for (libName in libsToLoad)
		{
			preloadLibrary(libName, handleCompletion, handleError);
		}

		return true;
	}

	function preloadLibrary(libName:String, done:Void->Void, fail:String->Dynamic->Void):Void
	{
		try
		{
			var future = OpenFlAssets.loadLibrary(libName);

			var onLibraryReady = function(library:AssetLibrary)
			{
				if (library == null)
				{
					done();
					return;
				}

				preloadLibraryAssets(libName, library, done, fail);
			};

			if (future == null)
			{
				onLibraryReady(cast OpenFlAssets.getLibrary(libName));
				return;
			}

			future.onComplete(function(library) onLibraryReady(library != null ? library : cast OpenFlAssets.getLibrary(libName)));
			future.onError(function(err) fail(libName, err));
		}
		catch (err:Dynamic)
		{
			fail(libName, err);
		}
	}

	function preloadLibraryAssets(libName:String, library:AssetLibrary, done:Void->Void, fail:String->Dynamic->Void):Void
	{
		var pending:Int = 0;
		var completed:Bool = false;
		var queued:Map<String, Bool> = new Map();

		function finalize():Void
		{
			if (!completed && pending <= 0)
			{
				completed = true;
				done();
			}
		}

		function queueFuture<T>(future:Future<T>, assetId:String, assetType:AssetType):Void
		{
			if (future == null)
				return;

			pending++;
			future.onComplete(function(_) {
				pending--;
				finalize();
			});
			future.onError(function(err) {
				fail(libName, 'Failed to load ' + Std.string(assetType) + ' asset "' + assetId + '": ' + Std.string(err));
				pending--;
				finalize();
			});
		}

		function queueAsset(assetId:String, assetType:AssetType):Void
		{
			var fullId:String = assetId;
			if (fullId.indexOf(':') == -1)
				fullId = libName + ':' + assetId;

			if (queued.exists(fullId))
				return;
			queued.set(fullId, true);

			var future:Future<Dynamic> = null;

			switch (assetType)
			{
				case AssetType.IMAGE:
					future = cast OpenFlAssets.loadBitmapData(fullId);
				case AssetType.TEXT:
					future = cast OpenFlAssets.loadText(fullId);
				case AssetType.SOUND, AssetType.MUSIC:
					// Use Sound loader for both; music assets stream but share API
					future = (assetType == AssetType.MUSIC)
						? cast OpenFlAssets.loadMusic(fullId)
						: cast OpenFlAssets.loadSound(fullId);
				default:
					// ignore unsupported types
			}

			if (future != null)
				queueFuture(future, fullId, assetType);
		}

		var assetTypes:Array<AssetType> = [AssetType.IMAGE, AssetType.TEXT, AssetType.SOUND, AssetType.MUSIC];
		for (assetType in assetTypes)
		{
			var ids = library.list(assetType);
			if (ids == null)
				continue;

			for (assetId in ids)
				queueAsset(assetId, assetType);
		}

		if (pending == 0)
			finalize();
	}
	#end
	#end
}
