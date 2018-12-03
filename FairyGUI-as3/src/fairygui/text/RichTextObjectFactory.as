package fairygui.text
{
	import flash.display.DisplayObject;
	
	import fairygui.GLoader;
	import fairygui.LoaderFillType;
	import fairygui.display.UIDisplayObject;

	public class RichTextObjectFactory implements IRichTextObjectFactory
	{
		public var pool:Array;
		
		public function RichTextObjectFactory()
		{
			pool = [];
		}
		
		public function createObject(src:String, width:int, height:int):DisplayObject
		{
			var loader:GLoader;
			
			if (pool.length > 0)
				loader = pool.pop();
			else
			{
				loader = new GLoader();
				loader.fill = LoaderFillType.ScaleFree;
			}
			loader.url = src;
			
			loader.setSize(width, height);
			
			return loader.displayObject;
		}
		
		public function freeObject(obj:DisplayObject):void
		{
			var loader:GLoader = GLoader(UIDisplayObject(obj).owner);
			loader.url = null;
			pool.push(loader);
		}
	}
}