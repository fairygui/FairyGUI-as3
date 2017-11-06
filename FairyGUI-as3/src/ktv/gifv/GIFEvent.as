package ktv.gifv
{
	import flash.events.Event;

	public class GIFEvent extends Event
	{
		public static const OK:String="_gif_event_ok";
		public static const FAIL:String="_gif_event_fail";

		public function GIFEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}