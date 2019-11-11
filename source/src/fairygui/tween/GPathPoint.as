package fairygui.tween
{
	public class GPathPoint
	{
		public var x:Number;
		public var y:Number;

		public var control1_x:Number;
		public var control1_y:Number;

		public var control2_x:Number;
		public var control2_y:Number;
		
		public var curveType:int;
		public var smooth:Boolean;

		public function GPathPoint()
		{
			x = 0;
			y = 0;
			control1_x = 0;
			control1_y = 0;
			control2_x = 0;
			control2_y = 0;
			curveType = 0;
			smooth = true;
		}

		public static function newPoint(x:Number=0, y:Number=0, curveType:int=0):GPathPoint
		{
			var pt:GPathPoint = new GPathPoint();
			pt.x = x;
			pt.y = y;
			pt.control1_x = 0;
			pt.control1_y = 0;
			pt.control2_x = 0;
			pt.control2_y = 0;
			pt.curveType = curveType;
			
			return pt;
		}
		
		public static function newBezierPoint(x:Number=0, y:Number=0, 
										control1_x:Number = 0, control1_y:Number=0):GPathPoint
		{
			var pt:GPathPoint = new GPathPoint();
			pt.x = x;
			pt.y = y;
			pt.control1_x = control1_x;
			pt.control1_y = control1_y;
			pt.control2_x = 0;
			pt.control2_y = 0;
			pt.curveType = CurveType.Bezier;
			
			return pt;
		}
		
		public static function newCubicBezierPoint(x:Number=0, y:Number=0, 
											  control1_x:Number = 0, control1_y:Number=0, 
											  control2_x:Number = 0, control2_y:Number=0):GPathPoint
		{
			var pt:GPathPoint = new GPathPoint();
			pt.x = x;
			pt.y = y;
			pt.control1_x = control1_x;
			pt.control1_y = control1_y;
			pt.control2_x = control2_x;
			pt.control2_y = control2_y;
			pt.curveType = CurveType.CubicBezier;
			
			return pt;
		}

		public function clone():GPathPoint
		{
			var ret:GPathPoint = new GPathPoint();
			ret.x = x;
			ret.y = y;
			ret.control1_x = control1_x;
			ret.control1_y = control1_y;
			ret.control2_x = control2_x;
			ret.control2_y = control2_y;
			ret.curveType = curveType;

			return ret;
		}

		public function toString():String
		{
			switch(curveType)
			{		
				case CurveType.Bezier:
					return curveType + "," + x + "," + y + "," + control1_x + "," + control1_y;

				case CurveType.CubicBezier:
					return curveType + "," + x + "," + y + "," + control1_x + "," + control1_y + "," 
					+ control2_x + "," + control2_y + "," + (smooth?1:0);

				default:
					return curveType + "," + x + "," + y;
			}
		}
	}
}