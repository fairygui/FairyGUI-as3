package fairygui
{
	import flash.geom.Point;
	
	import fairygui.tween.GTween;
	import fairygui.tween.GTweener;
	
	public class GearXY extends GearBase
	{
		private var _storage:Object;
		private var _default:Point;
		private var _tweener:GTweener;
		
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

			if(_tween && !UIPackage._constructing && !disableAllTweenEffect)
			{
				if (_tweener != null)
				{
					if (_tweener.endValue.x != pt.x || _tweener.endValue.y != pt.y)
					{
						_tweener.kill(true);
						_tweener = null;
					}
					else
						return;
				}
				
				if (_owner.x != pt.x || _owner.y != pt.y)
				{
					if(_owner.checkGearController(0, _controller))
						_displayLockToken = _owner.addDisplayLock();
					
					_tweener = GTween.to2(_owner.x, _owner.y, pt.x, pt.y, _tweenTime)
						.setDelay(_delay)
						.setEase(_easeType)
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
			if(_displayLockToken!=0)
			{
				_owner.releaseDisplayLock(_displayLockToken);
				_displayLockToken = 0;
			}
			_tweener = null;
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
