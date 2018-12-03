package fairygui.text
{
	import fairygui.utils.ToolSet;

	public class XMLIterator
	{
		public static var tagName:String;
		public static var tagType:int;
		public static var lastTagName:String;
		
		private static var source:String;
		private static var sourceLen:int;
		private static var parsePos:int;
		private static var tagPos:int;
		private static var tagLength:int;
		private static var lastTagEnd:int;
		private static var attrParsed:Boolean;
		private static var lowerCaseName:Boolean;
		private static var attributes:Object;
		
		public static const TAG_START:int = 0;
		public static const TAG_END:int = 1;
		public static const TAG_VOID:int = 2;
		public static const TAG_CDATA:int = 3;
		public static const TAG_COMMENT:int = 4;
		public static const TAG_INSTRUCTION:int = 5;
		
		private static const CDATA_START:String = "<![CDATA[";
		private static const CDATA_END:String = "]]>";
		private static const COMMENT_START:String = "<!--";
		private static const COMMENT_END:String = "-->";
		
		public static function begin(source:String, lowerCaseName:Boolean = false):void
		{
			XMLIterator.source = source;
			XMLIterator.lowerCaseName = lowerCaseName;
			sourceLen = source.length;
			parsePos = 0;
			lastTagEnd = 0;
			tagPos = 0;
			tagLength = 0;
			tagName = null;
		}
		
		public static function nextTag():Boolean
		{
			var pos:int;
			var c:int;
			tagType = TAG_START;
			lastTagEnd = parsePos;
			attrParsed = false;
			lastTagName = tagName;
			
			while ((pos = source.indexOf("<", parsePos)) != -1)
			{
				parsePos = pos;
				pos++;
				
				if (pos == sourceLen)
					break;
				
				c = source.charCodeAt(pos);
				if (c == 33) //!
				{
					if (sourceLen > pos + 7 && source.substr(pos - 1, 9) == CDATA_START)
					{
						pos = source.indexOf(CDATA_END, pos);
						tagType = TAG_CDATA;
						tagName = "";
						tagPos = parsePos;
						if (pos == -1)
							tagLength = sourceLen - parsePos;
						else
							tagLength = pos + 3 - parsePos;
						parsePos += tagLength;
						return true;
					}
					else if (sourceLen > pos + 2 && source.substr(pos - 1, 4) == COMMENT_START)
					{
						pos = source.indexOf(COMMENT_END, pos);
						tagType = TAG_COMMENT;
						tagName = "";
						tagPos = parsePos;
						if (pos == -1)
							tagLength = sourceLen - parsePos;
						else
							tagLength = pos + 3 - parsePos;
						parsePos += tagLength;
						return true;
					}
					else
					{
						pos++;
						tagType = TAG_INSTRUCTION;
					}
				}
				else if (c == 47) // /
				{
					pos++;
					tagType = TAG_END;
				}
				else if (c == 63) // ?
				{
					pos++;
					tagType = TAG_INSTRUCTION;
				}
				
				for (; pos < sourceLen; pos++)
				{
					c = source.charCodeAt(pos);
					if (c==32 || c==9 || c==10 || c==13 || c==62 || c==47) //space tab \r \n > /
						break;
				}
				if (pos == sourceLen)
					break;
				
				if(source.charCodeAt(parsePos + 1)==47)
					tagName = source.substr(parsePos + 2, pos - parsePos - 2);
				else
					tagName = source.substr(parsePos + 1, pos - parsePos - 1);
				if (lowerCaseName)
					tagName = tagName.toLowerCase();
				
				var singleQuoted:Boolean = false, doubleQuoted:Boolean = false;
				var possibleEnd:int = -1;
				for (; pos < sourceLen; pos++)
				{
					c = source.charCodeAt(pos);
					if (c == 34) //"
					{
						if (!singleQuoted)
							doubleQuoted = !doubleQuoted;
					}
					else if (c == 39) //'
					{
						if (!doubleQuoted)
							singleQuoted = !singleQuoted;
					}
					
					if (c == 62) //>
					{
						if (!(singleQuoted || doubleQuoted))
						{
							possibleEnd = -1;
							break;
						}
						
						possibleEnd = pos;
					}
					else if (c == 60) // <
						break;
				}
				if (possibleEnd != -1)
					pos = possibleEnd;
				
				if (pos == sourceLen)
					break;
				
				if (source.charCodeAt(pos-1) == 47) // /
					tagType = TAG_VOID;
				
				tagPos = parsePos;
				tagLength = pos + 1 - parsePos;
				parsePos += tagLength;
				
				return true;
			}
			
			tagPos = sourceLen;
			tagLength = 0;
			tagName = null;
			return false;
		}
		
		public static function getTagSource():String
		{
			return source.substr(tagPos, tagLength);
		}
		
		public static function getRawText(trim:Boolean = false):String
		{
			if (lastTagEnd == tagPos)
				return "";
			else if (trim)
			{
				var i:int = lastTagEnd;
				for (; i < tagPos; i++)
				{
					var c:int = source.charCodeAt(i);
					if(c != 32 && c != 9 && c != 13 && c != 10)
						break;
				}
				
				if (i == tagPos)
					return "";
				else
					return ToolSet.trimRight(source.substr(i, tagPos - i));
			}
			else
				return source.substr(lastTagEnd, tagPos - lastTagEnd);
		}
		
		public static function getText(trim:Boolean = false):String
		{
			if (lastTagEnd == tagPos)
				return "";
			else if (trim)
			{
				var i:int = lastTagEnd;
				for (; i < tagPos; i++)
				{
					var c:int = source.charCodeAt(i);
					if(c != 32 && c != 9 && c != 13 && c != 10)
						break;
				}
				
				if (i == tagPos)
					return "";
				else
					return ToolSet.decodeXML(ToolSet.trimRight(source.substr(i, tagPos - i)));
			}
			else
				return ToolSet.decodeXML(source.substr(lastTagEnd, tagPos - lastTagEnd));
		}
		
		public static function hasAttribute(attrName:Boolean):Boolean
		{
			if (!attrParsed)
			{
				attributes = {};
				parseAttributes(attributes);
				attrParsed = true;
			}
			
			return attributes.ContainsKey(attrName);
		}

		public static function getAttribute(attrName:String, defValue:String=null):String
		{
			if (!attrParsed)
			{
				attributes = {};
				parseAttributes(attributes);
				attrParsed = true;
			}
			
			var value:* = attributes[attrName];
			if(value!=undefined)
				return value.toString();
			else
				return defValue;
		}
		
		public static function getAttributeInt(attrName:String, defValue:int=0):int
		{
			var value:String = getAttribute(attrName);
			if (value == null || value.length == 0)
				return defValue;
			
			var ret:Number;
			if(value.charAt(value.length-1)=="%")
			{
				ret = parseInt(value.substr(0, value.length-1));
				if (isNaN(ret))
					return 0;
				
				return ret/100*defValue;
			}
			else
			{
				ret = parseInt(value);
				if (isNaN(ret))
					return 0;
				else
					return int(ret);
			}
		}
		
		public static function getAttributeFloat(attrName:String, defValue:Number=0):Number
		{
			var value:String = getAttribute(attrName);
			if (value == null || value.length == 0)
				return defValue;
			
			var ret:Number;
			if(value.charAt(value.length-1)=="%")
			{
				ret = parseFloat(value.substr(0, value.length-1));
				if (isNaN(ret))
					return 0;
				
				return ret/100*defValue;
			}
			else
			{
				ret = parseFloat(value);
				if (isNaN(ret))
					return 0;
				else
					return ret;
			}
		}
		
		public static function getAttributeBool(attrName:String, defValue:Boolean):Boolean
		{
			var value:String = getAttribute(attrName);
			if (value == null || value.length == 0)
				return defValue;
			
			return value=="true";
		}
		
		public static function getAttributes():Object
		{
			var result:Object = {};
			if (attrParsed)
			{
				for(var key:String in attributes)
					result[key] = attributes[key];
			}
			else //这里没有先ParseAttributes再赋值给result是为了节省复制的操作
				parseAttributes(result);
			
			return result;
		}
		
		private static function parseAttributes(attrs:Object):void
		{
			var attrName:String;
			var valueStart:int;
			var valueEnd:int;
			var waitValue:Boolean = false;
			var quoted:int;
			var i:int = tagPos;
			var attrEnd:int = tagPos + tagLength;
			var c:int;
			var buffer:String = "";
			
			if (i < attrEnd && source.charCodeAt(i) == 60) // <
			{
				for (; i < attrEnd; i++)
				{
					c = source.charCodeAt(i);
					if (c==32 || c==9 || c==10 || c==13 || c==62 || c==47) //space tab \r \n > /
						break;
				}
			}
			
			for (; i < attrEnd; i++)
			{
				c = source.charCodeAt(i);
				if (c == 61) // =
				{
					valueStart = -1;
					valueEnd = -1;
					quoted = 0;
					for (var j:int = i + 1; j < attrEnd; j++)
					{
						var c2:int = source.charCodeAt(j);
						if(c2 == 32 || c2 == 9 && c2 == 13 || c2 == 10)
						{
							if (valueStart != -1 && quoted == 0)
							{
								valueEnd = j - 1;
								break;
							}
						}
						else if (c2 == 62) // >
						{
							if (quoted == 0)
							{
								valueEnd = j - 1;
								break;
							}
						}
						else if (c2 == 34) // "
						{
							if (valueStart != -1)
							{
								if (quoted != 1)
								{
									valueEnd = j - 1;
									break;
								}
							}
							else
							{
								quoted = 2;
								valueStart = j + 1;
							}
						}
						else if (c2 == 39) // '
						{
							if (valueStart != -1)
							{
								if (quoted != 2)
								{
									valueEnd = j - 1;
									break;
								}
							}
							else
							{
								quoted = 1;
								valueStart = j + 1;
							}
						}
						else if (valueStart == -1)
						{
							valueStart = j;
						}
					}
					
					if (valueStart != -1 && valueEnd != -1)
					{
						attrName = buffer;
						if (lowerCaseName)
							attrName = attrName.toLowerCase();
						buffer = "";
						attrs[attrName] = ToolSet.decodeXML(source.substr(valueStart, valueEnd - valueStart + 1));
						i = valueEnd + 1;
					}
					else
						break;
				}
				else if (c != 32 && c != 9 && c != 13 && c != 10)
				{
					if (waitValue || c == 47 || c == 62) // / >
					{
						if (buffer.length > 0)
						{
							attrName = buffer;
							if (lowerCaseName)
								attrName = attrName.toLowerCase();
							attrs[attrName] = "";
							buffer = "";
						}
						
						waitValue = false;
					}
					
					if (c != 47 && c != 62) // / >
						buffer += String.fromCharCode(c);
				}
				else
				{
					if (buffer.length > 0)
						waitValue = true;
				}
			}
		}
	}
}