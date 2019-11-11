package fairygui.utils
{
	import flash.geom.Point;

	public class PointList
	{
		private var _list:Vector.<Number>;
		
		public function PointList()
		{
			_list = new Vector.<Number>();
		}
		
		public function get rawList():Vector.<Number>
		{
			return _list;
		}

		public function set rawList(value:Vector.<Number>):void
		{
			_list = value;
		}
		
		public function push(x:Number, y:Number):void
		{
			_list.push(x);
			_list.push(y);
		}
		
		public function push2(pt:Point):void
		{
			_list.push(pt.x);
			_list.push(pt.y);
		}
		
		public function push3(anotherList:PointList, anotherIndex:int):void
		{
			_list.push(anotherList._list[anotherIndex*2]);
			_list.push(anotherList._list[anotherIndex*2+1]);
		}
		
		public function addRange(anotherList:PointList):void
		{
			var cnt:int = anotherList._list.length;
			for(var i:int=0;i<cnt;i++)
				_list.push(anotherList._list[i]);
		}
		
		public function insert(index:int, x:Number, y:Number):void
		{
			_list.splice(index*2, 0, x, y);
		}
		
		public function insert2(index:int, pt:Point):void
		{
			_list.splice(index*2, 0, pt.x, pt.y);
		}
		
		public function insert3(index:int, anotherList:PointList, anotherIndex:int):void
		{
			_list.splice(index*2, 0, anotherList._list[anotherIndex*2], anotherList._list[anotherIndex*2+1]);
		}
		
		public function remove(index:int):void
		{
			_list.splice(index*2, 2);
		}
		
		public function get_x(index:int):Number
		{
			return _list[index*2];
		}
		
		public function get_y(index:int):Number
		{
			return _list[index*2+1];
		}
		
		public function set(index:int, x:Number, y:Number):void
		{
			_list[index*2] = x;
			_list[index*2+1] = y;
		}
		
		public function setBy(index:int, dx:Number, dy:Number):void
		{
			_list[index*2] += dx;
			_list[index*2+1] += dy;
		}
		
		public function get length():int
		{
			return _list.length/2;
		}
		
		public function set length(value:int):void
		{
			_list.length = value*2;
		}
		
		public function join(sep:String):String
		{
			return _list.join(sep);
		}

		public function clone():PointList
		{
			var ret:PointList = new PointList();
			ret.rawList = this.rawList.concat();
			return ret;
		}
	}
}