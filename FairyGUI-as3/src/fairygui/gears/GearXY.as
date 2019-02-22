package fairygui.gears
{
	import flash.geom.Point;
	
	import fairygui.tween.GTween;
	import fairygui.tween.GTweener;
	import fairygui.GObject;
	import fairygui.UIPackage;
	
	public class GearXY extends GearBase
	{
		private var _storage:Object;
		private var _default:Point;
		
		public function GearXY(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			_default = new Point(_owner.x, _owner.y);
			_storage = {};
		}
		
		override protected function addStatus(pageId:String, value:String):void
		{
			if(value=="-" || value.length==0)
				return;
			
			var arr:Array = value.split(",");
			var pt:Point;
			if(pageId==null)
				pt = _default;
			else
			{
				pt = new Point();
				_storage[pageId] = pt;
			}
			pt.x = parseInt(arr[0]);
			pt.y = parseInt(arr[1]);
		}

		override public function apply():void
		{
			var pt:Point = _storage[_controller.selectedPageId];
			if(!pt)
				pt = _default;

			if(_tweenConfig != null && _tweenConfig.tween && !UIPackage._constructing && !disableAllTweenEffect)
			{
				if (_tweenConfig._tweener != null)
				{
					if (_tweenConfig._tweener.endValue.x != pt.x || _tweenConfig._tweener.endValue.y != pt.y)
					{
						_tweenConfig._tweener.kill(true);
						_tweenConfig._tweener = null;
					}
					else
						return;
				}
				
				if (_owner.x != pt.x || _owner.y != pt.y)
				{
					if(_owner.checkGearController(0, _controller))
						_tweenConfig._displayLockToken = _owner.addDisplayLock();
					
					_tweenConfig._tweener = GTween.to2(_owner.x, _owner.y, pt.x, pt.y, _tweenConfig.duration)
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
				_owner.setXY(pt.x, pt.y);
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
			var pt:Point = _storage[_controller.selectedPageId];
			if(!pt) {
				pt = new Point();
				_storage[_controller.selectedPageId] = pt;
			}
			
			pt.x = _owner.x;
			pt.y = _owner.y;
		}
		
		override public function updateFromRelations(dx:Number, dy:Number):void
		{
			if(_controller==null || _storage==null)
				return;
			
			for each (var pt:Point in _storage)
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
