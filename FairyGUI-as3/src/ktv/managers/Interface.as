package ktv.managers
{
	import flash.external.ExternalInterface;
	
	import ktv.message.local.UIEvent;
	import ktv.message.local.UIEventDispatcher;
	import ktv.message.socket.SocketManager;
	import ktv.morn.core.managers.LogManager;
	

	public class Interface
	{
		/**
		 *发送数据后的回调 可以在这里侦听 发送模拟数据 
		 */		
		public static var SendCallback:Function;
		public static var isSocket:Boolean=false;
		public static function sendPfAndPid(pf:String,pid:String=""):void
		{
			if(!pf||pf=="") return;
			if(isSocket)
			{
				var obj:Object={pf:pf,pid:pid};
				sendStr(JSON.stringify(obj));
			}else
			{
				LogManager.log.send("pf:"+pf+" pid:"+pid);
				if(ExternalInterface.available)
				{
					ExternalInterface.call(pf,pid);
				}
			}
		}
		public static var messageHeader:String="";
		private static function sendStr(str:String):void
		{
			if(str)
			{
				if(isSocket)
				{
					SocketManager.getInstance().sendMessage(messageHeader+str);
				}
				else//本地发送  本地接受
				{
					LogManager.log.send(str);
					UIEventDispatcher.sendEvent(UIEvent.LOACL_MESSAGE,str);
				}
			}
		}
		
		public static function sendObj(obj:Object):void
		{
			if(obj)
			{
				if(obj is String)
				{
					sendStr(String(obj));
				}else
				{
					sendStr(JSON.stringify(obj));
				}
				if(SendCallback)
				{
					SendCallback(obj);
				}
			}
		}
		
		public static function recevieData(data:String):void
		{
			SocketManager.getInstance().getMessage(data);
		}
	}
}

