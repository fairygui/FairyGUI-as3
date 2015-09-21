package fairygui
{
	public class PageOptionSet
	{
		private var _controller:Controller;
		private var _items:Array;
		
		public function PageOptionSet()
		{
			_items = [];
		}
		
		public function set controller(val:Controller):void
		{
			_controller = val;
		}
		
		public function add(pageIndex:int):void
		{
			var id:String = _controller.getPageId(pageIndex);
			var i:int = _items.indexOf(id);
			if(i==-1)
				_items.push(id);
		}
		
		public function remove(pageIndex:int):void
		{
			var id:String = _controller.getPageId(pageIndex);
			var i:int = _items.indexOf(id);
			if(i!=-1)
				_items.splice(i,1);
		}
		
		public function addByName(pageName:String):void
		{
			var id:String = _controller.getPageIdByName(pageName);
			var i:int = _items.indexOf(id);
			if(i!=-1)
				_items.push(id);
		}
		
		public function removeByName(pageName:String):void
		{
			var id:String = _controller.getPageIdByName(pageName);
			var i:int = _items.indexOf(id);
			if(i!=-1)
				_items.splice(i,1);
		}
		
		public function clear():void
		{
			_items.length = 0;
		}
		
		public function get empty():Boolean
		{
			return _items.length==0;
		}
		
		public function addById(id:String):void
		{
			_items.push(id);
		}
		
		public function containsId(id:String):Boolean
		{
			return _items.indexOf(id)!=-1;
		}
	}
}