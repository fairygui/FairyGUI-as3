package fairygui
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.text.TextFieldType;
	
	import fairygui.utils.ToolSet;

	public class GTextInput extends GTextField
	{
		private var _changed:Boolean;
		private var _promptText:String;
		private var _password:Boolean;
		
		public function GTextInput()
		{
			super();
			this.focusable = true;
			
			_textField.addEventListener(KeyboardEvent.KEY_DOWN, __textChanged);
			_textField.addEventListener(Event.CHANGE, __textChanged);
			_textField.addEventListener(FocusEvent.FOCUS_IN, __focusIn);
			_textField.addEventListener(FocusEvent.FOCUS_OUT, __focusOut);
		}

		public function set maxLength(val:int):void
		{
			_textField.maxChars = val;
		}
		
		public function get maxLength():int
		{
			return _textField.maxChars;
		}
		
		public function set editable(val:Boolean):void
		{
			if(val)
			{
				_textField.type = TextFieldType.INPUT;
				_textField.selectable = true;
			}
			else
			{
				_textField.type = TextFieldType.DYNAMIC;
				_textField.selectable = false;
			}
		}
		
		public function get editable():Boolean
		{
			return _textField.type == TextFieldType.INPUT;
		}
		
		public function get promptText():String
		{
			return _promptText;
		}
		
		public function set promptText(value:String):void
		{
			_promptText = value;
			renderNow();
		}
		
		public function get restrict():String
		{
			return _textField.restrict;
		}
		
		public function set restrict(value:String):void
		{
			_textField.restrict = value;
		}
		
		public function get password():Boolean
		{
			return _password;
		}
		
		public function set password(val:Boolean):void
		{
			if(_password != val)
			{
				_password = val;
				render();
			}
		}
		
		override protected function createDisplayObject():void
		{ 
			super.createDisplayObject();
			
			_textField.type = TextFieldType.INPUT;
			_textField.selectable = true;
			_textField.mouseEnabled = true;
		}
		
		override public function get text():String
		{
			if(_changed)
			{
				_changed = false;
				_text = _textField.text.replace(/\r\n/g, "\n");
				_text = _text.replace(/\r/g, "\n");
			}
			return _text;
		}
		
		override protected function render():void
		{
			renderNow(true);
		}
		
		override protected function updateTextFormat():void
		{
			super.updateTextFormat();
			
			_textField.defaultTextFormat = _textFormat;
		}
		
		override protected function renderNow(updateBounds:Boolean=true):void
		{
			_textField.width = this.width;
			_textField.height = this.height+_fontAdjustment;
			_textField.wordWrap = !_singleLine;
			_textField.multiline = !_singleLine;
			_yOffset = -_fontAdjustment;
			_textField.y = this.y+_yOffset;
			
			if(!_text && _promptText)
			{
				_textField.displayAsPassword = false;
				_textField.htmlText = ToolSet.parseUBB(ToolSet.encodeHTML(_promptText));
			}
			else
			{
				_textField.displayAsPassword = _password;
				_textField.text = _text;
			}
			_changed = false;
		}
		
		override protected function handleSizeChanged():void
		{
			_textField.width = this.width;
			_textField.height = this.height+_fontAdjustment;
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			_promptText = xml.@prompt;
			var str:String = xml.@maxLength;
			if(str)
				_textField.maxChars = parseInt(str);
			str = xml.@restrict;
			if(str)
				_textField.restrict = str;
			_password = xml.@password=="true";
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			if(!_text)
			{
				if(_promptText)
				{
					_textField.displayAsPassword = false;
					_textField.htmlText = ToolSet.parseUBB(ToolSet.encodeHTML(_promptText));
				}			
			}
		}
		
		private function __textChanged(evt:Event):void
		{
			_changed = true;
			TextInputHistory.inst.markChanged(_textField);
		}
		
		private function __focusIn(evt:Event):void
		{
			if(!_text && _promptText)
			{
				_textField.displayAsPassword = _password;
				_textField.text = "";
			}
			TextInputHistory.inst.startRecord(_textField);
		}
		
		private function __focusOut(evt:Event):void
		{
			_text = _textField.text;
			TextInputHistory.inst.stopRecord(_textField);
			_changed = false;
			
			if(!_text && _promptText)
			{
				_textField.displayAsPassword = false;
				_textField.htmlText = ToolSet.parseUBB(ToolSet.encodeHTML(_promptText));
			}
		}
	}
}