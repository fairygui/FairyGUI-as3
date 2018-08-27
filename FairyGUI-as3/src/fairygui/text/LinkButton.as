package fairygui.text
{
	import flash.display.Sprite;

	public class LinkButton extends Sprite
	{
		public var owner:HtmlNode;
		
		public function LinkButton():void {
			buttonMode = true;
		}
		
		public function setSize(w:Number, h:Number):void {
			graphics.clear();
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, w, h);
			graphics.endFill();
		}
	}
}