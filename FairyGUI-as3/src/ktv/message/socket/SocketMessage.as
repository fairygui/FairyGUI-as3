package ktv.message.socket
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class SocketMessage
	{
		public var headByte:ByteArray=new ByteArray();
		public var dataByte:ByteArray=new ByteArray();

		/**
		 *定义消息的长度  4
		 */
		public static const RECEIVE_MESSAGE_HEAD_LENGTH:int=4;
		public function SocketMessage()
		{

		}

		public function get headLength():int
		{
			return SocketMessage.RECEIVE_MESSAGE_HEAD_LENGTH;
		}

		public function get dataLength():int
		{
			if(headByte.length>=SocketMessage.RECEIVE_MESSAGE_HEAD_LENGTH)
			{
				headByte.position=0;
				headByte.endian=Endian.LITTLE_ENDIAN; //  C# 的字节数组转换 int 值的那个方法 是这种字节顺序
				return headByte.readInt();
			}
			return 0;
		}
		/**
		 *返回消息头的长度+消息的长度 
		 * @return 
		 * 
		 */
		public function get totalLength():int
		{
			return headByte.length+dataLength;
		}

		public function get data():String
		{
			var str:String="空数据";
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

