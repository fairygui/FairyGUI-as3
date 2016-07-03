package fairygui
{
	import com.greensock.TweenLite;
	
	import flash.geom.Point;	
	
	public class GearXY extends GearBase
	{
		private var _storage:Object;
		private var _default:Point;
		private var _tweenValue:Point;
		private var _tweener:TweenLite;
		
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
			_owner._gearLocked = true;
			
			var pt:Point = _storage[_controller.selectedPageId];
			if(!pt)
				pt = _default;

			if(_tweener!=null)
			{
				_owner.setXY(_tweener.vars.x, _tweener.vars.y);
				_tweener.kill();
				_tweener = null;
				_owner.internalVisible--;
			}
			
			if(_tween && !UIPackage._constructing && !disableAllTweenEffect)
			{
				if (_owner.x != pt.x || _owner.y != pt.y)
				{
					_owner.internalVisible++;
					var vars:Object = 
						{
							x: pt.x,
							y: pt.y,
							ease: _easeType,
							delay: _delay,
							overwrite:0
						};
					vars.onUpdate = __tweenUpdate;
					vars.onComplete = __tweenComplete;
					if(_tweenValue==null)
						_tweenValue = new Point();
					_tweenValue.x = _owner.x;
					_tweenValue.y = _owner.y;
					_tweener = TweenLite.to(_tweenValue, _tweenTime, vars);
				}
			}
			else
				_owner.setXY(pt.x, pt.y);
			
			_owner._gearLocked = false;
		}
		
		private function __tweenUpdate():void
		{
			_owner._gearLocked = true;
			_owner.setXY(_tweenValue.x, _tweenValue.y);
			_owner._gearLocked = false;
		}
		
		private function __tweenComplete():void
		{
			_owner.internalVisible--;
			_tweener = null;
		}
		
		override public function updateState():void
		{
			if(_owner._gearLocked)
				return;

			var pt:Point = _storage[_controller.selectedPageId];
			if(!pt) {
				pt = new Point();
				_storage[_controller.selectedPageId] = pt;
			}
			
			pt.x = _owner.x;
			pt.y = _owner.y;
		}
		
		public function updateFromRelations(dx:Number, dy:Number):void
		{
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
