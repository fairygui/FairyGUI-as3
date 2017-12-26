package ktv.message.socket
{
	import flash.utils.ByteArray;

	public class SocketMessage
	{
		public var headByte:ByteArray=new ByteArray();
		public var dataByte:ByteArray=new ByteArray();

		/**
		 *定义消息头的字节长度 8
		 */
		public static const RECEIVE_MESSAGE_HEAD_BYTE_LENGTH:int=8;
		public function SocketMessage()
		{

		}

		public function get headLength():int
		{
			return SocketMessage.RECEIVE_MESSAGE_HEAD_BYTE_LENGTH;
		}
		/**
		 *消息的长度 = 数据长度-消息头的长度
		 * @return 
		 */
		public function get dataLength():int
		{
			if(headByte.length>=SocketMessage.RECEIVE_MESSAGE_HEAD_BYTE_LENGTH)
			{
				headByte.position=0;
				var str:String=headByte.readUTFBytes(headByte.length);
				return parseInt(str)-headLength;
			}
			trace("消息[头]长度没有可读的数据!");
			return 0;
		}
		/**
		 *返回消息的长度 
		 * @return 
		 * 
		 */
		public function get totalLength():int
		{
			return headLength+dataLength;
		}

		public function get data():String
		{
			var str:String="消息长度没有可读的数据";
			dataByte.position=0;
			str=dataByte.readUTFBytes(dataByte.length);
			return str;
		}

		public function clear():void
		{
			headByte.clear();
			dataByte.clear();
		}
	}
}

