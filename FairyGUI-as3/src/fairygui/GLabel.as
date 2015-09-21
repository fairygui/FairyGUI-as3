package fairygui
{
	import fairygui.utils.ToolSet;
	
	public class GLabel extends GComponent
	{
		protected var _titleObject:GObject;
		protected var _iconObject:GObject;
		
		public function GLabel()
		{
			super();
		}
		
		final public function get icon():String
		{
			if(_iconObject is GLoader)
				return GLoader(_iconObject).url;
			else if(_iconObject is GLabel)
				return GLabel(_iconObject).icon;
			else if(_iconObject is GButton)
				return GButton(_iconObject).icon;
			else
				return null;
		}
		
		public function set icon(value:String):void
		{
			if(_iconObject is GLoader)
				GLoader(_iconObject).url = value;
			else if(_iconObject is GLabel)
				GLabel(_iconObject).icon = value;
			else if(_iconObject is GButton)
				GButton(_iconObject).icon = value;
		}
		
		final public function get title():String
		{
			if(_titleObject)
				return _titleObject.text;
			else
				return null;
		}
		
		public function set title(value:String):void
		{
			if(_titleObject)
				_titleObject.text = value;
		}
		
		override final public function get text():String
		{
			return this.title;
		}
		
		override public function set text(value:String):void
		{
			this.title = value;
		}
		
		final public function get titleColor():uint
		{
			if(_titleObject is GTextField)
				return GTextField(_titleObject).color;
			else if(_titleObject is GLabel)
				return GLabel(_titleObject).titleColor;
			else if(_titleObject is GButton)
				return GButton(_titleObject).titleColor;
			else
				return 0;
		}
		
		public function set titleColor(value:uint):void
		{
			if(_titleObject is GTextField)
				GTextField(_titleObject).color = value;
			else if(_titleObject is GLabel)
				GLabel(_titleObject).titleColor = value;
			else if(_titleObject is GButton)
				GButton(_titleObject).titleColor = value;
		}
		
		public function set editable(val:Boolean):void
		{
			if(_titleObject)
				_titleObject.asTextInput.editable = val;
		}
		
		public function get editable():Boolean
		{
			if(_titleObject is GTextInput)
				return _titleObject.asTextInput.editable;
			else
				return false;
		}
		
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			
			_titleObject = getChild("title");
			_iconObject = getChild("icon");
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			xml = xml.Label[0];
			if(xml)
			{
				this.text = xml.@title;
				this.icon = xml.@icon;
				var str:String;
				str = xml.@titleColor;
				if(str)
					this.titleColor = ToolSet.convertFromHtmlColor(str);
			}
		}
	}
}

