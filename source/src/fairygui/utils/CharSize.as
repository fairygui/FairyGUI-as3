package fairygui.utils
{
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	public class CharSize
	{
		private static var testTextField:TextField;
		private static var testTextField2:TextField;
		private static var testTextFormat:TextFormat;
		private static var results:Object;
		private static var boldResults:Object;
		private static var holderResults:Object;
		
		private static var helperBmd:BitmapData;
		
		public static var TEST_STRING:String = "fj|_我案爱";
		
		public static function getSize(size:int, font:String, bold:Boolean):Object {
			if(!testTextField){
				testTextField = new TextField();
				testTextField.autoSize = TextFieldAutoSize.LEFT;
				testTextField.text = TEST_STRING;
				
				if(!testTextFormat)
					testTextFormat = new TextFormat();
				results = {};
				boldResults = {};
			}
			var col:Object = bold?boldResults[font]:results[font];
			if(!col)
			{
				col = {};
				if(bold)
					boldResults[font] = col;
				else
					results[font] = col;
			}
			var ret:Object = col[size];
			if(ret)
				return ret;
			
			ret = {};
			col[size] = ret;
			
			testTextFormat.font = font;
			testTextFormat.size = size;
			testTextFormat.bold = bold;
			testTextField.setTextFormat(testTextFormat);
			testTextField.embedFonts = FontUtils.isEmbeddedFont(testTextFormat);
			
			ret.height = testTextField.textHeight;
			if(ret.height==0)
				ret.height = size;
			
			if(helperBmd==null || helperBmd.width<testTextField.width || helperBmd.height<testTextField.height)
				helperBmd = new BitmapData(Math.max(128, testTextField.width), Math.max(128, testTextField.height), true, 0);
			else
				helperBmd.fillRect(helperBmd.rect,0);
			
			helperBmd.draw(testTextField);
			var bounds:Rectangle = helperBmd.getColorBoundsRect(0xFF000000, 0, false);
			ret.yIndent = bounds.top-2-int((ret.height - Math.max(bounds.height, size))/2);
			if(ret.yIndent<0)
				ret.yIndent = 0;
			
			return ret;
		}
		
		public static function getHolderWidth(font:String, size:int):int
		{
			if(!testTextField2){
				testTextField2 = new TextField();
				testTextField2.autoSize = TextFieldAutoSize.LEFT;
				testTextField2.text = "　";
				
				if(!testTextFormat)
					testTextFormat = new TextFormat();
				holderResults = {};
			}
			var col:Object = holderResults[font];
			if(!col)
			{
				col = {};
				holderResults[font] = col;
			}
			var ret:Object = col[size];
			if(ret==null)
			{
				testTextFormat.font = font;
				testTextFormat.size = size;
				testTextFormat.bold = false;
				testTextField2.setTextFormat(testTextFormat);
				testTextField2.embedFonts = FontUtils.isEmbeddedFont(testTextFormat);
				
				ret = testTextField2.textWidth;
				col[size] = ret;
			}
			
			return int(ret);
		}
		
		public static function getFontSizeByHeight(height:Number, font:String):int
		{
			var low:int = 0;
			var high:int = height;
			var cur:int = height/2;
			
			while(high-low>1)
			{
				var textHeight:Number = getSize(cur, font, false).height;
				if(Math.abs(height-textHeight)<1)
					return cur;
				
				if(textHeight>height)
					high = cur;
				else
					low = cur;
				cur = low+(high-low)/2;
			}
			return cur;
		}
	}
}

