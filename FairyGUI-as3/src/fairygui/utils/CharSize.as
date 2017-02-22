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
		private static var testTextFormat:TextFormat;
		private static var results:Object;
		private static var boldResults:Object;
		
		private static var helperBmd:BitmapData;
		
		private static var TEST_STRING:String = "fj|_我案愛爱";
		
		public static function getSize(size:int, font:String, bold:Boolean):Object {
			if(!testTextField){
				testTextField = new TextField();
				testTextField.autoSize = TextFieldAutoSize.LEFT;
				testTextField.text = TEST_STRING;
				
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

			return ret;
		}
	}
}