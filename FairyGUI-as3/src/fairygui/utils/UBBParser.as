package fairygui.utils
{
	public class UBBParser
	{
		private var _text:String;
		private var _readPos:int;
		
		protected var _handlers:Object;
		
		public var smallFontSize:int = 12;
		public var normalFontSize:int = 14;
		public var largeFontSize:int = 16;
		
		public var defaultImgWidth:int = 0;
		public var defaultImgHeight:int = 0;
		
		public var maxFontSize:int = 0;
		
		public static var inst:UBBParser = new UBBParser();
		
		public function UBBParser()
		{
			_handlers = {};
			_handlers["url"] = onTag_URL;
			_handlers["img"] = onTag_IMG;
			_handlers["b"] = onTag_Simple;
			_handlers["i"] = onTag_Simple;
			_handlers["u"] = onTag_Simple;
			_handlers["sup"] = onTag_Simple;
			_handlers["sub"] = onTag_Simple;
			_handlers["color"] = onTag_COLOR;
			_handlers["font"] = onTag_FONT;
			_handlers["size"] = onTag_SIZE;
			_handlers["align"] = onTag_ALIGN;
		}
		
		protected function onTag_URL(tagName:String, end:Boolean, attr:String):String {
			if(!end) {
				if(attr!=null)
					return "<a href=\"" + attr + "\" target=\"_blank\">";
				else {
					var href:String = getTagText();
					return "<a href=\"" + href + "\" target=\"_blank\">";
				}
			}
			else
				return "</a>";
		}
		
		protected function onTag_IMG(tagName:String, end:Boolean, attr:String):String {
			if(!end) {
				var src:String = getTagText(true);
				if(!src)
					return null;
				
				if(defaultImgWidth)
					return "<img src=\"" + src + "\" width=\"" + defaultImgWidth + "\" height=\"" + defaultImgHeight + "\"/>";
				else
					return "<img src=\"" + src + "\"/>";
			}
			else
				return null;
		}
		
		protected function onTag_Simple(tagName:String, end:Boolean, attr:String):String {
			return end?("</"+tagName+">"):("<" + tagName + ">");
		}
		
		protected function onTag_COLOR(tagName:String, end:Boolean, attr:String):String {
			if(!end)
				return "<font color=\"" + attr + "\">";
			else
				return "</font>";
		}
		
		protected function onTag_FONT(tagName:String, end:Boolean, attr:String):String {
			if(!end)
				return "<font face=\"" + attr + "\">";
			else
				return "</font>";
		}
		
		protected function onTag_ALIGN(tagName:String, end:Boolean, attr:String):String {
			if (!end)
				return "<p align=\"" + attr + "\">";
			else
				return "</p>";
		}
		
		protected function onTag_SIZE(tagName:String, end:Boolean, attr:String):String {
			if(!end) {
				var size:int;
				if(attr=="normal")
					size = normalFontSize;
				else if(attr=="small")
					size = smallFontSize;
				else if(attr=="large")
					size = largeFontSize;
				else if(attr.length && attr.charAt(0)=="+")
					size = (smallFontSize+int(attr.substr(1)));
				else if(attr.length && attr.charAt(0)=="-")
					size = (smallFontSize-int(attr.substr(1)));
				else
					size = parseInt(attr);
				if(size>maxFontSize)
					maxFontSize = size;
				return "<font size=\""+ size + "\">";
			}
			else
				return "</font>";
		}

		protected function getTagText(remove:Boolean=false):String {
			var pos1:int = _readPos;
			var pos2:int
			var result:String = "";
			while ((pos2 = _text.indexOf("[", pos1)) != -1)
			{
				if (_text.charCodeAt(pos2 - 1) == 92 )//\
				{
					result += _text.substring(pos1, pos2 - 1);
					result += "[";
					pos1 = pos2 + 1;
				}
				else
				{
					result += _text.substring(pos1, pos2);
					break;
				}
			}
			if (pos2 == -1)
				return null;
			
			if (remove)
				_readPos = pos2;
			
			return result;
		}		
		
		public function parse(text:String):String {
			_text = text;
			maxFontSize = 0;
			
			var pos1:int = 0, pos2:int, pos3:int;
			var end:Boolean;
			var tag:String, attr:String;
			var repl:String;
			var func:Function;
			var result:String = "";
			while((pos2=_text.indexOf("[", pos1))!=-1) {
				if (pos2 > 0 && _text.charCodeAt(pos2 - 1) == 92 )//\
				{
					result += _text.substring(pos1, pos2 - 1);
					result += "[";
					pos1 = pos2 + 1;
					continue;
				}

				result += _text.substring(pos1, pos2);
				pos1 = pos2;
				pos2 = _text.indexOf("]", pos1);
				if(pos2==-1)
					break;
				
				end = _text.charAt(pos1+1)=='/';
				tag = _text.substring(end?pos1+2:pos1+1, pos2);
				_readPos = pos2 + 1;
				attr = null;
				repl = null;
				pos3 = tag.indexOf("=");
				if(pos3!=-1) {
					attr = tag.substring(pos3+1);
					tag = tag.substring(0, pos3);
				}
				tag = tag.toLowerCase();
				func = _handlers[tag];
				if(func!=null) {
					repl = func(tag, end, attr);
					if(repl!=null)
						result += repl;
				}
				else
					result += _text.substring(pos1, _readPos);
				pos1 = _readPos;
			}
			
			if (pos1 < _text.length)
				result += _text.substr(pos1);
			
			_text = null;
			
			return result;
		}
	}
}