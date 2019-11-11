package fairygui
{
	import flash.display.BitmapData;
	import flash.filters.DropShadowFilter;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import fairygui.display.UIImage;
	import fairygui.display.UITextField;
	import fairygui.text.BMGlyph;
	import fairygui.text.BitmapFont;
	import fairygui.utils.CharSize;
	import fairygui.utils.FontUtils;
	import fairygui.utils.GTimers;
	import fairygui.utils.ToolSet;
	import fairygui.utils.UBBParser;

	public class GTextField extends GObject
	{
		protected var _ubbEnabled:Boolean;
		protected var _autoSize:int;
		protected var _widthAutoSize:Boolean;
		protected var _heightAutoSize:Boolean;
		protected var _textFormat:TextFormat;
		protected var _text:String;
		protected var _font:String;
		protected var _fontSize:int;
		protected var _align:int;
		protected var _verticalAlign:int;
		protected var _color:uint;
		protected var _leading:int;
		protected var _letterSpacing:int;
		protected var _underline:Boolean;
		protected var _bold:Boolean;
		protected var _italic:Boolean;
		protected var _singleLine:Boolean;
		protected var _stroke:int;
		protected var _strokeColor:uint;
		protected var _shadowOffset:Point;
		protected var _textFilters:Array;
		protected var _templateVars:Object;

		protected var _textField:TextField;
		protected var _bitmap:UIImage;
		protected var _bitmapData:BitmapData;

		protected var _updatingSize:Boolean;
		protected var _requireRender:Boolean;
		protected var _sizeDirty:Boolean;
		protected var _textWidth:int;
		protected var _textHeight:int;
		protected var _fontAdjustment:int;
		protected var _maxFontSize:int;
		
		protected var _bitmapFont:BitmapFont;
		protected var _lines:Vector.<LineInfo>;
		
		private static const GUTTER_X:int = 2;
		private static const GUTTER_Y:int = 2;
		
		public function GTextField()
		{
			super();
			
			_textFormat = new TextFormat();
			_fontSize = 12;
			_color = 0;
			_align = AlignType.Left;
			_verticalAlign = VertAlignType.Top;
			_text = "";
			_leading = 3;
			
			_autoSize= AutoSizeType.Both;
			_widthAutoSize = true;
			_heightAutoSize = true;
			updateAutoSize();
		}
		
		override protected function createDisplayObject():void
		{ 
			_textField = new UITextField(this);
			_textField.mouseEnabled = false;
			_textField.selectable = false;
			_textField.multiline = true;
			_textField.width = 10;
			_textField.height = 1;
			setDisplayObject(_textField);
		}
		
		private function switchBitmapMode(value:Boolean):void
		{
			if(value && this.displayObject==_textField)
			{
				if(_bitmap==null)
					_bitmap = new UIImage(this);
				switchDisplayObject(_bitmap);
			}
			else if(!value && this.displayObject==_bitmap)
				switchDisplayObject(_textField);
		}
		
		override public function dispose():void
		{
			super.dispose();
			if(_bitmapData)
			{
				_bitmapData.dispose();
				_bitmapData = null;
			}
			_requireRender = false;
			_bitmapFont = null;
		}

		override public function set text(value:String):void
		{
			_text = value;
			if(_text==null)
				_text = "";
			updateGear(6);
			
			if(parent && parent._underConstruct)
				renderNow();
			else
				render();
		}
		
		override public function get text():String
		{
			return _text;
		}
		
		final public function get font():String
		{
			return _font;
		}
		
		public function set font(value:String):void
		{
			if(_font!=value)
			{
				_font = value;
				updateTextFormat();
			}
		}
		
		final public function get fontSize():int
		{
			return _fontSize;
		}
		
		public function set fontSize(value:int):void
		{
			if(value<0)
				return;
			
			if(_fontSize!=value)
			{
				_fontSize = value;
				updateTextFormat();
			}
		}
		
		final public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void
		{
			if(_color!=value)
			{
				_color = value;
				updateGear(4);
				updateTextFormat();
			}
		}
		
		final public function get align():int
		{
			return _align;
		}
		
		public function set align(value:int):void
		{
			if(_align!=value)
			{
				_align = value;
				updateTextFormat();
			}
		}
		
		final public function get verticalAlign():int
		{
			return _verticalAlign;
		}
		
		public function set verticalAlign(value:int):void
		{
			if(_verticalAlign!=value)
			{
				_verticalAlign = value;
				doAlign();
			}
		}
		
		final public function get leading():int
		{
			return _leading;
		}
		
		public function set leading(value:int):void
		{
			if(_leading!=value)
			{
				_leading = value;
				updateTextFormat();
			}
		}
		
		final public function get letterSpacing():int
		{
			return _letterSpacing;
		}
		
		public function set letterSpacing(value:int):void
		{
			if(_letterSpacing!=value)
			{
				_letterSpacing = value;
				updateTextFormat();
			}
		}

		final public function get underline():Boolean
		{
			return _underline;
		}
		
		public function set underline(value:Boolean):void
		{
			if(_underline!=value)
			{
				_underline = value;
				updateTextFormat();
			}
		}
		
		final public function get bold():Boolean
		{
			return _bold;
		}
		
		public function set bold(value:Boolean):void
		{
			if(_bold!=value)
			{
				_bold = value;
				updateTextFormat();
			}
		}
		
		final public function get italic():Boolean
		{
			return _italic;
		}
		
		public function set italic(value:Boolean):void
		{
			if(_italic!=value)
			{
				_italic = value;
				updateTextFormat();
			}
		}
		
		public function get singleLine():Boolean
		{
			return _singleLine;
		}
		
		public function set singleLine(value:Boolean):void
		{
			if(_singleLine!=value)
			{
				_singleLine = value;
				_textField.multiline = !_singleLine;
				if(!_widthAutoSize)
					_textField.wordWrap = !_singleLine;
				
				if(!_underConstruct)
					render();
			}
		}
		
		final public function get stroke():int
		{
			return _stroke;
		}
		
		public function set stroke(value:int):void
		{
			if(_stroke!=value)
			{
				_stroke = value;
				updateTextFilters();
			}
		}
		
		final public function get strokeColor():uint
		{
			return _strokeColor;
		}
		
		public function set strokeColor(value:uint):void
		{
			if(_strokeColor!=value)
			{
				_strokeColor = value;
				updateTextFilters();
				updateGear(4);
			}
		}
		
		final public function get shadowOffset():Point
		{
			return _shadowOffset;
		}
		
		public function set shadowOffset(value:Point):void
		{
			_shadowOffset = value;
			updateTextFilters();
		}
		
		private function updateTextFilters():void
		{
			if(_stroke && _shadowOffset!=null)
				_textFilters =  [
					new DropShadowFilter(_stroke, 45, _strokeColor, 1, 1, 1, 5, 1),
					new DropShadowFilter(_stroke, 222, _strokeColor, 1, 1, 1, 5, 1),
					new DropShadowFilter(Math.sqrt(Math.pow(_shadowOffset.x, 2)+Math.pow(_shadowOffset.y,2)), 
						Math.atan2(_shadowOffset.y, _shadowOffset.x)*ToolSet.RAD_TO_DEG, _strokeColor, 1, 1, 2)
				];
			else if(_stroke)
				_textFilters =  [
					new DropShadowFilter(_stroke, 45, _strokeColor, 1, 1, 1, 5, 1),
					new DropShadowFilter(_stroke, 222, _strokeColor, 1, 1, 1, 5, 1)
				];
			else if(_shadowOffset!=null)
				_textFilters =  [
					new DropShadowFilter(Math.sqrt(Math.pow(_shadowOffset.x, 2)+Math.pow(_shadowOffset.y,2)), 
						Math.atan2(_shadowOffset.y, _shadowOffset.x)*ToolSet.RAD_TO_DEG, _strokeColor, 1, 1, 2)
				];
			else
				_textFilters = null;
			
			_textField.filters = _textFilters;
		}
		
		public function set ubbEnabled(value:Boolean):void
		{
			if(_ubbEnabled!=value)
			{
				_ubbEnabled = value;
				render();
			}
		}
		
		final public function get ubbEnabled():Boolean
		{
			return _ubbEnabled;
		}
		
		public function set autoSize(value:int):void
		{
			if(_autoSize!=value)
			{
				_autoSize = value;
				_widthAutoSize = value==AutoSizeType.Both;
				_heightAutoSize = value==AutoSizeType.Both||value==AutoSizeType.Height;
				updateAutoSize();
				render();
			}
		}
		
		final public function get autoSize():int
		{
			return _autoSize;
		}
		
		public function get textWidth():int
		{
			if(_requireRender)
				renderNow();
			return _textWidth;
		}
		
		override public function ensureSizeCorrect():void
		{
			if(_sizeDirty && _requireRender)
				renderNow();
		}
		
		protected function updateTextFormat():void
		{
			_textFormat.size = _fontSize;
			if(ToolSet.startsWith(_font, "ui://") && !(this is GRichTextField)/*not supported*/)
			{
				_bitmapFont = UIPackage.getBitmapFontByURL(_font);
				_fontAdjustment = 0;
			}
			else
			{
				_bitmapFont = null;
				
				if(_font)
					_textFormat.font = _font;
				else
					_textFormat.font = UIConfig.defaultFont;
				
				var charSize:Object = CharSize.getSize(int(_textFormat.size), _textFormat.font, _bold);
				_fontAdjustment = charSize.yIndent;
			}
			
			if(this.grayed)
				_textFormat.color = 0xAAAAAA;
			else
				_textFormat.color = _color;
			_textFormat.align = AlignType.toString(_align);
			_textFormat.leading = _leading-_fontAdjustment;
			_textFormat.letterSpacing = _letterSpacing;
			_textFormat.bold = _bold;
			_textFormat.underline = _underline;
			_textFormat.italic = _italic;
			
			_textField.defaultTextFormat = _textFormat;
			_textField.embedFonts = FontUtils.isEmbeddedFont(_textFormat);
			
			if(!_underConstruct)
				render();
		}
		
		protected function updateAutoSize():void
		{
			if(_widthAutoSize)
			{
				_textField.autoSize = TextFieldAutoSize.LEFT;
				_textField.wordWrap = false;
			}
			else
			{
				_textField.autoSize = TextFieldAutoSize.NONE;
				_textField.wordWrap = !_singleLine;
			}
		}
		
		protected function render():void
		{
			if(!_requireRender)
			{
				_requireRender = true;
				GTimers.inst.add(0, 1, __render);
			}
			
			if(!_sizeDirty && (_widthAutoSize || _heightAutoSize))
			{
				_sizeDirty = true;
				_dispatcher.dispatch(this, GObject.SIZE_DELAY_CHANGE);
			}
		}
		
		private function __render():void
		{
			if(_requireRender)
				renderNow();
		}
		
		protected function updateTextFieldText(value:String):void
		{
			if(_ubbEnabled)
			{
				_textField.htmlText = UBBParser.inst.parse(ToolSet.encodeHTML(value));
				_maxFontSize = Math.max(_maxFontSize, UBBParser.inst.maxFontSize);
			}
			else
				_textField.text = value;
		}

		protected function renderNow():void
		{
			_requireRender = false;
			_sizeDirty = false;
			
			if(_bitmapFont!=null)
			{
				renderWithBitmapFont();
				return;
			}
			
			switchBitmapMode(false);
			
			var w:Number, h:Number;
			w = _width;
			if(w!=_textField.width)
				_textField.width = w;
			h = Math.max(_height, int(_textFormat.size));
			if(h!=_textField.height)
				_textField.height = h;
			_textField.defaultTextFormat = _textFormat;
			_maxFontSize = int(_textFormat.size);
			
			var text2:String = _text;
			if (_templateVars != null)
				text2 = parseTemplate(text2);
			updateTextFieldText(text2);
			
			_textWidth = Math.ceil(_textField.textWidth);
			if(_textWidth>0)
				_textWidth+=5;
			_textHeight = Math.ceil(_textField.textHeight);
			if(_textHeight>0)
			{
				if(_textField.numLines==1) //单行时文本高度的测算可能受leading的影响（flash问题），所以不使用textHeight
				{
					_textHeight = CharSize.getSize(_maxFontSize, _textFormat.font, _textFormat.bold).height;
				}
				_textHeight += 4;
			}

			if(_widthAutoSize)
				w = _textWidth;
			else
				w = _width;

			if(_heightAutoSize)
				h = _textHeight;
			else
				h = _height;

			if(maxHeight>0 && h>maxHeight)
				h = maxHeight;
			if(_textHeight>h)
				_textHeight = h;
			
			_textField.height = _textHeight + _fontAdjustment + 3;

			if(_widthAutoSize || _heightAutoSize)
			{
				_updatingSize = true;
				if(_parent && _parent._underConstruct
					&& _rawWidth==w && _rawHeight==h)
					_dispatcher.dispatch(this, SIZE_CHANGED);
				else
					setSize(w,h);
				_updatingSize = false;
			}
			
			doAlign();
		}
		
		private function renderWithBitmapFont():void
		{
			switchBitmapMode(true);
			
			if(!_lines)
				_lines = new Vector.<LineInfo>();
			else
				LineInfo.returnList(_lines);
			
			var letterSpacing:int = _letterSpacing;
			var lineSpacing:int = _leading - 1;
			var rectWidth:int = this.width - GUTTER_X * 2;
			var lineWidth:int = 0, lineHeight:int = 0, lineTextHeight:int = 0;
			var glyphWidth:int = 0, glyphHeight:int = 0;
			var wordChars:int = 0, wordStart:int = 0, wordEnd:int = 0;
			var lastLineHeight:int = 0;
			var lineBuffer:String = "";
			var lineY:int = GUTTER_Y;
			var line:LineInfo;
			var wordWrap:Boolean = !_widthAutoSize && !_singleLine;
			var fontScale:Number =  _bitmapFont.resizable?_fontSize/_bitmapFont.size:1;
			_textWidth = 0;
			_textHeight = 0;
			
			var text2:String = _text;
			if (_templateVars != null)
				text2 = parseTemplate(text2);
			var textLength:int = text2.length;
			for (var offset:int = 0; offset < textLength; ++offset)
			{
				var ch:String = text2.charAt(offset);
				var cc:int = ch.charCodeAt(0);
				
				if (cc == 10) //\n
				{
					lineBuffer += ch;
					line = LineInfo.borrow();
					line.width = lineWidth;
					if (lineTextHeight == 0)
					{
						if (lastLineHeight == 0)
							lastLineHeight = _fontSize;
						if (lineHeight == 0)
							lineHeight = lastLineHeight;
						lineTextHeight = lineHeight;
					}
					line.height = lineHeight;
					lastLineHeight = lineHeight;
					line.textHeight = lineTextHeight;
					line.text = lineBuffer;
					line.y = lineY;
					lineY += (line.height + lineSpacing);
					if (line.width > _textWidth)
						_textWidth = line.width;
					_lines.push(line);
					
					lineBuffer = "";
					lineWidth = 0;
					lineHeight = 0;
					lineTextHeight = 0;
					wordChars = 0;
					wordStart = 0;
					wordEnd = 0;
					continue;
				}
				
				if (cc>=65 && cc<=90 || cc>=97 && cc<=122) //a-z,A-Z
				{
					if (wordChars == 0)
						wordStart = lineWidth;
					wordChars++;
				}
				else
				{
					if (wordChars > 0)
						wordEnd = lineWidth;
					wordChars = 0;
				}

				if(cc==32) //space
				{
					glyphWidth = Math.ceil(_fontSize/2);
					glyphHeight = _fontSize;
				}
				else
				{
					var glyph:BMGlyph = _bitmapFont.glyphs[ch];
					if(glyph)
					{
						glyphWidth = Math.ceil(glyph.advance*fontScale);
						glyphHeight = Math.ceil(glyph.lineHeight*fontScale);
					}
					else
					{
						glyphWidth = 0;
						glyphHeight = 0;
					}
				}
				if (glyphHeight > lineTextHeight)
					lineTextHeight = glyphHeight;
				
				if (glyphHeight > lineHeight)
					lineHeight = glyphHeight;
				
				if (lineWidth != 0)
					lineWidth += letterSpacing;
				lineWidth += glyphWidth;
				
				if (!wordWrap || lineWidth <= rectWidth)
				{
					lineBuffer += ch;
				}
				else
				{
					line = LineInfo.borrow();
					line.height = lineHeight;
					line.textHeight = lineTextHeight;
					
					if (lineBuffer.length == 0) //the line cannt fit even a char
					{
						line.text = ch;
					}
					else if (wordChars > 0 && wordEnd > 0) //if word had broken, move it to new line
					{
						lineBuffer += ch;
						var len:int = lineBuffer.length - wordChars;
						line.text = ToolSet.trimRight(lineBuffer.substr(0, len));
						line.width = wordEnd;
						lineBuffer = lineBuffer.substr(len);	
						lineWidth -= wordStart;
					}
					else
					{
						line.text = lineBuffer;
						line.width = lineWidth - (glyphWidth + letterSpacing);
						lineBuffer = ch;
						lineWidth = glyphWidth;
						lineHeight = glyphHeight;
						lineTextHeight = glyphHeight;
					}
					line.y = lineY;
					lineY += (line.height + lineSpacing);
					if (line.width > _textWidth)
						_textWidth = line.width;
					
					wordChars = 0;
					wordStart = 0;
					wordEnd = 0;
					_lines.push(line);
				}
			}
			
			if (lineBuffer.length > 0)
			{
				line = LineInfo.borrow();
				line.width = lineWidth;
				if (lineHeight == 0)
					lineHeight = lastLineHeight;
				if (lineTextHeight == 0)
					lineTextHeight = lineHeight;
				line.height = lineHeight;
				line.textHeight = lineTextHeight;
				line.text = lineBuffer;
				line.y = lineY;
				if (line.width > _textWidth)
					_textWidth = line.width;
				_lines.push(line);
			}
			
			if (_textWidth > 0)
				_textWidth += GUTTER_X * 2;
			
			var count:int = _lines.length;
			if(count==0)
			{
				_textHeight = 0;
			}
			else
			{
				line = _lines[_lines.length - 1];
				_textHeight = line.y + line.height + GUTTER_Y;
			}
			
			var w:int, h:int;
			if(_widthAutoSize)
				w = _textWidth;
			else
				w = _width;
			if(_heightAutoSize)
				h = _textHeight;
			else
				h = _height;
			if(maxHeight>0 && h>maxHeight)
				h = maxHeight;
			
			if(_widthAutoSize || _heightAutoSize)
			{
				_updatingSize = true;
				if(_parent && _parent._underConstruct
					&& _rawWidth==w && _rawHeight==h)
					_dispatcher.dispatch(this, SIZE_CHANGED);
				else
					setSize(w,h);
				_updatingSize = false;
			}
			
			doAlign();
			
			if(_bitmapData!=null)
				_bitmapData.dispose();
			
			if(w==0 || h==0)
				return;
			
			_bitmapData = new BitmapData(w, h, true, 0);
			
			var charX:int = GUTTER_X;
			var lineIndent:int;
			var charIndent:int;
			rectWidth = this.width - GUTTER_X * 2;
			
			var lineCount:int = _lines.length;
			for(var i:int=0;i<lineCount;i++)
			{
				line = _lines[i];
				charX = GUTTER_X;
				
				if (_align == AlignType.Center)
					lineIndent = (rectWidth - line.width) / 2;
				else if (_align == AlignType.Right)
					lineIndent = rectWidth - line.width;
				else
					lineIndent = 0;
				textLength = line.text.length;
				for (var j:int = 0; j < textLength; j++)
				{
					ch = line.text.charAt(j);
					cc = ch.charCodeAt(0);
					
					if(cc==10)
						continue;
					
					if(cc==32)
					{
						charX += _letterSpacing + Math.ceil(_fontSize/2);
						continue;
					}
					
					glyph = _bitmapFont.glyphs[ch];
					if (glyph != null)
					{
						charIndent = (line.height + line.textHeight) / 2 - Math.ceil(glyph.lineHeight*fontScale);
						_bitmapFont.draw(_bitmapData, glyph, charX + lineIndent, line.y + charIndent, _color, fontScale);
						
						charX += letterSpacing + Math.ceil(glyph.advance*fontScale);
					}
					else
					{
						charX += letterSpacing;
					}
				}//text loop
			}//line loop
			
			_bitmap.bitmapData = _bitmapData;
			_bitmap.smoothing = true;
		}
		
		protected function parseTemplate(template:String):String
		{
			var pos1:int = 0, pos2:int, pos3:int;
			var tag:String;
			var value:String;
			var result:String = "";
			while((pos2=template.indexOf("{", pos1))!=-1) {
				if (pos2 > 0 && template.charCodeAt(pos2 - 1) == 92 )//\
				{
					result += template.substring(pos1, pos2 - 1);
					result += "{";
					pos1 = pos2 + 1;
					continue;
				}
				
				result += template.substring(pos1, pos2);
				pos1 = pos2;
				pos2 = template.indexOf("}", pos1);
				if(pos2==-1)
					break;
				
				if(pos2==pos1+1)
				{
					result += template.substr(pos1, 2);
					pos1 = pos2+1;
					continue;
				}
				
				tag = template.substring(pos1+1, pos2);
				pos3 = tag.indexOf("=");
				if(pos3!=-1)
				{
					value = _templateVars[tag.substring(0, pos3)];
					if(value==null)
						result += tag.substring(pos3+1);
					else
						result += value;
				}
				else
				{
					value = _templateVars[tag];
					if(value!=null)
						result += value;
				}
				pos1 = pos2+1;
			}
			
			if (pos1 < template.length)
				result += template.substr(pos1);
			
			return result;
		}
		
		public function get templateVars():Object
		{
			return _templateVars;
		}
		
		public function set templateVars(value:Object):void
		{
			if(_templateVars==null && value==null)
				return;
			
			_templateVars = value;
			flushVars();
		}
		
		public function setVar(name:String, value:String):GTextField
		{
			if(!_templateVars)
				_templateVars = {};
			_templateVars[name] = value;
			
			return this;
		}
		
		public function flushVars():void
		{
			render();
		}
		
		override protected function handleSizeChanged():void
		{
			if(!_updatingSize)
			{
				if(!_widthAutoSize)
					render();
				else
					doAlign();
			}
		}
		
		override protected function handleGrayedChanged():void
		{
			if(_bitmapFont)
				super.handleGrayedChanged();
			updateTextFormat();
		}
		
		protected function doAlign():void
		{
			if(_verticalAlign==VertAlignType.Top)
				_yOffset = 0;
			else
			{
				var dh:Number;
				if(_textHeight==0)
					dh = this.height-int(_textFormat.size);
				else
					dh = this.height-_textHeight;
				if(_verticalAlign==VertAlignType.Middle)
					_yOffset = int(dh/2);
				else
					_yOffset = int(dh);
			}
			
			_yOffset -=_fontAdjustment;
			displayObject.y = this.y+_yOffset;
		}

		override public function getProp(index:int):*
		{
			switch(index)
			{
				case ObjectPropID.Color:
					return this.color;
				case ObjectPropID.OutlineColor:
					return this.strokeColor;
				case ObjectPropID.FontSize:
					return this.fontSize;
				default:
					return super.getProp(index);
			}
		}

		override public function setProp(index:int, value:*):void
		{
			switch(index)
			{
				case ObjectPropID.Color:
					this.color = value;
					break;
				case ObjectPropID.OutlineColor:
					this.strokeColor = value;
					break;
				case ObjectPropID.FontSize:
					this.fontSize = value;
					break;
				default:
					super.setProp(index, value);
					break;
			}
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);

			var str:String;
			var arr:Array;
			
			str = xml.@font;
			if(str)
				_font = str;
			
			str = xml.@fontSize;
			if(str)
				_fontSize = parseInt(str);

			str = xml.@color;
			if(str)
				_color = ToolSet.convertFromHtmlColor(str);
			
			str = xml.@align;
			if(str)
				_align = AlignType.parse(str);
			
			str = xml.@vAlign;
			if(str)
				_verticalAlign = VertAlignType.parse(str);
			
			str = xml.@leading;
			if(str)
				_leading = parseInt(str);
			else
				_leading = 3;
			
			str = xml.@letterSpacing;
			if(str)
				_letterSpacing = parseInt(str);
			
			_ubbEnabled = xml.@ubb=="true";
			
			str = xml.@autoSize;
			if(str)
			{
				_autoSize = AutoSizeType.parse(str);
				_widthAutoSize = _autoSize==AutoSizeType.Both;
				_heightAutoSize = _autoSize==AutoSizeType.Both||_autoSize==AutoSizeType.Height;
				updateAutoSize();
			}

			_underline = xml.@underline == "true";
			_italic = xml.@italic == "true";
			_bold = xml.@bold == "true";
			this.singleLine = xml.@singleLine == "true";
			str = xml.@strokeColor;
			if(str)
			{
				_strokeColor = ToolSet.convertFromHtmlColor(str);
				str = xml.@strokeSize;
				if(str)
					_stroke = parseInt(str);
				else
					_stroke = 1;
			}
			
			str = xml.@shadowColor;
			if(str)
			{
				if(!_stroke)
					_strokeColor = ToolSet.convertFromHtmlColor(str);
				str = xml.@shadowOffset;
				if(str)
				{
					arr = str.split(",");
					_shadowOffset = new Point(parseFloat(arr[0]), parseFloat(arr[1]));
				}
			}
			
			if(_stroke || _shadowOffset!=null)
				updateTextFilters();
			
			if(xml.@vars=="true")
				_templateVars = {};
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			updateTextFormat();
			
			var str:String = xml.@text;
			if(str)
				this.text = str;

			_sizeDirty = false;
		}
	}
}

class LineInfo
{
	public var width:int;
	public var height:int;
	public var textHeight:int;
	public var text:String;
	public var y:int;
	
	private static var pool:Array = [];
	
	public static function borrow():LineInfo
	{
		if(pool.length)
		{
			var ret:LineInfo = pool.pop();
			ret.width = 0;
			ret.height = 0;
			ret.textHeight = 0;
			ret.text = null;
			ret.y = 0;
			return ret;
		}
		else
			return new LineInfo();
	}
	
	public static function returns(value:LineInfo):void
	{
		pool.push(value);
	}
	
	public static function returnList(value:Vector.<LineInfo>):void
	{
		for each(var li:LineInfo in value)
		{
			pool.push(li);
		}
		value.length = 0;
	}
	
	public function LineInfo()
	{
	}
}

