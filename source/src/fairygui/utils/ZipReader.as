package fairygui.utils
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class ZipReader
	{
		private var _stream:ByteArray;
		private var _entries:Object;
		
		public function ZipReader(ba:ByteArray):void {
			_stream = ba;
			_stream.endian = Endian.LITTLE_ENDIAN;
			_entries = {};
			
			readEntries();
		}
		
		public function get entries():Object
		{
			return _entries;
		}

		private function readEntries():void {
			var buf:ByteArray = new ByteArray();
			buf.endian = Endian.LITTLE_ENDIAN;

			//End of central directory record(EOCD) 
			_stream.position = _stream.length - 22;
			_stream.readBytes(buf, 0, 22);
			buf.position = 10;
			var entryCount:int = buf.readUnsignedShort();
			buf.position = 16;
			_stream.position = buf.readUnsignedInt();
			buf.length = 0;
			
			for(var i:int = 0; i < entryCount; i++) {
				_stream.readBytes(buf, 0, 46);
				buf.position = 28;
				var len:uint = buf.readUnsignedShort();
				var name:String = _stream.readUTFBytes(len);
				var nextEntryPos:int = _stream.position + buf.readUnsignedShort() + buf.readUnsignedShort();
				var lastChar:String = name.charAt(name.length-1);
				if(lastChar=="/" || lastChar=="\\")
				{
					_stream.position = nextEntryPos;
					continue;
				}
				
				name = name.replace(/\\/g, "/");
				var e:ZipEntry = new ZipEntry();
				e.name = name;
				buf.position = 10;
				e.compress = buf.readUnsignedShort();
				buf.position = 16;
				e.crc = buf.readUnsignedInt();
				e.size = buf.readUnsignedInt();
				e.sourceSize = buf.readUnsignedInt();
				buf.position = 42;

				//local file header 文件头
				e.offset = buf.readUnsignedInt();
				_stream.position = e.offset;
				_stream.readBytes(buf, 0, 30);
				buf.position = 26;
				e.offset += buf.readUnsignedShort() + buf.readUnsignedShort() + 30;

				_stream.position = nextEntryPos;
				_entries[name] = e;
			}
		}
		
		public function getEntryData(n:String):ByteArray {
			var entry:ZipEntry = _entries[n];
			if(!entry)
				return null;
			
			var ba:ByteArray = new ByteArray();
			if(!entry.size)
				return ba;
			
			_stream.position = entry.offset;
			_stream.readBytes(ba, 0, entry.size);
			if(entry.compress)
				ba.inflate();
			
			return ba;
		}
	}
}

import flash.utils.ByteArray;

class ZipEntry
{
	public var name:String;
	public var offset:uint;
	public var size:uint;
	public var sourceSize:uint;
	public var compress:int;
	public var crc:uint;
	
	public function ZipEntry() {}
}