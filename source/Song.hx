package;

import Section.SwagSection;
import haxe.format.JsonParser;
#if sys
import sys.FileSystem;
import sys.io.File;
#end


typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;

	@:optional var disableNoteRGB:Bool;

	var songCredit:String;
	var songCreditBarPath:String;
	var songCreditIcon:String;
	var event7:String;
	var event7Value:String;

	var windowName:String;
	var specialAudioName:String;
	var specialEventsName:String;

	var arrowSkin:String;
	var splashSkin:String;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	private static function onLoadJson(songJson:Dynamic) // Convert old charts to newest format
	{
		if (songJson == null) {
			trace('Warning: songJson is null in onLoadJson');
			return;
		}
		
		try {
			if(songJson.gfVersion == null)
			{
				songJson.gfVersion = songJson.player3;
				if (Reflect.hasField(songJson, 'player3'))
                    Reflect.deleteField(songJson, 'player3');
			}	
		}
		catch(e:Dynamic){
			final errStr:String = e.toString();
			if (errStr.startsWith('Invalid') && errStr.endsWith('gfVersion'))
				throw "Psych 1.0 charts are not supported!";
			else
			{
				songJson.gfVersion = "null";
				trace(e);
			}
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			// Check if notes exists and is an array before accessing its length
			if (songJson.notes != null) {
				var notesLength = 0;
				try {
					// Try to get the length, but handle the case where it fails
					if (Std.isOfType(songJson.notes, Array)) {
						notesLength = songJson.notes.length;
					} else {
						trace('Warning: songJson.notes is not an Array type');
						return; // Exit to prevent the error
					}
				} catch(e:Dynamic) {
					trace('Error accessing songJson.notes.length: $e');
					return; // Exit to prevent the error
				}
				
				for (secNum in 0...notesLength)
				{
					if (songJson.notes[secNum] != null) {
						var sec:SwagSection = songJson.notes[secNum];

						if (sec.sectionNotes != null) {
							var i:Int = 0;
							var notes:Array<Dynamic> = sec.sectionNotes;
							var len:Int = notes.length;
							while(i < len)
							{
								var note:Array<Dynamic> = notes[i];
								if(note != null && note.length >= 5 && Std.isOfType(note[1], Float) && cast(note[1], Float) < 0)
								{
									songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
									notes.remove(note);
									len = notes.length;
								}
								else i++;
							}
						}
					}
				}
			}
		}
        /*
		if (Reflect.hasField(songJson, "format") && StringTools.contains(Reflect.field(songJson, 'format'), 'psych_v1')){
            throw "Psych Engine 1.0 charts are not supported!";
        }
        */
	}

	public static function hasDifficulty(songName:String, difficulty:String):Bool
	{
		var formattedSong:String = Paths.formatToSongPath(songName);
		var formDiff:String = Paths.formatToSongPath(difficulty);
		var jsonToFind:String = Paths.json(formattedSong + '/' + formattedSong + '-' + formDiff);
		#if MODS_ALLOWED
			if (!CoolUtil.defaultSongs.contains(formattedSong) && !CoolUtil.defaultSongsFormatted.contains(formattedSong))
				jsonToFind = Paths.modsJson(formattedSong + '/' + formattedSong + '-' + formDiff); #end
		#if sys
		if(FileSystem.exists(jsonToFind)) return true;
		#else
		if (OpenFlAssets.exists(jsonToFind)) return true;
		#end

		return false;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson:String = null;

		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		#if (MODS_ALLOWED && sys)
		var moddyFile:String = Paths.modsJson('$formattedFolder/$formattedSong');
		if(FileSystem.exists(moddyFile)) {
			rawJson = File.getContent(moddyFile).trim();
		}
		#end

		if(rawJson == null) {
			var path:String = Paths.json('$formattedFolder/$formattedSong');
			#if sys
			if(FileSystem.exists(path))
				rawJson = File.getContent(path);
			else
			#end
				#if html5
				// For HTML5, ensure the library is loaded first
				var libraryName = formattedFolder;
				if (libraryName != null && libraryName.length > 0 && libraryName != "preload") {
					Paths.setCurrentLevel(libraryName);
				}
				#end
				
				if (Assets.exists(path)) {
					rawJson = Assets.getText(path);
				} else {
					trace('Warning: Song JSON file does not exist at path: $path');
					// Return a default song to prevent crashes
					return {
						song: formattedSong,
						notes: [],
						events: [],
						bpm: 100,
						needsVoices: false,
						speed: 1,
						player1: "bf",
						player2: "dad",
						gfVersion: "gf",
						stage: "",
						songCredit: "",
						songCreditBarPath: "",
						songCreditIcon: "",
						event7: "",
						event7Value: "",
						windowName: "",
						specialAudioName: "",
						specialEventsName: "",
						arrowSkin: "",
						splashSkin: ""
					};
				}
		}

		var songJson:Dynamic = parseJSON(rawJson);
		if (songJson == null) {
			trace('Error: Failed to parse song JSON for: $formattedSong');
			// Return a default song to prevent crashes
			return {
				song: formattedSong,
				notes: [],
				events: [],
				bpm: 100,
				needsVoices: false,
				speed: 1,
				player1: "bf",
				player2: "dad",
				gfVersion: "gf",
				stage: "",
				songCredit: "",
				songCreditBarPath: "",
				songCreditIcon: "",
				event7: "",
				event7Value: "",
				windowName: "",
				specialAudioName: "",
				specialEventsName: "",
				arrowSkin: "",
				splashSkin: ""
			};
		}
		
		if(jsonInput != 'events') StageData.loadDirectory(songJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSON(rawJson:String):SwagSong {
		try {
			if (rawJson == null || rawJson.length == 0) {
				trace('Warning: rawJson is null or empty in parseJSON');
				return getDefaultSong();
			}
			
			var parsedData:Dynamic = Json.parse(rawJson);
			if (parsedData == null) {
				trace('Error: Json.parse returned null');
				return getDefaultSong();
			}
			
			if (parsedData.song == null) {
				trace('Error: Parsed data missing song property');
				return getDefaultSong();
			}
			
			// Check if the song object has the required properties
			var songObj:Dynamic = parsedData.song;
			if (songObj.notes == null) {
				trace('Warning: Song object missing notes array, initializing as empty');
				songObj.notes = [];
			}
			
			return cast songObj;
		} catch (e:Dynamic) {
			trace('Error parsing JSON: $e');
			return getDefaultSong();
		}
	}
	
	private static function getDefaultSong():SwagSong {
		return {
			song: "default",
			notes: [],
			events: [],
			bpm: 100,
			needsVoices: false,
			speed: 1,
			player1: "bf",
			player2: "dad",
			gfVersion: "gf",
			stage: "",
			songCredit: "",
			songCreditBarPath: "",
			songCreditIcon: "",
			event7: "",
			event7Value: "",
			windowName: "",
			specialAudioName: "",
			specialEventsName: "",
			arrowSkin: "",
			splashSkin: ""
		};
	}
}
