package fairygui
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	
	import fairygui.display.UITextField;

	public class GTextInput extends GTextField
	{
		protected var _textField:TextField;
		private var _changed:Boolean;
		
		public function GTextInput()
		{
			super();
			
			_textField.addEventListener(KeyboardEvent.KEY_DOWN, __textChanged);
			_textField.addEventListener(Event.CHANGE, __textChanged);
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
		
		override protected function createDisplayObject():void
		{ 
			_textField = new UITextField(this);
			_textField.type = TextFieldType.INPUT;
			setDisplayObject(_textField);
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
		
		override protected function updateTextFormat():void
		{
			super.updateTextFormat();
			
			_textField.width = this.width*GRoot.contentScaleFactor;
			_textField.height = (this.height+_fontAdjustment)*GRoot.contentScaleFactor;
			_textField.defaultTextFormat = _textFormat;
			_textField.displayAsPassword = this.displayAsPassword;
			_textField.wordWrap = !_singleLine;
			_textField.multiline = !_singleLine;
			_yOffset = -_fontAdjustment;
			_textField.y = this.y*GRoot.contentScaleFactor+_yOffset;
		}
		
		override protected function render():void
		{
			renderNow(true);
		}
		
		override protected function renderNow(updateBounds:Boolean=true):void
		{
			_textField.text = _text;
			_changed = false;
		}
		
		override protected function handleSizeChanged():void
		{
			_textField.width = this.width*GRoot.contentScaleFactor;
			_textField.height = this.height*GRoot.contentScaleFactor+_fontAdjustment;
		}
		
		private function __textChanged(evt:Event):void
		{
			_changed = true;
		}
	}
}