package fairygui
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.LineScaleMode;
	import flash.display.Sprite;

	import fairygui.display.UISprite;
	import fairygui.utils.ToolSet;
	import fairygui.utils.PointList;
	import flash.display.GraphicsPathCommand;
	
	public class GGraph extends GObject
	{
		private var _graphics:Graphics;
		
		private var _type:int;
		private var _lineSize:int;
		private var _lineColor:int;
		private var _lineAlpha:Number;
		private var _fillColor:int;
		private var _fillAlpha:Number;
		private var _fillBitmapData:BitmapData;
		private var _corner:Array;
		private var _sides:int;
		private var _startAngle:Number;
		private var _polygonPoints:PointList;
		private var _distances:Array;

		private static var helperCmds:Vector.<int> = new Vector.<int>();
		private static var helperPointList:PointList = new PointList();
		
		public function GGraph()
		{
			_lineSize = 1;
			_lineAlpha = 1;
			_fillAlpha = 1;
			_fillColor = 0xFFFFFF;
			_startAngle = 0;
		}
		
		public function get graphics():Graphics
		{
			if(_graphics)
				return _graphics;
			
			delayCreateDisplayObject();
			_graphics = Sprite(displayObject).graphics;
			return _graphics;
		}
		
		public function get color():uint
		{
			return _fillColor;
		}
		
		public function set color(value:uint):void 
		{
			if(_fillColor != value)
			{
				_fillColor = value;
				updateGear(4);
				if(_type!=0)
					updateGraph();
			}
		}
		
		public function drawRect(lineSize:int, lineColor:int, lineAlpha:Number,
								 fillColor:int, fillAlpha:Number, corner:Array=null):void
		{
			_type = 1;
			_lineSize = lineSize;
			_lineColor = lineColor;
			_lineAlpha = lineAlpha;
			_fillColor = fillColor;
			_fillAlpha = fillAlpha;
			_fillBitmapData = null;
			_corner = corner;
			updateGraph();
		}
		
		public function drawRectWithBitmap(lineSize:int, lineColor:int, lineAlpha:Number, bitmapData:BitmapData):void
		{
			_type = 1;
			_lineSize = lineSize;
			_lineColor = lineColor;
			_lineAlpha = lineAlpha;
			_fillBitmapData = bitmapData;
			updateGraph();
		}

		public function drawEllipse(lineSize:int, lineColor:int, lineAlpha:Number,
									fillColor:int, fillAlpha:Number):void
		{
			_type = 2;
			_lineSize = lineSize;
			_lineColor = lineColor;
			_lineAlpha = lineAlpha;
			_fillColor = fillColor;
			_fillAlpha = fillAlpha;
			_corner = null;
			updateGraph();
		}

		public function drawRegularPolygon(lineSize:int, lineColor:int, lineAlpha:Number,
									fillColor:int, fillAlpha:Number, sides:int, startAngle:Number=0, distances:Array=null):void
		{
			_type = 3;
			_lineSize = lineSize;
			_lineColor = lineColor;
			_lineAlpha = lineAlpha;
			_fillColor = fillColor;
			_fillAlpha = fillAlpha;
			_corner = null;
			_sides = sides;
			_startAngle = startAngle;
			_distances = distances;
			updateGraph();
		}

		public function get distances():Array
		{
			return _distances;
		}

		public function set distances(value:Array):void
		{
			_distances = value;
			if(_type==3)
				updateGraph();
		}

		public function drawPolygon(lineSize:int, lineColor:int, lineAlpha:Number,
									fillColor:int, fillAlpha:Number, points:PointList):void
		{
			_type = 4;
			_lineSize = lineSize;
			_lineColor = lineColor;
			_lineAlpha = lineAlpha;
			_fillColor = fillColor;
			_fillAlpha = fillAlpha;
			_corner = null;
			_polygonPoints = points;
			updateGraph();
		}
		
		public function clearGraphics():void
		{
			if(_graphics)
			{
				_type = 0;
				_graphics.clear();
			}
		}
		
		private function updateGraph():void
		{
			this.graphics;//force create
			
			_graphics.clear();
			
			var w:int = Math.ceil(this.width);
			var h:int = Math.ceil(this.height);
			if(w==0 || h==0)
				return;
			
			if(_lineSize==0)
				_graphics.lineStyle(0,0,0,true,LineScaleMode.NORMAL);
			else
				_graphics.lineStyle(_lineSize, _lineColor, _lineAlpha, true, LineScaleMode.NORMAL);
			
			var offset:Number = 0;
			
			//特殊处理，保证当lineSize是1时，图形的大小是正确的。
			if(_lineSize>0)
			{
				if(w>0)
					w-=_lineSize;
				if(h>0)
					h-=_lineSize;
				
				offset = _lineSize*0.5;
			}
			
			if(_fillBitmapData!=null)
				_graphics.beginBitmapFill(_fillBitmapData);
			else
				_graphics.beginFill(_fillColor, _fillAlpha);
			if(_type==1)
			{	
				if(_corner)
				{
					if(_corner.length==1)
						_graphics.drawRoundRectComplex(offset,offset,w,h,int(_corner[0]),int(_corner[0]),int(_corner[0]),int(_corner[0]));
					else
						_graphics.drawRoundRectComplex(offset,offset,w,h,int(_corner[0]),int(_corner[1]),int(_corner[2]),int(_corner[3]));
				}
				else
					_graphics.drawRect(offset,offset,w,h);
			}
			else if(_type==2)
				_graphics.drawEllipse(offset,offset,w,h);
			else if(_type==3 || _type==4)
			{
				if(_type==3)
				{
					if(!_polygonPoints)
						_polygonPoints = new PointList();
	
					var radius:Number = Math.min(_width, _height)/2;
					_polygonPoints.length = _sides;
					var angle:Number = ToolSet.DEG_TO_RAD*_startAngle;
					var deltaAngle:Number = 2*Math.PI/_sides;
					var dist:Number;
					for(var i:int=0;i<_sides;i++)
					{
						if(_distances)
						{
							dist = _distances[i];
							if(isNaN(dist))
								dist = 1;
						}
						else
							dist = 1;

						var xv:Number = radius + radius * dist * Math.cos(angle);
						var yv:Number = radius + radius * dist * Math.sin(angle);
						_polygonPoints.set(i, xv, yv);

						angle += deltaAngle;
					}
				}

				helperCmds.length = 0;
				helperCmds.push(GraphicsPathCommand.MOVE_TO)
				for(i=1;i<=_polygonPoints.length;i++)
					helperCmds.push(GraphicsPathCommand.LINE_TO);

				//close the path
				helperPointList.length = 0;
				helperPointList.addRange(_polygonPoints);
				helperPointList.push3(_polygonPoints, 0);
				
				_graphics.drawPath(helperCmds, helperPointList.rawList);
			}
			_graphics.endFill();
		}
		
		public function replaceMe(target:GObject):void
		{
			if(!_parent)
				throw new Error("parent not set");
			
			target.name = this.name;
			target.alpha = this.alpha;
			target.rotation = this.rotation;
			target.visible = this.visible;
			target.touchable = this.touchable;
			target.grayed = this.grayed;
			target.setXY(this.x, this.y);
			target.setSize(this.width, this.height);
			
			var index:int = _parent.getChildIndex(this);
			_parent.addChildAt(target, index);
			target.relations.copyFrom(this.relations);
			
			_parent.removeChild(this, true);
		}
		
		public function addBeforeMe(target:GObject):void
		{
			if (_parent == null)
				throw new Error("parent not set");
			
			var index:int = _parent.getChildIndex(this);
			_parent.addChildAt(target, index);
		}
		
		public function addAfterMe(target:GObject):void
		{
			if (_parent == null)
				throw new Error("parent not set");
			
			var index:int = _parent.getChildIndex(this);
			index++;
			_parent.addChildAt(target, index);
		}
		
		public function setNativeObject(obj:DisplayObject):void
		{
			delayCreateDisplayObject();
			Sprite(displayObject).addChild(obj);
		}
		
		private function delayCreateDisplayObject():void
		{
			if(!displayObject)
			{
				setDisplayObject(new UISprite(this));
				if(_parent)
					_parent.childStateChanged(this);
				handlePositionChanged();
				displayObject.alpha = this.alpha;
				displayObject.rotation = this.normalizeRotation;
				displayObject.visible = this.visible;
				Sprite(displayObject).mouseEnabled = this.touchable;
				Sprite(displayObject).mouseChildren = this.touchable;
			}
			else
			{
				Sprite(displayObject).graphics.clear();
				Sprite(displayObject).removeChildren();
				_graphics = null;
			}
		}
		
		override protected function handleSizeChanged():void
		{
			if(_graphics)
			{
				if(_type!=0)
					updateGraph();
			}
		}

		override public function getProp(index:int):*
		{
			if(index==ObjectPropID.Color)
				return this.color;
			else
				return super.getProp(index);
		}

		override public function setProp(index:int, value:*):void
		{
			if(index==ObjectPropID.Color)
				this.color = value;
			else
				super.setProp(index, value);
		}

		override public function setup_beforeAdd(xml:XML):void
		{
			var str:String;
			var type:String = xml.@type;
			if(type && type!="empty")
			{
				setDisplayObject(new UISprite(this));
			}
			
			super.setup_beforeAdd(xml);
			
			if(displayObject!=null)
			{
				_graphics = Sprite(this.displayObject).graphics;
				
				str = xml.@lineSize;
				if(str)
					_lineSize = parseInt(str);
				
				str = xml.@lineColor;
				if(str)
				{
					var c:uint = ToolSet.convertFromHtmlColor(str,true);
					_lineColor = c & 0xFFFFFF;
					_lineAlpha = ((c>>24)&0xFF)/0xFF;
				}
				
				str = xml.@fillColor;
				if(str)
				{
					c = ToolSet.convertFromHtmlColor(str,true);
					_fillColor = c & 0xFFFFFF;
					_fillAlpha = ((c>>24)&0xFF)/0xFF;
				}
				
				str = xml.@corner;
				if(str)
					_corner = str.split(",");

				if(type=="rect")
					_type = 1;
				else if(type=="ellipse" || type=="eclipse")
					_type = 2;
				else if(type=="regular_polygon")
				{
					_type = 3;
					str = xml.@sides;
					_sides = parseInt(str);
					str = xml.@startAngle;
					if(str)
						_startAngle = parseFloat(str);

					str = xml.@distances;
					if(str)
					{
						arr = str.split(",");
						cnt = arr.length;
						_distances = [];
						for(i=0;i<cnt;i++)
						{
							if(arr[i])
								_distances[i] = 1;
							else
								_distances[i] = parseFloat(arr[i]);
						}
					}
				}
				else if(type=="polygon")
				{
					_type = 4;
					_polygonPoints = new PointList();
					str = xml.@points;
					if(str)
					{
						var arr:Array = str.split(",");
						var cnt:int = arr.length;
						for(var i:int=0;i<cnt;i+=2)
							_polygonPoints.push(arr[i], arr[i+1]);
					}
				}
				
				updateGraph();
			}
		}
	}
}