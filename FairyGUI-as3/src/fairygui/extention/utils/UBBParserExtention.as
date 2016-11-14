package fairygui.extention.utils
{
	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-8-22下午8:38:03 <br/>
	 **/
	import fairygui.utils.UBBParser;
	
	public final class UBBParserExtention extends UBBParser
	{
		private static var _strList:Array = [];
		public function UBBParserExtention()
		{
			super();
		}
		//***************
		//internal
		//***************
		
		//***************
		//noticeHandler
		//***************
		
		//***************
		//protected
		//***************
		
		//***************
		//private
		//***************
		
		//***************
		//eventHandler
		//***************
		
		//***************
		//public
		//***************
		public static function ToHtml(content:Object, color:Object=null, underLine:Boolean=false, eventStr:String=null, href:String=null, bold:Boolean=false, fontSize:int=-1):String
		{
			_strList.push("<font");
			color!=null && _strList.push(" color='#" + color.toString(16) + "'");
			fontSize!=-1 && _strList.push(" size='" + fontSize + "'");
			_strList.push(">");
			bold && _strList.push("<b>");
			underLine && _strList.push("<u>");
			eventStr ? _strList.push("<a href='event:" + eventStr + "'>") : (href && _strList.push("<a href='" + href + "'>"));
			_strList.push(content);
			(eventStr || href) && _strList.push("</a>");
			underLine && _strList.push("</u>");
			bold && _strList.push("</b>");
			_strList.push("</font>");
			
			var str:String = _strList.join("");
			_strList.length = 0;
			return str;
		}
		public static function ToUbb(content:Object, 
										color:Object=null, 
										underLine:Boolean=false, 
										eventStr:String=null, 
										href:String=null, 
										bold:Boolean=false,
										fontSize:int=-1):String
		{
			_strList.push("<font");
			color!=null && _strList.push(" color='#" + color.toString(16) + "'");
			fontSize!=-1 && _strList.push(" size='" + fontSize + "'");
			_strList.push(">");
			bold && _strList.push("<b>");
			underLine && _strList.push("<u>");
			eventStr ? _strList.push("<a href='event:" + eventStr + "'>") : (href && _strList.push("<a href='" + href + "'>"));
			_strList.push(content);
			(eventStr || href) && _strList.push("</a>");
			underLine && _strList.push("</u>");
			bold && _strList.push("</b>");
			_strList.push("</font>");
			
			var str:String = _strList.join("");
			_strList.length = 0;
			return str;
			/*var str:String = (color!=null ? "[color=#" + color.toString(16) + "]" : "") +
							 (underLine ? "[u]" : "") +
							 (eventStr!=null ? "[event=" + eventStr + "]" : "") +
							 (href!=null ? "[url=" + href + "]" : "") +
							 (bold ? "[b]" : "") +
							 (fontSize > 0 ? "[size=" + fontSize + "]" : "") +
							 content +
							 (fontSize > 0 ? "[/size]" : "") +
							 (bold ? "[/b]" : "") +
							 (href!=null ? "[/url]" : "") +
							 (eventStr!=null ? "[/event]" : "") +
							 (underLine ? "[/u]" : "") +
							 (color!=null ? "[/color]" : "");
			return str;*/
		}
	}
}