package ktv.message.local
{
	import flash.events.EventDispatcher;

	[Event(name="UIEvent.CHANGE_BG", type="ktv.message.local.UIEvent")]
	[Event(name="UIEvent.CHANGE_SKIN", type="ktv.message.local.UIEvent")]
	[Event(name="UIEvent.CHANGE_LANG", type="ktv.message.local.UIEvent")]
	[Event(name="UIEvent.LOACL_MESSAGE", type="ktv.message.local.UIEvent")]
	[Event(name="UIEvent.IMAGE_COMPLETE", type="ktv.message.local.UIEvent")]
	[Event(name="UIEvent.IMAGE_ERROR", type="ktv.message.local.UIEvent")]
	[Event(name="UIEvent.CHANGE_PAGE", type="ktv.message.local.UIEvent")]
	public class UIEventDispatcher extends EventDispatcher
	{
		private static var instance:UIEventDispatcher;
		
		public static function getInstance():UIEventDispatcher
		{
			if(instance==null)
			{
				instance=new UIEventDispatcher();
			}
			return instance;
		}
		
		/**
		 * 发送事件  消息
		 * @param type  发送的事件 类型
		 * @param data  发送的事件  所 携带的数据
		 * 
		 */		
		public static function sendEvent(type:String,data:*=null):void
		{
			if(getInstance().hasEventListener(type))
			{
				getInstance().dispatchEvent(new UIEvent(type, data));
			}
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeekReference:Boolean=false):void
		{
			super.addEventListener(type, listener, useCapture, priority, true);
		}
		
	}
}