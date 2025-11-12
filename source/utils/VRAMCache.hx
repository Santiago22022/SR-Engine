package utils;

import Character;
import Character.CharacterFile;
import Note;
import NoteSplash;
import Paths;
import ClientPrefs;
import Song.SwagSong;
import StageData;
import haxe.Json;
import haxe.ds.StringMap;
using StringTools;

class VRAMCache
{
	static var cachedGraphics:StringMap<Bool> = new StringMap<Bool>();
	static var cachedCharacters:StringMap<Bool> = new StringMap<Bool>();

	public static function preloadForSong(song:SwagSong, dad:Character, boyfriend:Character, gf:Character, currentStage:String, stageUI:String, isPixelStage:Bool, dadSkin:String, bfSkin:String):Void
	{
		if (!ClientPrefs.cacheOnGPU || song == null)
			return;

		cacheGraphic(Note.defaultNoteSkin + Note.getNoteSkinPostfix());
		cacheGraphic('noteSplashes/noteSplashes' + NoteSplash.getSplashSkinPostfix());

		preloadNoteSkin(dadSkin);
		preloadNoteSkin(bfSkin);

		preloadCharacter(song.player1);
		preloadCharacter(song.player2);
		preloadCharacter(song.gfVersion);
		if (dad != null) preloadCharacter(dad.curCharacter);
		if (boyfriend != null) preloadCharacter(boyfriend.curCharacter);
		if (gf != null) preloadCharacter(gf.curCharacter);

		if (stageUI == 'pixel' || isPixelStage)
			cacheGraphic('pixelUI/NOTE_assets');

		preloadStage(currentStage);
	}

	static function preloadStage(stage:String):Void
	{
		if (stage == null || stage.length == 0 || !ClientPrefs.cacheOnGPU)
			return;
		var stageFile = StageData.getStageFile(stage);
		if (stageFile != null && stageFile.directory != null && stageFile.directory.length > 0)
		{
			cacheGraphic('stages/' + stageFile.directory + '/stageback');
			cacheGraphic('stages/' + stageFile.directory + '/stagefront');
		}
	}

	static function preloadNoteSkin(skin:String):Void
	{
		if (skin == null || skin.length == 0)
			return;
		var normalized = skin;
		if (!normalized.startsWith('noteskins/'))
			normalized = 'noteskins/' + normalized;
		cacheGraphic(normalized);
	}

	static function preloadCharacter(charName:String):Void
	{
		if (charName == null || charName.length == 0 || cachedCharacters.exists(charName))
			return;

		var raw:String = Paths.getTextFromFile('characters/' + charName + '.json');
		if (raw == null || raw.length == 0)
			return;

		try
		{
			var data:CharacterFile = cast Json.parse(raw);
			if (data != null)
			{
				if (data.image != null && data.image.length > 0)
				{
					var sheets = data.image.split(',');
					for (sheet in sheets)
					{
						var trimmed = sheet.trim();
						if (trimmed.length > 0)
						{
							Paths.getAtlas(trimmed);
							cacheGraphic(trimmed);
						}
					}
				}
				if (data.healthicon != null && data.healthicon.length > 0)
					cacheGraphic('icons/icon-' + data.healthicon);
				if (data.noteskin != null && data.noteskin.length > 0)
					preloadNoteSkin(data.noteskin);
			}
			cachedCharacters.set(charName, true);
		}
		catch(e:Dynamic)
		{
			// ignore malformed character files
		}
	}

	static function cacheGraphic(key:String):Void
	{
		if (!ClientPrefs.cacheOnGPU || key == null)
			return;
		var normalized = key.trim();
		if (normalized.length == 0 || cachedGraphics.exists(normalized))
			return;

		var graphic = Paths.image(normalized);
		if (graphic != null)
			cachedGraphics.set(normalized, true);
	}
}
