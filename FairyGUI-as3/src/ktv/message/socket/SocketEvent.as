package ktv.message.socket
{
	import flash.events.Event;

	public class SocketEvent extends Event
	{
		public static const SOCKET_CONNECTED:String="SOCKET_CONNECTED";
		public static const SOCKET_DATA:String="SOCKET_DATA";
		public var data:*=null;
		public function SocketEvent(type:String,data:*=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
			this.data = data;
		}

		override public function clone():Event
		{
			return super.clone();
		}

		override public function toString():String
		{
			return super.toString();
		}


	}
}

