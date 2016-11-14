package fairygui.extention.text
{
	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-8-12下午3:00:02 <br/>
	 **/
	import fairygui.GLabel;
	import fairygui.GTextField;
	import fairygui.ScrollPane;
	import fairygui.VertAlignType;
	import fairygui.display.UITextField;
	import fairygui.utils.GTimers;
	
	public final class TextAreaExtention extends GLabel
	{
		private var _uiTextField:UITextField;
		private var _gTextField:GTextField;
		private var _scrollPanel:ScrollPane;
		public function TextAreaExtention()
		{
			super();
		}
		//***************
		//internal
		//***************
		
		//***************
		//noticeHandler
		//***************
		
		//***************
		//protected
		//***************
		
		//***************
		//private
		//***************
		private function Align():void
		{
			//垂直居中对齐
			if(_gTextField!=null)
			{
				switch(_gTextField.verticalAlign)
				{
					case	VertAlignType.Middle:
					{
						if(_gTextField.height >= height) _gTextField.y = 0;
						else _gTextField.y = height - _gTextField.height >> 1;
					}
						break;
					case	VertAlignType.Top:
					{
						_gTextField.y = 0;
						_gTextField.removeSizeChangeCallback(GTextFieldSizeChange);
					}
						break;
					case	VertAlignType.Bottom: _gTextField.y = height - _gTextField.height;
						break;
				}
			}
		}
		//***************
		//eventHandler
		//***************
		private function GTextFieldSizeChange():void
		{
			Align();
		}
		//***************
		//public
		//***************
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			var label:GLabel = getChild("title").asLabel;
			if(label)
			{
				_scrollPanel = label.scrollPane;
				_titleObject = label.getChild("title");
				_iconObject = label.getChild("icon");
				if(_titleObject!=null)
				{
					_gTextField = _titleObject.asTextField;
					if(_gTextField!=null)
					{ _uiTextField = _gTextField.displayObject as UITextField; }
					_gTextField.addSizeChangeCallback(GTextFieldSizeChange);
				}
			}
		}
		override public function set title(value:String):void
		{
			super.title = value;
			GTimers.inst.add(0, 1, Align);
		}
		public function set selectable(value:Boolean):void
		{
			if(_uiTextField)
			{
				_uiTextField.mouseEnabled = value;
				_uiTextField.selectable = value;
			}
		}
		public function set bouncebackEffect(value:Boolean):void
		{
			if(_scrollPanel!=null) _scrollPanel.bouncebackEffect = value;
		}
		public function set touchEffect(value:Boolean):void
		{
			if(_scrollPanel!=null) _scrollPanel.touchEffect = value;
		}
		public function set alignH(value:uint):void
		{
			if(_gTextField!=null) _gTextField.align = value;
		}
		public function set alignV(value:uint):void
		{
			if(_gTextField!=null && _gTextField.verticalAlign!=value)
			{
				_gTextField.verticalAlign = value;
				Align();
				value==VertAlignType.Middle && _gTextField.addSizeChangeCallback(Align);
			}
		}
		
		override public function dispose():void
		{
			_gTextField!=null && _gTextField.removeSizeChangeCallback(GTextFieldSizeChange);
			_gTextField = null;
			_uiTextField = null;
			_scrollPanel = null;
			super.dispose();
		}
	}
}