package fairygui.gears
{
	import fairygui.tween.GTween;
	import fairygui.tween.GTweener;
	import fairygui.GObject;
	import fairygui.UIPackage;
	
	public class GearXY extends GearBase
	{
		public var positionsInPercent:Boolean;

		private var _storage:Object;
		private var _default:Object;
		
		public function GearXY(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			_default = {x:_owner.x, y:_owner.y, px:_owner.x/_owner.parent.width, py:_owner.y/_owner.parent.height};
			_storage = {};
		}
		
		override protected function addStatus(pageId:String, value:String):void
		{
			if(value=="-" || value.length==0)
				return;
			
			var arr:Array = value.split(",");
			var pt:Object;
			if(pageId==null)
				pt = _default;
			else
			{
				pt = {};
				_storage[pageId] = pt;
			}
			pt.x = parseInt(arr[0]);
			pt.y = parseInt(arr[1]);
			pt.px = parseFloat(arr[2]);
			pt.py = parseFloat(arr[3]);
			if(isNaN(pt.px))
			{
				pt.px = pt.x / _owner.parent.width;
				pt.py = pt.y / _owner.parent.height;
			}
		}

		override public function apply():void
		{
			var pt:Object = _storage[_controller.selectedPageId];
			if(!pt)
				pt = _default;

			var ex:Number;
			var ey:Number;

			if(positionsInPercent && _owner.parent)
			{
				ex = pt.px * _owner.parent.width;
				ey = pt.py * _owner.parent.height;
			}
			else
			{
				ex = pt.x;
				ey = pt.y;
			}

			if(_tweenConfig != null && _tweenConfig.tween && !UIPackage._constructing && !disableAllTweenEffect)
			{
				if (_tweenConfig._tweener != null)
				{
					if (_tweenConfig._tweener.endValue.x != ex || _tweenConfig._tweener.endValue.y != ey)
					{
						_tweenConfig._tweener.kill(true);
						_tweenConfig._tweener = null;
					}
					else
						return;
				}

				var ox:Number = _owner.x;
				var oy:Number = _owner.y;

				if (ox != ex || oy != ey)
				{
					if(_owner.checkGearController(0, _controller))
						_tweenConfig._displayLockToken = _owner.addDisplayLock();
					
					_tweenConfig._tweener = GTween.to2(ox, oy, ex, ey, _tweenConfig.duration)
						.setDelay(_tweenConfig.delay)
						.setEase(_tweenConfig.easeType)
						.setTarget(this)
						.onUpdate(__tweenUpdate)
						.onComplete(__tweenComplete);
				}
			}
			else
			{
				_owner._gearLocked = true;
				_owner.setXY(ex, ey);
				_owner._gearLocked = false;
			}
		}
		
		private function __tweenUpdate(tweener:GTweener):void
		{
			_owner._gearLocked = true;
			_owner.setXY(tweener.value.x, tweener.value.y);
			_owner._gearLocked = false;
		}
		
		private function __tweenComplete():void
		{
			if(_tweenConfig._displayLockToken!=0)
			{
				_owner.releaseDisplayLock(_tweenConfig._displayLockToken);
				_tweenConfig._displayLockToken = 0;
			}
			_tweenConfig._tweener = null;
		}
		
		override public function updateState():void
		{
			var pt:Object = _storage[_controller.selectedPageId];
			if(!pt) {
				pt = {};
				_storage[_controller.selectedPageId] = pt;
			}
			
			pt.x = _owner.x;
			pt.y = _owner.y;
			if(_owner.parent)
			{
				pt.px = _owner.x / _owner.parent.width;
				pt.py = _owner.y / _owner.parent.height;
			}
		}
		
		override public function updateFromRelations(dx:Number, dy:Number):void
		{
			if(_controller==null || _storage==null || positionsInPercent)
				return;
			
			for each (var pt:Object in _storage)
			{
				pt.x += dx;
				pt.y += dy;
			}
			_default.x += dx;
			_default.y += dy;
			
			updateState();
		}
	}
}
