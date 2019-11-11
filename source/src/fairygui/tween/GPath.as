package fairygui.tween
{
	import flash.geom.Point;
	
	import fairygui.utils.PointList;
	import fairygui.utils.ToolSet;

	public class GPath
	{
		private var _segments:Vector.<Segment>;
		private var _points:PointList;
		private var _fullLength:Number;
		
		private static var helperList:Vector.<GPathPoint> = new Vector.<GPathPoint>();
		private static var helperPoints:PointList = new PointList();
		private static var helperPoint:Point = new Point();
		
		public function GPath()
		{
			_segments = new Vector.<Segment>();
			_points = new PointList();
		}

		public function get length():Number
		{
			return _fullLength;
		}

		public function create2(pt1:GPathPoint, pt2:GPathPoint, pt3:GPathPoint=null, pt4:GPathPoint=null):void
		{
			helperList.length = 0;
			helperList.push(pt1);
			helperList.push(pt2);
			if(pt3)
				helperList.push(pt3);
			if(pt4)
				helperList.push(pt4);
			create(helperList);
		}

		public function create(points:Vector.<GPathPoint>):void
		{
			_segments.length = 0;
			_points.length = 0;
			helperPoints.length = 0;
			_fullLength = 0;
			
			var cnt:int = points.length;
			if (cnt==0)
				return;
			
			var prev:GPathPoint = points[0];
			if (prev.curveType == CurveType.CRSpline)
				helperPoints.push(prev.x, prev.y);
			
			for(var i:int=1;i<cnt;i++)
			{
				var current:GPathPoint = points[i];
				
				if (prev.curveType != CurveType.CRSpline)
				{
					var seg:Segment = new Segment();
					seg.type = prev.curveType;
					seg.ptStart = _points.length;
					if (prev.curveType == CurveType.Straight)
					{
						seg.ptCount = 2;
						_points.push(prev.x, prev.y);
						_points.push(current.x, current.y);
					}
					else if (prev.curveType == CurveType.Bezier)
					{
						seg.ptCount = 3;
						_points.push(prev.x, prev.y);
						_points.push(current.x, current.y);
						_points.push(prev.control1_x, prev.control1_y);
					}
					else if (prev.curveType == CurveType.CubicBezier)
					{
						seg.ptCount = 4;
						_points.push(prev.x, prev.y);
						_points.push(current.x, current.y);
						_points.push(prev.control1_x, prev.control1_y);
						_points.push(prev.control2_x, prev.control2_y);
					}
					seg.length = ToolSet.distance(prev.x, prev.y, current.x, current.y);
					_fullLength += seg.length;
					_segments.push(seg);
				}
				
				if (current.curveType != CurveType.CRSpline)
				{
					if (helperPoints.length > 0)
					{
						helperPoints.push(current.x, current.y);
						createSplineSegment();
					}
				}
				else
					helperPoints.push(current.x, current.y);
				
				prev = current;
			}
			
			if (helperPoints.length > 1)
				createSplineSegment();
		}
		
		private function createSplineSegment():void
		{
			var cnt:int = helperPoints.length;
			helperPoints.insert3(0, helperPoints, 0);
			helperPoints.push3(helperPoints, cnt);
			helperPoints.push3(helperPoints, cnt);
			cnt += 3;
			
			var seg:Segment = new Segment();
			seg.type = CurveType.CRSpline;
			seg.ptStart = _points.length;
			seg.ptCount = cnt;
			_points.addRange(helperPoints);
			
			seg.length = 0;
			for (var i:int = 1; i < cnt; i++)
			{
				seg.length += ToolSet.distance(helperPoints.get_x(i-1), helperPoints.get_y(i-1),
					helperPoints.get_x(i), helperPoints.get_y(i));
			}
			_fullLength += seg.length;
			_segments.push(seg);
			helperPoints.length = 0;
		}
		
		public function clear():void
		{
			_segments.length = 0;
			_points.length = 0;
		}
		
		public function getPointAt(t:Number, result:Point=null):Point
		{
			if(result==null)
				result = new Point();
			else
				result.setTo(0, 0);
			
			t = ToolSet.clamp01(t);
			var cnt:int = _segments.length;
			if (cnt == 0)
			{
				return result;
			}
			
			var seg:Segment;
			if (t == 1)
			{
				seg = _segments[cnt - 1];
				
				if (seg.type == CurveType.Straight)
				{
					result.x = ToolSet.lerp(_points.get_x(seg.ptStart), _points.get_x(seg.ptStart + 1), t);
					result.y = ToolSet.lerp(_points.get_y(seg.ptStart), _points.get_y(seg.ptStart + 1), t);
					
					return result;
				}
				else if (seg.type == CurveType.Bezier || seg.type == CurveType.CubicBezier)
					return onBezierCurve(seg.ptStart, seg.ptCount, t, result);
				else
					return onCRSplineCurve(seg.ptStart, seg.ptCount, t, result);
			}
			
			var len:Number = t * _fullLength;
			for (var i:int = 0; i < cnt; i++)
			{
				seg = _segments[i];
				
				len -= seg.length;
				if (len < 0)
				{
					t = 1 + len / seg.length;
					
					if (seg.type == CurveType.Straight)
					{
						result.x = ToolSet.lerp(_points.get_x(seg.ptStart), _points.get_x(seg.ptStart + 1), t);
						result.y = ToolSet.lerp(_points.get_y(seg.ptStart), _points.get_y(seg.ptStart + 1), t);
					}
					else if (seg.type == CurveType.Bezier || seg.type == CurveType.CubicBezier)
						result = onBezierCurve(seg.ptStart, seg.ptCount, t, result);
					else
						result = onCRSplineCurve(seg.ptStart, seg.ptCount, t, result);
					
					break;
				}
			}
			
			return result;
		}

		public function get segmentCount():int
		{
			return _segments.length;
		}
		
		public function getSegment(segmentIndex:int):Object
		{
			return _segments[segmentIndex];
		}
		
		public function getAnchorsInSegment(segmentIndex:int, points:PointList = null):PointList
		{
			if (points == null)
				points = new PointList();

			var seg:Segment = _segments[segmentIndex];
			for(var i:int=0;i<seg.ptCount;i++)
				points.push3(_points, seg.ptStart+i);

			return points;
		}
		
		public function getPointsInSegment(segmentIndex:int, t0:Number, t1:Number, points:PointList = null, ts:Vector.<Number> = null, pointDensity:Number = 0.1):PointList
		{
			if (points == null)
				points = new PointList();
			
			if (ts != null)
				ts.push(t0);
			var seg:Segment = _segments[segmentIndex];
			if (seg.type == CurveType.Straight)
			{
				points.push(ToolSet.lerp(_points.get_x(seg.ptStart), _points.get_x(seg.ptStart + 1), t0),
					ToolSet.lerp(_points.get_y(seg.ptStart), _points.get_y(seg.ptStart + 1), t0));
				points.push(ToolSet.lerp(_points.get_x(seg.ptStart), _points.get_x(seg.ptStart + 1), t1),
					ToolSet.lerp(_points.get_y(seg.ptStart), _points.get_y(seg.ptStart + 1), t1));
			}
			else
			{
				var func:Function;
				if (seg.type == CurveType.Bezier || seg.type == CurveType.CubicBezier)
					func = onBezierCurve;
				else
					func = onCRSplineCurve;

				points.push2(func(seg.ptStart, seg.ptCount, t0, helperPoint));
				var SmoothAmount:int = Math.min(seg.length * pointDensity, 50);
				for (var j:int = 0; j <= SmoothAmount; j++)
				{
					var t:Number = j / SmoothAmount;
					if (t > t0 && t < t1)
					{
						points.push2(func(seg.ptStart, seg.ptCount, t, helperPoint));
						if (ts != null)
							ts.push(t);
					}
				}
				points.push2(func(seg.ptStart, seg.ptCount, t1, helperPoint));
			}
			
			if (ts != null)
				ts.push(t1);
			
			return points;
		}
	
		public function getAllPoints(points:PointList = null, ts:Vector.<Number> = null, pointDensity:Number = 0.1):PointList
		{
			if (points == null)
				points = new PointList();
			
			var cnt:int = _segments.length;
			for (var i:int = 0; i < cnt; i++)
				getPointsInSegment(i, 0, 1, points, ts, pointDensity);
			
			return points;
		}

		public function findSegmentNear(x0:Number, y0:Number):int
		{
			var cnt:int = _segments.length;
			var min:Number = int.MAX_VALUE;
			var dist:Number;
			var result:int = -1;
			for (var i:int = 0; i < cnt; i++)
			{
				var seg:Segment = _segments[i];
				if (seg.type == CurveType.Straight)
				{
					var x1:Number = _points.get_x(seg.ptStart);
					var y1:Number = _points.get_y(seg.ptStart);
					var x2:Number = _points.get_x(seg.ptStart+1);
					var y2:Number = _points.get_y(seg.ptStart+1);

					var a:Number = y2 - y1;
					var b:Number = x1 - x2;
					var c:Number = x2*y1 - x1*y2;

					dist = ToolSet.pointLineDistance(x0, y0, x1, y1, x2, y2, true);
					if(dist<min)
					{
						min = dist;
						result = i;
					}
				}
				else
				{
					helperPoints.length = 0;
					getPointsInSegment(i, 0, 1, helperPoints);
					for (var j:int = 0; j < helperPoints.length; j++)
					{
						dist = ToolSet.distance(helperPoints.get_x(j), helperPoints.get_y(j), x0, y0);
						if(dist<min)
						{
							min = dist;
							result = i;
						}
					}
				}
			}

			return result;
		}
		
		private function onCRSplineCurve(ptStart:int, ptCount:int, t:Number, result:Point):Point
		{
			var adjustedIndex:int = Math.floor(t * (ptCount - 4)) + ptStart; //Since the equation works with 4 points, we adjust the starting point depending on t to return a point on the specific segment
			
			var p0x:Number = _points.get_x(adjustedIndex);
			var p0y:Number = _points.get_y(adjustedIndex);
			var p1x:Number = _points.get_x(adjustedIndex + 1)
			var p1y:Number = _points.get_y(adjustedIndex + 1);
			var p2x:Number = _points.get_x(adjustedIndex + 2);
			var p2y:Number = _points.get_y(adjustedIndex + 2);
			var p3x:Number = _points.get_x(adjustedIndex + 3);
			var p3y:Number = _points.get_y(adjustedIndex + 3);
			
			var adjustedT:Number  = (t == 1) ? 1 : ToolSet.repeat(t * (ptCount - 4), 1); // Then we adjust t to be that value on that new piece of segment... for t == 1f don't use repeat (that would return 0f);
			
			var t0:Number = ((-adjustedT + 2) * adjustedT - 1) * adjustedT * 0.5;
			var t1:Number  = (((3 * adjustedT - 5) * adjustedT) * adjustedT + 2) * 0.5;
			var t2:Number  = ((-3 * adjustedT + 4) * adjustedT + 1) * adjustedT * 0.5;
			var t3:Number  = ((adjustedT - 1) * adjustedT * adjustedT) * 0.5;
			
			result.x = p0x * t0 + p1x * t1 + p2x * t2 + p3x * t3;
			result.y = p0y * t0 + p1y * t1 + p2y * t2 + p3y * t3;
			
			return result;
		}
		
		private function onBezierCurve(ptStart:int, ptCount:int, t:Number, result:Point):Point
		{
			var t2:Number = 1 - t;
			var p0x:Number = _points.get_x(ptStart);
			var p0y:Number = _points.get_y(ptStart);
			var p1x:Number = _points.get_x(ptStart + 1);
			var p1y:Number = _points.get_y(ptStart + 1);
			var cp0x:Number = _points.get_x(ptStart + 2);
			var cp0y:Number = _points.get_y(ptStart + 2);
			
			if (ptCount == 4)
			{
				var cp1x:Number = _points.get_x(ptStart + 3);
				var cp1y:Number = _points.get_y(ptStart + 3);
				result.x =  t2 * t2 * t2 * p0x + 3 * t2 * t2 * t * cp0x + 3 * t2 * t * t * cp1x + t * t * t * p1x;
				result.y =  t2 * t2 * t2 * p0y + 3 * t2 * t2 * t * cp0y + 3 * t2 * t * t * cp1y + t * t * t * p1y;
			}
			else
			{
				result.x = t2 * t2 * p0x + 2 * t2 * t * cp0x + t * t * p1x;
				result.y = t2 * t2 * p0y + 2 * t2 * t * cp0y + t * t * p1y;
			}
			
			return result;
		}
	}
}

class Segment
{
	public var type:int;
	public var length:Number;
	public var ptStart:int;
	public var ptCount:int;

	public function Segment()
	{
	}
}