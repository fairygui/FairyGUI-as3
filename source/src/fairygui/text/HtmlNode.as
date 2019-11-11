package fairygui.text
{
	import flash.display.DisplayObject;
	
	public class HtmlNode
	{
		public var charStart:int;
		public var charEnd:int;
		
		public var element:HtmlElement;
		
		public var displayObject:DisplayObject;
		public var topY:Number;
		
		public function HtmlNode()
		{
		}
		
		public function reset():void
		{
			charStart = -1;
			charEnd = -1;			
			displayObject = null;
		}
	}
}