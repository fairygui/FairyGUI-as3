package fairygui.utils
{
	import flash.text.Font;
	import flash.text.FontStyle;
	import flash.text.TextFormat;
	
	public class FontUtils
	{
		private static var sEmbeddedFonts:Array = null;
		
		public function FontUtils()
		{
		}
		
		public static function updateEmbeddedFonts():void
		{
			sEmbeddedFonts = null; // will be updated in 'isEmbeddedFont()'
		}
		
		//from starling
		public static function isEmbeddedFont(format:TextFormat):Boolean
		{
			if (sEmbeddedFonts == null)
				sEmbeddedFonts = Font.enumerateFonts(false);
			
			for each (var font:Font in sEmbeddedFonts)
			{
				var style:String = font.fontStyle;
				var isBold:Boolean = style == FontStyle.BOLD || style == FontStyle.BOLD_ITALIC;
				var isItalic:Boolean = style == FontStyle.ITALIC || style == FontStyle.BOLD_ITALIC;
				var fBold:Boolean = format.bold==null?false:format.bold;
				var fItalic:Boolean = format.italic==null?false:format.italic;
				
				if (format.font == font.fontName && fItalic == isItalic && fBold == isBold)
					return true;
			}
			
			return false;
		}
	}
}

