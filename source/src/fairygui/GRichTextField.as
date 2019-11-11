package fairygui
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;
	
	import fairygui.display.UISprite;
	import fairygui.text.HtmlElement;
	import fairygui.text.HtmlNode;
	import fairygui.text.IRichTextObjectFactory;
	import fairygui.text.LinkButton;
	import fairygui.text.RichTextObjectFactory;
	import fairygui.text.XMLIterator;
	import fairygui.utils.CharSize;
	import fairygui.utils.ToolSet;
	import fairygui.utils.UBBParser;
	
	public class GRichTextField extends GTextField
	{
		private var _ALinkFormat:TextFormat;
		private var _AHoverFormat:TextFormat;	
		private var _elements:Vector.<HtmlElement>;
		private var _nodes:Vector.<HtmlNode>;
		private var _objectsContainer:Sprite;
		private var _linkButtonCache:Vector.<LinkButton>;
		
		public static var objectFactory:IRichTextObjectFactory = new RichTextObjectFactory();

		private static var _nodeCache:Vector.<HtmlNode> = new Vector.<HtmlNode>();
		private static var _elementCache:Vector.<HtmlElement> = new Vector.<HtmlElement>();
		
		public function GRichTextField()
		{
			super();
			
			_ALinkFormat = new TextFormat();
			_ALinkFormat.underline = true;
			_AHoverFormat = new TextFormat();
			_AHoverFormat.underline = true;
			
			_elements = new Vector.<HtmlElement>();
			_nodes = new Vector.<HtmlNode>();
			
			_linkButtonCache = new Vector.<LinkButton>();
		}
		
		public function get ALinkFormat():TextFormat {
			return _ALinkFormat;
		}
		
		public function set ALinkFormat(val:TextFormat):void {
			_ALinkFormat = val;
			render();
		}
		
		public function get AHoverFormat():TextFormat {
			return _AHoverFormat;
		}
		
		public function set AHoverFormat(val:TextFormat):void {
			_AHoverFormat = val;
		}
		
		override protected function createDisplayObject():void
		{
			super.createDisplayObject();
			
			_textField.mouseEnabled = true;
			
			_objectsContainer = new Sprite();
			_objectsContainer.mouseEnabled = false;
			
			var sprite:UISprite = new UISprite(this);
			sprite.mouseEnabled = false;
			sprite.addChild(_textField);
			sprite.addChild(_objectsContainer);
			setDisplayObject(sprite);
		}
		
		override protected function updateTextFieldText(textValue:String):void
		{
			destroyNodes();
			clearElements();
			
			_textField.htmlText = "";
			_textField.defaultTextFormat = _textFormat;
			
			if(!_text.length)
				return;
			
			if(_ubbEnabled)
				textValue = UBBParser.inst.parse(textValue);
			
			_textField.text = parseHtml(textValue);
			
			var i:int;
			var cnt:int = _elements.length;
			for(i=0;i<cnt;i++) 
			{
				var element:HtmlElement = _elements[i];
				if(element.textFormat && element.end>element.start)
					_textField.setTextFormat(element.textFormat, element.start, element.end);
			}
			
			createNodes();
		}
		
		private function onAddedToStage(evt:Event):void
		{
			adjustNodes();
		}
		
		override protected function doAlign():void
		{
			super.doAlign();
			
			_objectsContainer.y = _yOffset;
			
			//如果RichTextField不在舞台，那么getCharBoundaries返回的字符的位置会错误（flash 问题），
			//所以这里设了一个标志，等待加到舞台后再刷新
			if(_objectsContainer.stage==null)
				_objectsContainer.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			else
				adjustNodes();
		}
		
		override public function dispose():void
		{
			destroyNodes();
			
			super.dispose();
		}
		
		private function parseHtml(source:String):String
		{
			var skipText:int = 0;
			var ignoreWhiteSpace:Boolean = false;
			var str:String;
			var parsedText:String = "";
			var tf:TextFormat;
			var start:int;
			var element:HtmlElement;
			var skipNextCR:Boolean = false;
			
			XMLIterator.begin(source, true);
			
			while (XMLIterator.nextTag())
			{
				if (skipText == 0)
				{
					str = XMLIterator.getText(ignoreWhiteSpace);
					if (str.length > 0)
					{
						if(skipNextCR && str.charCodeAt(0)==10)
							parsedText += str.substr(1);
						else
							parsedText += str;
					}
				}
				
				skipNextCR = false;
				switch (XMLIterator.tagName)
				{
					case "b":
						if (XMLIterator.tagType == XMLIterator.TAG_START)
						{
							tf = new TextFormat();
							tf.bold = true;
							
							element = createElement();
							element.tag = XMLIterator.tagName;
							element.start = parsedText.length;
							element.end = -1;
							element.textFormat = tf;
						}
						else if (XMLIterator.tagType == XMLIterator.TAG_END)
						{
							element = findStartTag(XMLIterator.tagName);
							if(element)
								element.end = parsedText.length;
						}
						break;
					
					case "i":
						if (XMLIterator.tagType == XMLIterator.TAG_START)
						{
							element = createElement();
							element.tag = XMLIterator.tagName;
							element.start = parsedText.length;
							element.end = -1;
							
							tf = new TextFormat();
							tf.italic = true;
							element.textFormat = tf;
						}
						else if (XMLIterator.tagType == XMLIterator.TAG_END)
						{
							element = findStartTag(XMLIterator.tagName);
							if(element)
								element.end = parsedText.length;
						}
						break;
					
					case "u":
						if (XMLIterator.tagType == XMLIterator.TAG_START)
						{
							element = createElement();
							element.tag = XMLIterator.tagName;
							element.start = parsedText.length;
							element.end = -1;
							
							tf = new TextFormat();
							tf.underline = true;
							element.textFormat = tf;
						}
						else if (XMLIterator.tagType == XMLIterator.TAG_END)
						{
							element = findStartTag(XMLIterator.tagName);
							if(element)
								element.end = parsedText.length;
						}
						break;
					
					case "font":
						if (XMLIterator.tagType == XMLIterator.TAG_START)
						{
							element = createElement();
							element.tag = XMLIterator.tagName;
							element.start = parsedText.length;
							element.end = -1;
							
							tf = new TextFormat();
							var fontSize:int = XMLIterator.getAttributeInt("size", -1);
							if(fontSize>0)
							{
								tf.size = fontSize;
								if(fontSize>_maxFontSize)
									_maxFontSize = fontSize;
							}
							str = XMLIterator.getAttribute("color");
							if (str)
								tf.color = ToolSet.convertFromHtmlColor(str);
							
							str = XMLIterator.getAttribute("align");
							if(str)
								tf.align = str;
							element.textFormat = tf;
						}
						else if (XMLIterator.tagType == XMLIterator.TAG_END)
						{
							element = findStartTag(XMLIterator.tagName);
							if(element)
								element.end = parsedText.length;
						}
						break;
					
					case "br":
						parsedText += "\n";
						break;
					
					case "img":
						if (XMLIterator.tagType == XMLIterator.TAG_START || XMLIterator.tagType == XMLIterator.TAG_VOID)
						{
							str = XMLIterator.getAttribute("src");
							if(str)
							{
								element = createElement();
								element.tag = XMLIterator.tagName;
								element.start = parsedText.length;
								element.end = element.start+1;
								element.text = str;
								var pi:PackageItem = UIPackage.getItemByURL(str);
								if(pi)
								{
									element.width = pi.width;
									element.height = pi.height;
								}
								element.width = XMLIterator.getAttributeInt("width", element.width);
								element.height = XMLIterator.getAttributeInt("height", element.height);
								
								tf = new TextFormat();
								tf.font = _textFormat.font;
								fontSize = CharSize.getFontSizeByHeight(element.height, tf.font);
								tf.size = fontSize;
								if(fontSize>_maxFontSize)
									_maxFontSize = fontSize;
								tf.bold = false;
								tf.italic = false;
								tf.letterSpacing = element.width+4-CharSize.getHolderWidth(tf.font, int(tf.size));
								element.textFormat = tf;
								
								parsedText += "　";
							}
						}
						break;
					
					case "a":
						if (XMLIterator.tagType == XMLIterator.TAG_START)
						{
							element = createElement();
							element.tag = XMLIterator.tagName;
							element.start = parsedText.length;
							element.end = -1;
							element.text = XMLIterator.getAttribute("href");
							element.textFormat = _ALinkFormat;
						}
						else if (XMLIterator.tagType == XMLIterator.TAG_END)
						{
							element = findStartTag(XMLIterator.tagName);
							if(element)
								element.end = parsedText.length;
						}
						break;
					
					case "p":
						if (XMLIterator.tagType == XMLIterator.TAG_START)
						{
							if (parsedText.length && parsedText.charCodeAt(parsedText.length-1)!=10)
								parsedText += "\n";

							str = XMLIterator.getAttribute("align");
							if(str=="center" || str=="right")
							{
								element = createElement();
								element.tag = XMLIterator.tagName;
								element.start = parsedText.length;
								element.end = -1;
								
								tf = new TextFormat();
								tf.align = str;
								element.textFormat = tf;
							}
						}
						else if (XMLIterator.tagType == XMLIterator.TAG_END)
						{
							parsedText += "\n";
							skipNextCR = true;
							
							element = findStartTag(XMLIterator.tagName);
							if(element)
								element.end = parsedText.length;
						}
						break;
					
					case "ui":
					case "div":
					case "li":
						if (XMLIterator.tagType == XMLIterator.TAG_START)
						{
							if (parsedText.length && parsedText.charCodeAt(parsedText.length-1)!=10)
								parsedText += "\n";
						}
						else if (XMLIterator.tagType == XMLIterator.TAG_END)
						{
							parsedText += "\n";
							skipNextCR = true;
						}
						break;
					
					case "html":
					case "body":
						//full html
						ignoreWhiteSpace = true;
						break;
					
					case "input":
					case "select":
					case "head":
					case "style":
					case "script":
					case "form":
						if (XMLIterator.tagType == XMLIterator.TAG_START)
							skipText++;
						else if (XMLIterator.tagType == XMLIterator.TAG_END)
							skipText--;
						break;
				}
			}
			
			if (skipText == 0)
			{
				str = XMLIterator.getText(ignoreWhiteSpace);
				if (str.length > 0)
				{
					if(skipNextCR && str.charCodeAt(0)==10)
						parsedText += str.substr(1);
					else
						parsedText += str;
				}
			}
			
			return parsedText;
		}
		
		private function createElement():HtmlElement
		{
			var element:HtmlElement;
			if(_elementCache.length)
				element = _elementCache.pop();
			else
				element = new HtmlElement();
			_elements.push(element);
			return element;
		}
		
		private function createNodes():void
		{
			var cnt:int = _elements.length;
			for(var i:int=0;i<cnt;i++) 
			{
				var element:HtmlElement = _elements[i];
				if(element.tag=="a")
				{
					var start:int = element.start;
					var end:int = element.end-1;
					if(end<0)
						return;
					
					var line1:int = _textField.getLineIndexOfChar(start);
					var line2:int = _textField.getLineIndexOfChar(end);
					if(line1==line2) 
					{ //single line
						createLinkButton(start, end, element);
					}
					else
					{
						var lineOffset:int = _textField.getLineOffset(line1);
						createLinkButton(start, lineOffset+_textField.getLineLength(line1)-1, element);
						for(var j:int=line1+1;j<line2;j++)
						{
							lineOffset = _textField.getLineOffset(j);
							createLinkButton(lineOffset, lineOffset+_textField.getLineLength(j)-1, element);
						}
						createLinkButton(_textField.getLineOffset(line2), end, element);
					}
				}
				else if(element.tag=="img")
				{
					var node:HtmlNode = createNode();
					node.charStart = element.start;
					node.charEnd = element.start;
					node.element = element;
				}
			}
		}
		
		private function createNode():HtmlNode
		{
			var node:HtmlNode;
			if(_nodeCache.length)
				node = _nodeCache.pop();
			else
				node = new HtmlNode();
			_nodes.push(node);
			return node;
		}
		
		private function createLinkButton(charStart:int, charEnd:int, element:HtmlElement):void
		{
			charStart = skipLeftCR(charStart, charEnd);
			charEnd = skipRightCR(charStart, charEnd);
			
			var node:HtmlNode = createNode();
			node.charStart = charStart;
			node.charEnd = charEnd;
			node.element = element;
		}
		
		private function clearElements():void
		{
			var cnt:int = _elements.length;
			for(var i:int=0;i<cnt;i++)
			{
				var element:HtmlElement = _elements[i];
				element.textFormat = null;
				element.text = null;
				element.tag = null;
				_elementCache.push(element);
			}
			
			_elements.length = 0;
		}
		
		private function destroyNodes():void
		{
			var cnt:int = _nodes.length;
			for(var i:int=0;i<cnt;i++)
			{
				var node:HtmlNode = _nodes[i];
				if(node.displayObject!=null) {
					if(node.displayObject.parent!=null)
						_objectsContainer.removeChild(node.displayObject);
					if(node.element.tag=="a")
						_linkButtonCache.push(node.displayObject);
					else if(node.element.tag=="img")
						objectFactory.freeObject(node.displayObject);
				}
				node.reset();
				_nodeCache.push(node);
			}
			
			_nodes.length = 0;
			_objectsContainer.removeChildren();
		}
		
		private function adjustNodes():void
		{
			var cnt:int = _nodes.length;
			var rect1:Rectangle;
			var rect2:Rectangle;
			var line:int;
			for(var i:int=0;i<cnt;i++)
			{
				var node:HtmlNode = _nodes[i];
				var element:HtmlElement = node.element;
				if(element.tag=="a") 
				{
					if(node.displayObject==null)
					{
						var btn:LinkButton;
						if(_linkButtonCache.length)
							btn = _linkButtonCache.pop();
						else 
						{
							btn = new LinkButton();
							btn.addEventListener(MouseEvent.ROLL_OVER, onLinkRollOver);
							btn.addEventListener(MouseEvent.ROLL_OUT, onLinkRollOut);
							btn.addEventListener(MouseEvent.CLICK, onLinkClick);
						}
						btn.owner = node;
						node.displayObject = btn;
					}
					
					rect1 = _textField.getCharBoundaries(node.charStart);
					if(rect1==null)
						return;
					rect2 = _textField.getCharBoundaries(node.charEnd);
					if(rect2==null)
						return;
					
					line = _textField.getLineIndexOfChar(node.charStart);
					var lm:TextLineMetrics = _textField.getLineMetrics(line);

					var w:int = rect2.right-rect1.left;
					if(rect1.left+w>_textField.width-2)
						w = _textField.width-rect1.left-2;					
					node.displayObject.x = rect1.left;
					LinkButton(node.displayObject).setSize(w, lm.height);
					if(rect1.top<rect2.top)
						node.topY = 0;
					else
						node.topY = rect2.top-rect1.top;
					
					node.displayObject.y = rect1.top + node.topY;
					if(isLineVisible(line))
					{
						if(node.displayObject.parent==null)
							_objectsContainer.addChild(node.displayObject);
					}
					else
					{
						if(node.displayObject.parent) 
							_objectsContainer.removeChild(node.displayObject);
					}
				}
				else if(element.tag=="img")
				{
					if(node.displayObject==null) 
					{
						var obj:DisplayObject = objectFactory.createObject(element.text, element.width, element.height);
						node.displayObject = obj;
					}
					
					rect1 = _textField.getCharBoundaries(node.charStart);
					if(rect1==null)
						return;
					
					line = _textField.getLineIndexOfChar(node.charStart);
					
					var tm:TextLineMetrics = _textField.getLineMetrics(line);
					if(tm==null)
						return;
					
					node.displayObject.x = rect1.left + 2;
					if(element.height<tm.ascent)
						node.displayObject.y = rect1.top+tm.ascent-element.height;
					else
						node.displayObject.y = rect1.bottom-element.height;
					if(isLineVisible(line) && node.displayObject.x+element.width<_textField.width-2) 
					{
						if(node.displayObject.parent==null)
							_objectsContainer.addChildAt(node.displayObject, _objectsContainer.numChildren);
					}
					else
					{
						if(node.displayObject.parent) 
							_objectsContainer.removeChild(node.displayObject);
					}
				}
			}
		}
		
		private function findStartTag(tagName:String):HtmlElement
		{
			var cnt:int = _elements.length;
			for(var i:int=cnt-1;i>=0;i--)
			{
				var element:HtmlElement = _elements[i];
				if(element.tag==tagName && element.end==-1)
					return element;
			}
			
			return null;
		}
		
		private function isLineVisible(line:int):Boolean
		{
			return line>=_textField.scrollV-1 && line<=_textField.bottomScrollV-1;
		}
		
		private function skipLeftCR(start:int, end:int):int
		{
			var text:String = _textField.text;
			for(var i:int=start;i<end;i++) 
			{
				var c:String = text.charAt(i);
				if(c!="\r" && c!="\n")
					break;
			}
			return i;
		}
		
		private function skipRightCR(start:int, end:int):int
		{
			var text:String = _textField.text;
			for(var i:int=end;i>start;i--) 
			{
				var c:String = text.charAt(i);
				if(c!="\r" && c!="\n")
					break;
			}
			return i;
		}
		
		private function onLinkRollOver(evt:Event):void 
		{
			var node:HtmlNode = LinkButton(evt.currentTarget).owner;
			if(_AHoverFormat)
				_textField.setTextFormat(_AHoverFormat, node.element.start, node.element.end);
		}
		
		private function onLinkRollOut(evt:Event):void 
		{
			var node:HtmlNode = LinkButton(evt.currentTarget).owner;
			if(!node.displayObject || !node.displayObject.stage)
				return;
			
			if(_AHoverFormat && _ALinkFormat)
				_textField.setTextFormat(_ALinkFormat, node.element.start, node.element.end);
		}
		
		private function onLinkClick(evt:Event):void
		{
			evt.stopPropagation();
			
			var node:HtmlNode = LinkButton(evt.currentTarget).owner;
			var url:String = node.element.text;
			var i:int = url.indexOf("event:");
			if(i==0)
			{
				url = url.substring(6);
				this.displayObject.dispatchEvent(new TextEvent(TextEvent.LINK, true, false, url));
			}
			else
				flash.net.navigateToURL(new URLRequest(url), "_blank");
		}
	}
}
