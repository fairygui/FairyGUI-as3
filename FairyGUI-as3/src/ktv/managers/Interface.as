package ktv.managers
{
	import flash.external.ExternalInterface;
	
	import ktv.message.local.UIEvent;
	import ktv.message.local.UIEventDispatcher;
	import ktv.message.socket.SocketManager;
	import ktv.morn.core.managers.LogManager;
	

	public class Interface
	{
		public static var isSocket:Boolean=false;
		public static function sendPfAndPid(pf:String,pid:String=""):void
		{
			if(!pf||pf=="") return;
			if(isSocket)
			{
				var obj:Object={pf:pf,pid:pid};
				sendObj(obj);
			}else
			{
				LogManager.log.send("pf:"+pf+" pid:"+pid);
				if(ExternalInterface.available)
				{
					ExternalInterface.call(pf,pid);
				}
			}
		}

		public static function sendObj(obj:Object):void
		{
			if(obj)
			{
				if(isSocket)
				{
					SocketManager.getInstance().sendMessage(JSON.stringify(obj));
				}
				else//本地发送  本地接受
				{
					var str:String=JSON.stringify(obj);
					LogManager.log.send(str);
					UIEventDispatcher.sendEvent(UIEvent.LOACL_MESSAGE,str);
				}
			}
		}
		
		public static function recevieData(data:String):void
		{
			SocketManager.getInstance().getMessage(data);
		}
	}
}

