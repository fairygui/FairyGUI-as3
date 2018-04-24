package ktv.managers
{
	import ktv.message.local.UIEvent;
	import ktv.message.local.UIEventDispatcher;
	
	/** 
	 * 作用： 多语言切换   
	 */
	public class ManagerLang
	{
		//那些语言
		/**       中文                   */
		public static const CN:String = "cn";
		/**       英文                    */
		public static const EN:String = "en";
		/**       繁体                   */
		public static const TR:String = "tr";
		/**       韩语                 */
		public static const KR:String = "kr";
		/**       日语                  */
		public static const JP:String = "jp";
		
		/**当前的语言  默认是 中文  */
		public static var crtLang:String = ManagerLang.CN;
		/**
		 *当前支持的语种
		 */		
		public static var supportLangAry:Array=[CN];
		
		/**           更新语言数据    默认更改为 中文            */
		public static function updateLuanguage(crtLang:String=ManagerLang.CN):void
		{
			ManagerLang.crtLang = crtLang;
			trace("改变多语言:"+crtLang);
			UIEventDispatcher.sendEvent(UIEvent.CHANGE_LANG);
		}
		
		/**多语言的最大语种数*/
		public static function get maxLang():int
		{
			return supportLangAry.length;
		}
		
	}
}