package ktv.message.socket
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	
	import ktv.morn.core.managers.LogManager;

	[Event(name="SocketEvent.SOCKET_CONNECTED", type="ktv.message.socket.SocketEvent")]
	[Event(name="SocketEvent.SOCKET_DATA", type="ktv.message.socket.SocketEvent")]
	public class SocketManager extends EventDispatcher
	{
		/**
		 *测试数据使用的 消息长度 
		 */		
		public static const messageHead:String="10000000";//8位数  1000 0000
		private var _socketIP:String="127.0.0.1";
		private var _socketPort:int=8730;
		private var timer:Timer;

		private var socket:Socket;

		private static var instance:SocketManager;

		private var isMessageHead:Boolean=false;
		/**
		 *循环读取的数据 
		 */		
		private var loopByte:ByteArray;
		private var socketMessage:SocketMessage;
		/**
		 *是否包含发送消息的长度 
		 */		
		public var isHasByteHeadLength:Boolean=true;
		
		public function SocketManager()
		{
			
		}

		public function get connected():Boolean
		{
			return socket.connected;
		}

		public static function getInstance():SocketManager
		{
			if (!instance)
			{
				instance=new SocketManager();
			}
			return instance;
		}

		public function get socketPort():int
		{
			return _socketPort;
		}

		public function set socketPort(value:int):void
		{
			_socketPort=value;
		}

		public function get socketIP():String
		{
			return _socketIP;
		}

		public function set socketIP(value:String):void
		{
			_socketIP=value;
		}

		public function init():void
		{
			trace("socketManager 初始话 init()");
			timer=new Timer(1000 * 1);
			loopByte=new ByteArray();
			socketMessage=new SocketMessage();
			
			socket=new Socket();
			socket.addEventListener(Event.CONNECT, socketConnected);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, socketData);
			socket.addEventListener(Event.CLOSE, socketClose);
			socket.addEventListener(IOErrorEvent.IO_ERROR, io_error);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, security_error);
			timer.addEventListener(TimerEvent.TIMER, timerRun);
			timer.start();//首次延迟发送
		}

		protected function socketConnected(event:Event):void
		{
			timer.stop();
			timer.reset();
			LogManager.log.info("socket连接成功!");
			sendEvent(SocketEvent.SOCKET_CONNECTED);
		}

		protected function timerRun(event:TimerEvent):void
		{
			socketConnect();
			LogManager.log.error("持续连接socket	次数:" + timer.currentCount);
		}

		protected function socketClose(event:Event):void
		{
			LogManager.log.error("socket连接失败");
			timer.start();
		}

		private function socketConnect():void
		{
			socket.connect(socketIP, socketPort);
		}

		protected function security_error(event:SecurityErrorEvent):void
		{
			LogManager.log.error("socket连接错误" + event.type + event.toString());
			timer.start();
		}

		protected function io_error(event:IOErrorEvent):void
		{
			LogManager.log.error("socket连接错误" + event.type);
			timer.start();
		}

		protected function socketData(event:ProgressEvent):void
		{
			var tempByte:ByteArray=new ByteArray();
			socket.readBytes(tempByte);
			var testMessage:String=tempByte.readUTFBytes(tempByte.length);
			if(testMessage.indexOf(messageHead.toString()) != -1)//查找发来的数据是否含有消息头
			{
				testMessage=testMessage.replace(messageHead,"");
				var tempAry:Array=testMessage.split(messageHead);
				while(tempAry.length>0)
				{
					getMessage(tempAry.shift(),messageHead);
				}
			}else
			{
				loopByte.position=loopByte.length; //从指定的位置开始写入 往末尾添加  push();
				tempByte.position=0;
				loopByte.writeBytes(tempByte);
				parseSocketDataByte();
			}
			
		}

		private function parseSocketDataByte():void
		{
			if (loopByte.length >= SocketMessage.RECEIVE_MESSAGE_HEAD_BYTE_LENGTH)
			{
				if (!isMessageHead)
				{
					isMessageHead=true;
					socketMessage.headByte.writeBytes(loopByte, 0, SocketMessage.RECEIVE_MESSAGE_HEAD_BYTE_LENGTH);
				}
				if (isMessageHead)
				{
					trace("读取消息中..." + loopByte.length + "/" + socketMessage.totalLength);
					if (loopByte.length >= socketMessage.totalLength)
					{
						socketMessage.dataByte.writeBytes(loopByte, SocketMessage.RECEIVE_MESSAGE_HEAD_BYTE_LENGTH, socketMessage.dataLength);
						//多余的数据
						var excessDataLength:int=loopByte.length - socketMessage.totalLength;
						if(excessDataLength >= 0)//调整trace 顺序
						getMessage(socketMessage.data,socketMessage.totalLength.toString());
						if (excessDataLength == 0) //截取完毕
						{
							isMessageHead=false;
							loopByte.clear();
							socketMessage.clear();
						}
						else//实际获取的数据 过长
						{
							var temp:ByteArray=new ByteArray();
							loopByte.position=socketMessage.totalLength;
							loopByte.readBytes(temp, 0, excessDataLength);
							loopByte=temp;
							isMessageHead=false;
							socketMessage.clear();
							parseSocketDataByte();
						}
					}
				}
			}
		}
		

		/**
		 *获取后台发来的消息
		 * @param data
		 */
		public function getMessage(data:String,msgHead:String=messageHead):void
		{
			LogManager.log.receive(msgHead + data);
			sendEvent(SocketEvent.SOCKET_DATA, data);
		}
		
		public function sendEvent(type:String,data:*=null):void
		{
			this.dispatchEvent(new SocketEvent(type, data));
		}

		/**
		 *发送消息给后台
		 * @param message
		 *
		 */
		public function sendMessage(message:String):void
		{
			if (socket && socket.connected && message)
			{
				var byteData:ByteArray=new ByteArray();
				byteData.writeUTFBytes(message); //4 个字节 的 消息长度
				if(isHasByteHeadLength)
				{
					var byteHead:ByteArray=new ByteArray();
					byteHead.endian=Endian.LITTLE_ENDIAN;
					byteHead.writeInt(byteData.length);
					socket.writeBytes(byteHead);
				}
				socket.writeBytes(byteData);
				if(isHasByteHeadLength)
				{
					byteHead.position=0;
				}
				byteData.position=0;
				if(isHasByteHeadLength)
				{
					LogManager.log.send("socket发送消息:"+byteHead.readUnsignedInt() + byteData.readUTFBytes(byteData.length));
				}else
				{
					LogManager.log.send("socket发送消息:"+byteData.readUTFBytes(byteData.length));
				}
				socket.flush();
			}
			else
			{
				LogManager.log.error("socket未连接不能推送消息" + message);
			}
		}

		public function dispose():void
		{
			socket.removeEventListener(Event.CONNECT, socketConnected);
			socket.removeEventListener(ProgressEvent.SOCKET_DATA,socketData);
			socket.removeEventListener(Event.CLOSE, socketClose);
			socket.removeEventListener(IOErrorEvent.IO_ERROR, io_error);
			socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, security_error);
			socket.close();
			timer.removeEventListener(TimerEvent.TIMER, timerRun);
			timer.stop();
			socketMessage.clear();
			if(loopByte) loopByte.clear();
		}
	}
}

