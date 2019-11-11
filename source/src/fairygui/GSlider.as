package fairygui
{
	import flash.geom.Point;
	
	import fairygui.event.GTouchEvent;
	import fairygui.event.StateChangeEvent;
	import fairygui.utils.ToolSet;
	
	[Event(name = "stateChanged", type = "fairygui.event.StateChangeEvent")]
	public class GSlider extends GComponent
	{
		private var _min:Number;
		private var _max:Number;
		private var _value:Number;
		private var _titleType:int;
		private var _reverse:Boolean;
		private var _wholeNumbers:Boolean;

		private var _titleObject:GTextField;
		private var _barObjectH:GObject;
		private var _barObjectV:GObject;
		private var _barMaxWidth:int;
		private var _barMaxHeight:int;
		private var _barMaxWidthDelta:int;
		private var _barMaxHeightDelta:int;
		private var _gripObject:GObject;
		private var _clickPos:Point;
		private var _clickPercent:Number;
		private var _barStartX:int;
		private var _barStartY:int;
		
		public var changeOnClick:Boolean = true;

		/**是否可拖动开关**/
		public var canDrag:Boolean = true;
		
		public function GSlider()
		{
			super();

			_titleType = ProgressTitleType.Percent;
			_value = 50;
			_max = 100;
			_clickPos = new Point();
		}

		final public function get titleType():int
		{
			return _titleType;
		}
		
		final public function set titleType(value:int):void
		{
			_titleType = value;
		}
		
		public function get wholeNumbers():Boolean
		{
			return _wholeNumbers;
		}

		public function set wholeNumbers(value:Boolean):void
		{
			if(_wholeNumbers != value)
			{
				_wholeNumbers = value;
				update();
			}
		}
		
		public function get min():Number
		{
			return _min;
		}
		
		public function set min(value:Number):void
		{
			if(_min != value)
			{
				_min = value;
				update();
			}
		}

		final public function get max():Number
		{
			return _max;
		}
		
		final public function set max(value:Number):void
		{
			if(_max != value)
			{
				_max = value;
				update();
			}
		}
		
		final public function get value():Number
		{
			return _value;
		}
		
		final public function set value(value:Number):void
		{
			if(_value != value)
			{
				_value = value;
				update();
			}
		}
		
		public function update():void
		{
			updateWithPercent((_value-_min)/(_max-_min), false);
		}
		
		private function updateWithPercent(percent:Number, manual:Boolean):void
		{
			percent = ToolSet.clamp01(percent);
			if(manual)
			{
				var newValue:Number = ToolSet.clamp(_min+(_max-_min)*percent, _min, _max);
				if(_wholeNumbers)
				{
					newValue = Math.round(newValue);
					percent = ToolSet.clamp01((newValue-_min)/(_max-_min));
				}

				if(newValue!=_value)
				{
					_value = newValue;
					dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
				}
			}
			
			if(_titleObject)
			{
				switch(_titleType)
				{
					case ProgressTitleType.Percent:
						_titleObject.text = Math.round(percent*100)+"%";
						break;
					
					case ProgressTitleType.ValueAndMax:
						_titleObject.text = _value + "/" + _max;
						break;
					
					case ProgressTitleType.Value:
						_titleObject.text = ""+_value;
						break;
					
					case ProgressTitleType.Max:
						_titleObject.text = ""+_max;
						break;
				}
			}
			
			var fullWidth:int = this.width-this._barMaxWidthDelta;
			var fullHeight:int = this.height-this._barMaxHeightDelta;
			if(!_reverse)
			{
				if(_barObjectH)
					_barObjectH.width = Math.round(fullWidth*percent);
				if(_barObjectV)
					_barObjectV.height = Math.round(fullHeight*percent);
			}
			else
			{
				if(_barObjectH)
				{
					_barObjectH.width = Math.round(fullWidth*percent);
					_barObjectH.x = _barStartX + (fullWidth-_barObjectH.width); 
				}
				if(_barObjectV)
				{
					_barObjectV.height = Math.round(fullHeight*percent);
					_barObjectV.y =  _barStartY + (fullHeight-_barObjectV.height);
				}
			}
		}
		
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			
			xml = xml.Slider[0];
			
			var str:String;
			str = xml.@titleType;
			if(str)
				_titleType = ProgressTitleType.parse(str);
			
			_reverse = xml.@reverse=="true";
			_wholeNumbers = xml.@wholeNumbers=="true";
			changeOnClick = xml.@changeOnClick!="false";
			
			_titleObject = getChild("title") as GTextField;
			_barObjectH = getChild("bar");
			_barObjectV = getChild("bar_v");
			_gripObject = getChild("grip");
			
			if(_barObjectH)
			{
				_barMaxWidth = _barObjectH.width;
				_barMaxWidthDelta = this.width - _barMaxWidth;
				_barStartX = _barObjectH.x;
			}
			if(_barObjectV)
			{
				_barMaxHeight = _barObjectV.height;
				_barMaxHeightDelta = this.height - _barMaxHeight;
				_barStartY = _barObjectV.y;
			}
			if(_gripObject)
			{
				_gripObject.addEventListener(GTouchEvent.BEGIN, __gripMouseDown);
				_gripObject.addEventListener(GTouchEvent.DRAG, __gripMouseMove);
			}
			
			addEventListener(GTouchEvent.BEGIN, __barMouseDown);
		}
		
		override protected function handleSizeChanged():void
		{
			super.handleSizeChanged();
			
			if(_barObjectH)
				_barMaxWidth = this.width - _barMaxWidthDelta;
			if(_barObjectV)
				_barMaxHeight = this.height - _barMaxHeightDelta;
			if(!this._underConstruct)
				update();
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			xml = xml.Slider[0];
			if(xml)
			{
				_value = parseInt(xml.@value);
				if(isNaN(_value))
					_value = 0;
				_max = parseInt(xml.@max);
				if(isNaN(_max))
					_max = 0;
				_min = parseInt(xml.@min);
				if(isNaN(_min))
					_min = 0;
			}
			
			update();
		}
		
		private function __gripMouseDown(evt:GTouchEvent):void
		{
			this.canDrag=true;

			evt.stopPropagation();
			
			_clickPos = this.globalToLocal(evt.stageX, evt.stageY);
			_clickPercent = ToolSet.clamp01((_value-_min)/(_max-_min));
		}
		
		private function __gripMouseMove(evt:GTouchEvent):void
		{
			if(!this.canDrag){
				return;
			}
			
			var pt:Point = this.globalToLocal(evt.stageX, evt.stageY);
			var deltaX:int = pt.x-_clickPos.x;
			var deltaY:int = pt.y-_clickPos.y;
			if(_reverse)
			{
				deltaX = -deltaX;
				deltaY = -deltaY;
			}
			var percent:Number;
			if(_barObjectH)
				percent = _clickPercent + deltaX/_barMaxWidth;
			else
				percent = _clickPercent + deltaY/_barMaxHeight;
			updateWithPercent(percent, true);
		}
		
		private function __barMouseDown(evt:GTouchEvent):void
		{
			if(!changeOnClick)
				return;
			
			var pt:Point = _gripObject.globalToLocal(evt.stageX, evt.stageY);
			var percent:Number = ToolSet.clamp01((_value-_min)/(_max-_min));
			var delta:Number;
			if(_barObjectH)
				delta = (pt.x-_gripObject.width/2)/_barMaxWidth;
			if(_barObjectV)
				delta = (pt.y-_gripObject.height/2)/_barMaxHeight;
			if(_reverse)
				percent -= delta;
			else
				percent += delta;
			updateWithPercent(percent, true);
		}
	}
}

