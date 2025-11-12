package utils;

import Song.SwagSong;
import Character;
import Paths;
import ClientPrefs;
import haxe.ds.StringMap;

class AudioCache
{
	static var cachedSongs:StringMap<Bool> = new StringMap<Bool>();

	public static function preloadSongAudio(song:SwagSong, difficulty:String, boyfriend:Character, dad:Character):Void
	{
		if (song == null)
			return;

		var formattedDifficulty:String = difficulty != null ? difficulty : '';
		var key = Paths.formatToSongPath(song.song) + ':' + formattedDifficulty;
		if (cachedSongs.exists(key))
			return;

		Paths.inst(song.song, formattedDifficulty);

		if (song.needsVoices)
		{
			var playerVocals = (boyfriend != null && boyfriend.vocalsFile != null && boyfriend.vocalsFile.length > 0) ? boyfriend.vocalsFile : 'Player';
			var opponentVocals = (dad != null && dad.vocalsFile != null && dad.vocalsFile.length > 0) ? dad.vocalsFile : 'Opponent';
			Paths.voices(song.song, formattedDifficulty, playerVocals);
			Paths.voices(song.song, formattedDifficulty, opponentVocals);
		}

		cachedSongs.set(key, true);
	}
}
