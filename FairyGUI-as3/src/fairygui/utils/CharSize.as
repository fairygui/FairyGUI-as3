package fairygui.utils
{
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;

	public class CharSize
	{
		private static var testTextField:TextField;
		private static var testTextFormat:TextFormat;
		private static var results:Object;
		private static var boldResults:Object;
		
		public static function getWidth(size:int, font:String=null, bold:Boolean=false):int {
			return calculateSize(size, font, bold).width;
		}
		
		public static function getHeight(size:int, font:String=null, bold:Boolean=false):int {
			return calculateSize(size, font, bold).height;
		}
		
		private static function calculateSize(size:int, font:String, bold:Boolean):Object {
			if(!testTextField){
				testTextField = new TextField();
				testTextField.autoSize = TextFieldAutoSize.LEFT;
				testTextField.text = "　";
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
			ret.width = testTextField.textWidth;
			ret.height = testTextField.textHeight;
			return ret;
		}
	}
}