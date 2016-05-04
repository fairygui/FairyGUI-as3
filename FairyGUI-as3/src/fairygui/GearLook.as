package fairygui
{
	import com.greensock.TweenLite;
	
	import flash.geom.Point;	

	public class GearLook extends GearBase
	{
		private var _storage:Object;
		private var _default:GearLookValue;
		private var _tweenValue:Point;
		private var _tweener:TweenLite;
		
		public function GearLook(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			_default = new GearLookValue(_owner.alpha, _owner.rotation, _owner.grayed);
			_storage = {};
		}
		
		override protected function addStatus(pageId:String, value:String):void
		{
			var arr:Array = value.split(",");
			var gv:GearLookValue;
			if(pageId==null)
				gv = _default;
			else
			{
				gv = new GearLookValue();
				_storage[pageId] = gv;
			}
			gv.alpha = parseFloat(arr[0]);
			gv.rotation = parseInt(arr[1]);
			gv.grayed = arr[2]=="1"?true:false;
		}
		
		override public function apply():void
		{
			_owner._gearLocked = true;
			
			var gv:GearLookValue;
			var ct:Boolean = this.connected;
			if(ct)
			{
				gv = _storage[_controller.selectedPageId];
				if(!gv)
					gv = _default;
			}
			else
				gv = _default;
			
			if(_tweener!=null)
			{
				if(_tweener.vars.onUpdateParams[0])
					_owner.alpha = _tweener.vars.x;
				if(_tweener.vars.onUpdateParams[1])
					_owner.rotation = _tweener.vars.y;
				_tweener.kill();
				_tweener = null;
				_owner.internalVisible--;
			}
			
			if(_tween && !UIPackage._constructing && !disableAllTweenEffect
				&& ct && _pageSet.containsId(_controller.previousPageId))
			{
				_owner.grayed = gv.grayed;
				var a:Boolean = gv.alpha!=_owner.alpha;
				var b:Boolean = gv.rotation!=_owner.rotation;
				if(a || b)
				{
					_owner.internalVisible++;
					var vars:Object = 
						{
							ease: _easeType,
							x: gv.alpha,
							y: gv.rotation,
							overwrite:0
						};
					vars.onUpdate = __tweenUpdate;
					vars.onUpdateParams = [a,b];
					vars.onComplete = __tweenComplete;
					if(_tweenValue==null)
						_tweenValue = new Point();
					_tweenValue.x = _owner.alpha;
					_tweenValue.y = _owner.rotation;
					_tweener = TweenLite.to(_tweenValue, _tweenTime, vars);
				}
			}
			else
			{
				_owner.alpha = gv.alpha;
				_owner.rotation = gv.rotation;
				_owner.grayed = gv.grayed;
			}
				
			_owner._gearLocked = false;
		}
		
		private function __tweenUpdate(a:Boolean, b:Boolean):void
		{
			_owner._gearLocked = true;
			if(a)
				_owner.alpha = _tweenValue.x;
			if(b)
				_owner.rotation = _tweenValue.y;
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

			var gv:GearLookValue;
			if(connected)
			{
				gv = _storage[_controller.selectedPageId];
				if(!gv)
				{
					gv = new GearLookValue();
					_storage[_controller.selectedPageId] = gv;
				}
			}
			else
			{
				gv = _default;
			}
			
			gv.alpha = _owner.alpha;
			gv.rotation = _owner.rotation;
			gv.grayed = _owner.grayed;
		}
	}
}

class GearLookValue
{
	public var alpha:Number;
	public var rotation:int;
	public var grayed:Boolean;
	
	public function GearLookValue(alpha:Number=0, rotation:int=0, grayed:Boolean=false)
	{
		this.alpha = alpha;
		this.rotation = rotation;
		this.grayed = grayed;
	}
}
