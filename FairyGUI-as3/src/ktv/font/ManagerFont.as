package ktv.font
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.text.Font;
	import flash.utils.getQualifiedClassName;
	
	import ktv.morn.core.managers.LogManager;
	
	public class ManagerFont extends EventDispatcher
	{
		/**
		 *字体加载中
		 */		
		public static const FONT_PROGRESS:String="font_progress";
		/**
		 *字体加载完毕 
		 */		
		public static const FONT_COMPLETE:String="font_complete";
		/**
		 *字体加载错误 
		 */
		public static const FONT_ERROR:String="font_error";
		/**
		 *是否嵌入字体 
		 */		
		public static var embedFont:Boolean=true;
		/**
		 *嵌入字体的类名   文本的优先选择字体顺序和数组中的字体顺序有关
		 *  比如：[font1,font2,font3]  文本在选择字体顺序优先选择 font1->font2->font3
		 *  如果都没有找到匹配的字体 就 使用 默认的字体  微软雅黑
		 */		 
		private static var fontURLAry:Vector.<FontItem>=new Vector.<FontItem>();
		public static const FontName_font_weiruanyahei:String="Microsoft YaHei";
		/**默认字体名称，微软雅黑*/
		public static var DefaultFontName:String=ManagerFont.FontName_font_weiruanyahei;
		/**
		 *字体类  Font 
		 */
		private static var ArrEmbedFonts:Array=[];
		private var crtLoadIndex:int=0;
		public var loadTotal:int=0;
		
		public  var progressValue:Number=0;
		
		public function ManagerFont()
		{
			
		}
		
		/**
		 * var ary:Array=[["font_weiruanyahei.swf","MyFont"],["font_weiruanyahei1.swf","MyFont1"]];
		 *<br>fontManager=new FontManager(ary);
		 *<br>fontManager.addEventListener(FontManager.FONT_COMPLETE,font_complete);
		 */
		public function load(fontItemVector:Vector.<FontItem>):void
		{
			fontURLAry=fontItemVector;
			loadTotal=fontURLAry.length;
			loadFont(fontURLAry);
		}
		
		private function loadFont(fontURLAry:Vector.<FontItem>):void
		{
			if(crtLoadIndex>=fontURLAry.length)
			{
				registerFontHandler();
				crtLoadIndex=0;
				dispatchEvent(new Event(FONT_COMPLETE));
			}else
			{
				var fontItem:FontItem=fontURLAry[crtLoadIndex];
				var loader:Loader=new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeHandler);
				loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS,fontProgress);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,iOError);
				loader.load(new URLRequest(fontItem.fontURL));
			}
		}
		
		protected function fontProgress(event:ProgressEvent):void
		{
			progressValue=( crtLoadIndex+(event.bytesLoaded / event.bytesTotal) ) / loadTotal;
			dispatchEvent(new Event(FONT_PROGRESS));
		}
		
		private function completeHandler(e:Event):void
		{
			LoaderInfo(e.currentTarget).removeEventListener(ProgressEvent.PROGRESS,fontProgress);
			LoaderInfo(e.currentTarget).removeEventListener(Event.COMPLETE, completeHandler);
			LoaderInfo(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR,iOError);
			var fontItem:FontItem=fontURLAry[crtLoadIndex];
			for (var i:int = 0; i < fontItem.className.length; i++) 
			{
				var fontClass:Class=LoaderInfo(e.currentTarget).applicationDomain.getDefinition(fontItem.className[i]) as Class;
				if(fontClass)
				{
					
				}else
				{
					throw("加载的字体库swf 文件里获取不到"+fontItem.className +"链接类!!");
				}
				fontItem.fontClass.push(fontClass);
			}
			crtLoadIndex++;
			loadFont(fontURLAry);
		}
		private function iOError(e:IOErrorEvent):void
		{
			LoaderInfo(e.currentTarget).removeEventListener(Event.COMPLETE, completeHandler);
			LoaderInfo(e.currentTarget).removeEventListener(IOErrorEvent.IO_ERROR,iOError);
			dispatchEvent(new Event(FONT_ERROR));
			trace("字体加载路径错误:["+fontURLAry[crtLoadIndex]+"]");
			crtLoadIndex++;
			loadFont(fontURLAry);
		}
		
		/**
		 * 注册要使用的内嵌字体
		 */		
		private static function registerFontHandler():void
		{
			//当前需要嵌入的字体
			regFontHandler();
		}
		
		private static function regFontHandler():void
		{
			//  注册字体
			for (var i:int = 0; i < fontURLAry.length; i++)
			{
				if(fontURLAry[i].fontClass)
				{
					try
					{
						for (var k:int = 0; k < fontURLAry[i].fontClass.length; k++) 
						{
							Font.registerFont(fontURLAry[i].fontClass[k]);
						}
					}
					catch(error:Error) 
					{
						LogManager.log.error("注册字体失败,检查路径不能是父级路径");
					}
				}
			}
			ArrEmbedFonts=Font.enumerateFonts(false);
			var tempFontAry:Array=[];//生成一个临时的数组存放字体顺序
			//  获取字体的引用  排序数组 排序的方式和Font_ClassNameAry 存放的顺序一致
			for ( i= 0; i < fontURLAry.length; i++) 
			{
				for (var j:int = 0; j < ArrEmbedFonts.length; j++)
				{
					for (k = 0; k < fontURLAry[i].className.length; k++) 
					{
						if(flash.utils.getQualifiedClassName(ArrEmbedFonts[j])==fontURLAry[i].className[k])
						{
							tempFontAry.push(ArrEmbedFonts[j]);
						}
					}
					
				}
			}
			ArrEmbedFonts=tempFontAry;
			for ( i= 0; i < ArrEmbedFonts.length; i++) 
			{
				trace("字体Font顺序["+i+"]:["+Font(ArrEmbedFonts[i]).fontName+"]");
			}
			
		}
		/**
		 *通过字体名称顺序 返回 字体列表 顺序 
		 * @param fontNameAry
		 * @return 
		 */		
		private static function getFontAry(fontNameAry:Array):Array
		{
			var tempFontNameAry:Array=fontNameAry.concat();
			var ary:Array=[];
			for (var i:int = 0; i < tempFontNameAry.length; i++) 
			{
				for (var j:int = 0; j < ArrEmbedFonts.length; j++) 
				{
					var tempFont:Font=Font(ArrEmbedFonts[j]);
					if(tempFont.fontName == tempFontNameAry[i])
					{
						ary.push(tempFont);
						tempFontNameAry.splice(i,1);
					}
				}
			}
			return ary;
		}
		
		/**
		 * 设置改变字体  检查顺序 和传入的 字体数组顺序一致   找不到就用 系统字体
		 * @param str	需要检查 字符 
		 * @param fontNameAry	该文本需要设置的字体数组 
		 * @return		返回 适合的字体名称
		 * 
		 */
		public static function setFontHandler(str:String,fontNameAry:Array):String
		{
			var fontName:String=DefaultFontName;
			var fontAry:Array=getFontAry(fontNameAry);
			if(fontAry.length)
			{
				for (var i:int = 0; i < fontAry.length; i++)
				{
					var tempFont:Font=fontAry[i];
					//  按照字体数组中的列表 进行选择   优先使用默认字体 
					if(tempFont.hasGlyphs(trimSpace(str)))// 去掉空白字符 (含有换行符  会导致为false )
					{
						ManagerFont.embedFont=true;
						fontName=tempFont.fontName;
						break;
					}else
					{
						if(i==fontAry.length-1)
						{
							ManagerFont.embedFont=false;
							fontName=DefaultFontName;
						}
						
					}
				}
			}else
			{
				ManagerFont.embedFont=false;
				fontName=DefaultFontName;
			}
			return fontName;
		}
		
		private static function trimSpace(str:String):String 
		{
			var pattern:RegExp = /\r|\n|\r\n/g;
			var pattern1:RegExp = /\t|\n\t/g;
			return str.replace(pattern, "").replace(pattern1," ");
		}
	}
}