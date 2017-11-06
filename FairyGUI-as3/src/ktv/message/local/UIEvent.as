package ktv.message.local
{
	import flash.events.Event;
	
	
	public class UIEvent extends Event
	{
		public static const CHANGE_BG:String="CHANGE_BG";
		public static const CHANGE_SKIN:String="CHANGE_SKIN";
		public static const CHANGE_LANG:String="CHANGE_LANG";
		
		public static const LOACL_MESSAGE:String="LOACL_MESSAGE";
		public static const IMAGE_COMPLETE:String="IMAGE_COMPLETE";
		public static const IMAGE_ERROR:String="IMAGE_ERROR";
		public static const PAGE_CHANGE:String="PAGE_CHANGE";
		private var _data:*;
		public function UIEvent(type:String, data:*=null, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
			_data = data;
		}
		/**事件数据*/
		public function get data():*{
			return _data;
		}
		
		public function set data(value:*):void {
			_data = value;
		}
		
		override public function clone():Event {
			return new UIEvent(type, _data, bubbles, cancelable);
		}
	}
}