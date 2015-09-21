package
{
	import flash.events.Event;
	
	public class DropEvent extends Event
	{
		public static const DROP:String = "__drop";
		
		public var source:Object;
		
		public function DropEvent(type:String, source:Object)
		{
			super(type, false, false);
			this.source = source;
		}
	}
}