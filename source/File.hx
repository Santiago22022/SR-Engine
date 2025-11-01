#if !sys
package;

import haxe.io.Bytes;
import openfl.utils.Assets as OpenFlAssets;

class File
{
	public static function getContent(path:String):String
	{
		return OpenFlAssets.exists(path) ? OpenFlAssets.getText(path) : "";
	}

	public static function getBytes(path:String):Bytes
	{
		return OpenFlAssets.exists(path) ? OpenFlAssets.getBytes(path) : Bytes.alloc(0);
	}

	public static function saveContent(path:String, data:String):Void {}

	public static function saveBytes(path:String, data:Bytes):Void {}

	public static function write(path:String, binary:Bool = false):FileOutputStub
	{
		return new FileOutputStub();
	}
}

class FileOutputStub
{
	public function new() {}

	public function write(bytes:Bytes):Void {}

	public function writeString(data:String):Void {}

	public function close():Void {}
}
#end
