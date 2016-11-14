package fairygui.extention
{
	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-9-24上午10:31:13 <br/>
	 **/
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextFieldType;
	
	import fairygui.GComponentExtention;
	import fairygui.GMovieClip;
	import fairygui.GObject;
	import fairygui.GSwfObject;
	import fairygui.GTextField;
	import fairygui.ProgressTitleType;
	import fairygui.display.UITextField;
	import fairygui.event.GTouchEvent;
	import fairygui.event.StateChangeEvent;
	
	import once.GameApp;
	[Event(name = "stateChanged", type = "fairygui.event.StateChangeEvent")]
	public final class GSliderValueExtention extends GComponentExtention
	{
		private var _max:int;
		private var _value:int;
		private var _titleType:int;
		
		private var _titleObject:GTextField;
		private var _aniObject:GObject;
		private var _barObjectH:GObject;
		private var _barObjectV:GObject;
		private var _barMaxWidth:int;
		private var _barMaxHeight:int;
		private var _barMaxWidthDelta:int;
		private var _barMaxHeightDelta:int;
		private var _gripObject:GObject;
		private var _clickPos:Point;
		private var _clickPercent:Number;
		
		/**扩展属性**/
		private var _min:int;
		private var _minValue:int;
		private var _maxValue:int;
		private var _btnAdd:GObject;
		private var _btnReduce:GObject;
		private var _added:Boolean = false;
		private var _reduced:Boolean = false;
		private var _len:int;
		public function GSliderValueExtention()
		{
			super();
			_titleType = ProgressTitleType.Percent;
			_value = 50;
			_max = 100;
			_min = 0;
			_minValue = 0;
			_maxValue = int.MAX_VALUE;
			_len = _max - _min;
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
		
		public function update():void
		{
			var percent:Number = Math.min((_value - _min)/_len,1);
			updateWidthPercent(percent);
		}
		
		private function updateWidthPercent(percent:Number):void
		{
			isNaN(percent) && (percent = 0);
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
			
			if(_barObjectH)
				_barObjectH.width = (this.width-_barMaxWidthDelta)*percent;
			if(_barObjectV)
				_barObjectV.height = (this.height-_barMaxHeightDelta)*percent;
			
			if(_aniObject is GMovieClip)
				GMovieClip(_aniObject).frame = Math.round(percent*100);
			else if(_aniObject is GSwfObject)
				GSwfObject(_aniObject).frame = Math.round(percent*100);
		}
		
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			
			_titleType = ProgressTitleType.Value;
			
			_titleObject = getChild("title") as GTextField;
			_barObjectH = getChild("bar");
			_barObjectV = getChild("bar_v");
			_aniObject = getChild("ani");
			_gripObject = getChild("grip");
			/**扩展**/
			_btnAdd = getChild("btnAdd");
			_btnReduce = getChild("btnReduce");
			/**扩展end**/
			
			if(_barObjectH)
			{
				_barMaxWidth = _barObjectH.width;
				_barMaxWidthDelta = this.width - _barMaxWidth;
			}
			if(_barObjectV)
			{
				_barMaxHeight = _barObjectV.height;
				_barMaxHeightDelta = this.height - _barMaxHeight;
			}
			if(_gripObject)
			{
				_gripObject.addEventListener(GTouchEvent.BEGIN, __gripMouseDown);
				_gripObject.addEventListener(GTouchEvent.DRAG, __gripMouseMove);
				_gripObject.addEventListener(GTouchEvent.END, __gripMouseUp);
			}
		}
		
		override protected function handleSizeChanged():void
		{
			super.handleSizeChanged();
			
			if(_barObjectH)
				_barMaxWidth = this.width - _barMaxWidthDelta;
			if(_barObjectV)
				_barMaxHeight = this.height - _barMaxHeightDelta;
			if(!this.underConstruct)
				GameApp.render.callLater(update);
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			xml = xml.Slider[0];
			if(xml)
			{
				_value = parseInt(xml.@value);
				_max = parseInt(xml.@max);
				_len = _max - _min;
			}
			
			update();
		}
		
		private function __gripMouseDown(evt:GTouchEvent):void
		{
			_clickPos = this.globalToLocal(evt.stageX, evt.stageY);
			_clickPercent = (_value - _min)/_len;
		}
		
		private function __gripMouseMove(evt:GTouchEvent):void
		{
			var pt:Point = this.globalToLocal(evt.stageX, evt.stageY);
			var deltaX:int = pt.x-_clickPos.x;
			var deltaY:int = pt.y-_clickPos.y;
			
			var percent:Number;
			if(_barObjectH)
				percent = _clickPercent + deltaX/_barMaxWidth;
			else
				percent = _clickPercent + deltaY/_barMaxHeight;
			if(percent>1)
				percent = 1;
			else if(percent<0)
				percent = 0;
			var newValue:int = Math.round(_len * percent);
			GameApp.render.callLater(ChangeValue, [newValue + _min]);
		}
		
		private function __gripMouseUp(evt:GTouchEvent):void
		{
			var percent:Number = (_value - _min)/_len;
			updateWidthPercent(percent);
		}
		//***************
		//internal
		//***************
		
		//***************
		//noticeHandler
		//***************
		
		//***************
		//protected
		//***************
		override protected function addEvents():void
		{
			//如果是输入文本
			if((_titleObject.asTextField.displayObject as UITextField).type==TextFieldType.INPUT)
			{
				_titleObject.addEventListener(Event.CHANGE, OnTitleObjectChange);
				_titleType = ProgressTitleType.Value;
			}
			if(_btnAdd)
			{
				_btnAdd.addEventListener(GTouchEvent.BEGIN, OnBtnAddBegin);
				_btnAdd.addEventListener(GTouchEvent.END, OnBtnAddEnd);
			}
			if(_btnReduce)
			{
				_btnReduce.addEventListener(GTouchEvent.BEGIN, OnBtnReduceBegin);
				_btnReduce.addEventListener(GTouchEvent.END, OnBtnReduceEnd);
			}
		}
		override protected function delEvents():void
		{
			_titleObject.removeEventListener(Event.CHANGE, OnTitleObjectChange);
			if(_btnAdd)
			{
				_btnAdd.removeEventListener(GTouchEvent.BEGIN, OnBtnAddBegin);
				_btnAdd.removeEventListener(GTouchEvent.END, OnBtnAddEnd);
			}
			if(_btnReduce)
			{
				_btnReduce.removeEventListener(GTouchEvent.BEGIN, OnBtnReduceBegin);
				_btnReduce.removeEventListener(GTouchEvent.END, OnBtnReduceEnd);
			}
		}
		//***************
		//private
		//***************
		private function AddValue():void
		{
			_added = true;
			if(_value < _maxValue)
			{
				_value++;
				dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
				update();
			}
		}
		private function ReduceValue():void
		{
			_reduced = true;
			if(_value > _minValue)
			{
				_value--;
				dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
				update();
			}
		}
		private function ChangeValue(newValue:int):void
		{
			if(newValue > _maxValue) newValue = _maxValue;
			else if(newValue < _minValue) newValue = _minValue;
			if(newValue!=_value)
			{
				_value = newValue;
				dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
				update();
			}
			else if(_titleObject!=null) _titleObject.text = _value.toString();
		}
		//***************
		//eventHandler
		//***************
		private function OnTitleObjectChange(e:Event):void
		{
			if(_titleObject.text!="")
			{ GameApp.render.callLater(ChangeValue, [int(_titleObject.text)]); }
		}
		private function OnBtnAddBegin(e:GTouchEvent):void
		{
			_added = false;
			GameApp.timer.doLoop(100, AddValue);
		}
		private function OnBtnAddEnd(e:GTouchEvent):void
		{
			GameApp.timer.clearTimer(AddValue);
			!_added && AddValue();
		}
		private function OnBtnReduceBegin(e:GTouchEvent):void
		{
			_reduced = false;
			GameApp.timer.doLoop(100, ReduceValue);
		}
		private function OnBtnReduceEnd(e:GTouchEvent):void
		{
			GameApp.timer.clearTimer(ReduceValue);
			!_reduced && ReduceValue();
		}
		//***************
		//public
		//***************
		final public function set min(value:int):void
		{
			if(_min != value)
			{
				_min = value;
				_len = _max - _min;
				if(_minValue < _min) minValue = _min;
				GameApp.render.callLater(update);
			}
		}
		final public function get min():int
		{
			return _min;
		}
		final public function set minValue(valueMin:int):void
		{
			if(_minValue != valueMin && valueMin >= _min)
			{
				_minValue = valueMin;
				if(_minValue > _maxValue) _minValue = _maxValue;
				if(_value < _minValue)
				{
					_value = _minValue;
					GameApp.render.callLater(update);
				}
			}
		}
		final public function get max():int
		{
			return _max;
		}
		
		final public function set max(value:int):void
		{
			if(_max != value)
			{
				_max = value;
				_len = _max - _min;
				if(_maxValue > _max) maxValue = _max;
				GameApp.render.callLater(update);
			}
		}
		final public function set maxValue(valueMax:int):void
		{
			if(_maxValue != valueMax && valueMax <= _max)
			{
				_maxValue = valueMax;
				if(_maxValue < _minValue) _maxValue = _minValue;
				if(_value > _maxValue)
				{
					_value = _maxValue;
					GameApp.render.callLater(update);
				}
			}
		}
		
		final public function get value():int
		{
			return _value;
		}
		
		final public function set value(newValue:int):void
		{
			if(newValue!=_value)
			{
				if(newValue > _maxValue) newValue = _maxValue;
				else if(newValue < _minValue) newValue = _minValue;
				_value = newValue;
				GameApp.render.callLater(update);
			}
		}
		
		final public function updateValue(value:int):void
		{
			ChangeValue(value);
		}
	}
}