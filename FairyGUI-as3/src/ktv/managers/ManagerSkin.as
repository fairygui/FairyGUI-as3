package ktv.managers
{
	import ktv.message.local.UIEvent;
	import ktv.message.local.UIEventDispatcher;

	public class ManagerSkin
	{
		 /**
		  *当前皮肤index 
		  */		
		 public static var crtSkinIndex:int=0;
		 /**
		  * 当前背景index 
		  */
		 public static var crtBgIndex:int=0;
		 /**
		  *皮肤总个数 
		  */
		 public static var totalSkinCount:int=1;
		 /**
		  *背景总个数 
		  */
		 public static var totalBgCount:int=1;
		 
		 /**
		  *资源的 路劲 前缀 
		  */
		 public static var assetsHead:String="";
		 
		 public static function changeSkin(index:int):void
		 {
			 trace("更换皮肤"+ManagerSkin.crtSkinIndex);
			 crtSkinIndex=index;
			 UIEventDispatcher.sendEvent(UIEvent.CHANGE_SKIN);
		 }
		 
		 public static function changeBg(index:int):void
		 {
			 crtBgIndex=index;
			 UIEventDispatcher.sendEvent(UIEvent.CHANGE_BG);
		 }
		 
		 /**
		  *获取指定 index 的皮肤路径 
		  * @param url
		  * @param index
		  * @return 
		  * 
		  */
		 public static function getSkin(url:String,index:int=-1):String
		 {
			 var tempIndex:int=crtSkinIndex;
			 if(index!=-1)
			 {
				 tempIndex=index;
			 }
			 var ary:Array=url.split("/");
			 var skinIndex:int=-1;
			 for (var i:int = 0; i < ary.length; i++) 
			 {
				 if(String(ary[i]).indexOf("skin") !=-1 )
				 {
					 skinIndex=i; 
					 break;
				 }
			 }
			 if(skinIndex != -1)
			 {
				 ary[skinIndex]="skin"+tempIndex;
				 return ary.join("/");
			 }
			 return url;
		 }
		 
		 public static function getBg(url:String):String
		 {
			 return url;
		 }
		 
		 public static function getColor(url:String):String
		 {
			 return url;
		 }
	}
}