package fairygui.extention
{
	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-8-13下午12:02:14 <br/>
	 **/
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import fairygui.GObject;
	import fairygui.GScrollBar;
	import fairygui.display.UISprite;
	
	public final class ScrollBarExtention extends GScrollBar
	{
		private var _grip:GObject;
		private var _owner:GObject;
		public function ScrollBarExtention()
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
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			_grip = getChild("grip");
			displayObject.addEventListener(Event.ADDED_TO_STAGE, OnAdded);
		}
		//***************
		//private
		//***************
		private function OwnerSizeChange(owner:GObject):void
		{
			var scrollRect:Rectangle = owner.asCom.displayObject.scrollRect;
			if(scrollRect==null) scrollRect = new Rectangle(0, 0, owner.width, owner.height);
			else scrollRect.setTo(0, 0, owner.width, owner.height);
			owner.asCom.displayObject.scrollRect = scrollRect;
		}
		//***************
		//eventHandler
		//***************
		private function OnAdded(e:Event):void
		{
			e.currentTarget.removeEventListener(Event.ADDED_TO_STAGE, OnAdded);
			_owner = (displayObject.parent as UISprite).owner;
			if(_owner!=null)
			{
				_owner.addSizeChangeCallback(OwnerSizeChange);
				OwnerSizeChange(_owner);
			}
		}
		//***************
		//public
		//***************
		override public function set displayPerc(val:Number):void
		{
			super.displayPerc = val;
			_grip!=null && (_grip.visible = val > 0 && val < 1);
		}
		override public function dispose():void
		{
			if(_owner!=null) _owner.removeSizeChangeCallback(OwnerSizeChange);
			_owner = null;
			_grip = null;
			super.dispose();
		}
	}
}