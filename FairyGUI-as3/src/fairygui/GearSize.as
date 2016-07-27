package fairygui
{
	import com.greensock.TweenLite;	

	public class GearSize extends GearBase
	{
		public var tweener:TweenLite;
		
		private var _storage:Object;
		private var _default:GearSizeValue;
		private var _tweenValue:GearSizeValue;
		
		public function GearSize(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			_default = new GearSizeValue(_owner.width, _owner.height, _owner.scaleX, _owner.scaleY);
			_storage = {};
		}
		
		override protected function addStatus(pageId:String, value:String):void
		{
			var arr:Array = value.split(",");
			var gv:GearSizeValue;
			if(pageId==null)
				gv = _default;
			else
			{
				gv = new GearSizeValue();
				_storage[pageId] = gv;
			}
			gv.width = parseInt(arr[0]);
			gv.height = parseInt(arr[1]);
			if(arr.length>2)
			{
				gv.scaleX = parseFloat(arr[2]);
				gv.scaleY = parseFloat(arr[3]);
			}
		}
		
		override public function apply():void
		{
			var gv:GearSizeValue = _storage[_controller.selectedPageId];
			if(!gv)
				gv = _default;

			if(_tween && !UIPackage._constructing && !disableAllTweenEffect)
			{
				var a:Boolean;
				var b:Boolean;
				if(tweener!=null)
				{
					a = tweener.vars.onUpdateParams[0];
					b = tweener.vars.onUpdateParams[1];
					if(a && (tweener.vars.width!=gv.width || tweener.vars.height!=gv.height)
						|| b && (tweener.vars.scaleX!=gv.scaleX || tweener.vars.scaleY!=gv.scaleY))
					{
						_owner._gearLocked = true;
						if(a)
							_owner.setSize(tweener.vars.width, tweener.vars.height, _owner.gearXY.controller==_controller);
						if(b)
							_owner.setScale(tweener.vars.scaleX, tweener.vars.scaleY);
						_owner._gearLocked = false;
						tweener.kill();
						tweener = null;
						_owner.internalVisible--;
					}
					else
						return;
				}
				
				a = gv.width != _owner.width || gv.height != _owner.height;
				b = gv.scaleX != _owner.scaleX || gv.scaleY != _owner.scaleY;
				if(a || b)
				{
					_owner.internalVisible++;
					var vars:Object = 
						{
							width: gv.width,
							height: gv.height,
							scaleX: gv.scaleX,
							scaleY: gv.scaleY,
							ease: _easeType,
							delay: _delay,
							overwrite:0
						};
					vars.onUpdate = __tweenUpdate;
					vars.onUpdateParams = [a,b];
					vars.onComplete = __tweenComplete;
					if(_tweenValue==null)
						_tweenValue = new GearSizeValue(0,0,0,0);
					_tweenValue.width = _owner.width;
					_tweenValue.height = _owner.height;
					_tweenValue.scaleX = _owner.scaleX;
					_tweenValue.scaleY = _owner.scaleY;
					tweener = TweenLite.to(_tweenValue, _tweenTime, vars);
				}
			}
			else
			{
				_owner._gearLocked = true;
				_owner.setSize(gv.width, gv.height, _owner.gearXY.controller==_controller);
				_owner.setScale(gv.scaleX, gv.scaleY);
				_owner._gearLocked = false;
			}
		}
		
		private function __tweenUpdate(a:Boolean, b:Boolean):void
		{
			_owner._gearLocked = true;
			if(a)
				_owner.setSize(_tweenValue.width, _tweenValue.height, _owner.gearXY.controller==_controller);
			if(b)
				_owner.setScale(_tweenValue.scaleX, _tweenValue.scaleY);
			_owner._gearLocked = false;							
		}
		
		private function __tweenComplete():void
		{
			_owner.internalVisible--;
			tweener = null;
		}
		
		override public function updateState():void
		{
			if(_owner._gearLocked)
				return;

			var gv:GearSizeValue = _storage[_controller.selectedPageId];
			if(!gv)
			{
				gv = new GearSizeValue();
				_storage[_controller.selectedPageId] = gv;
			}

			gv.width = _owner.width;
			gv.height = _owner.height;
			gv.scaleX = _owner.scaleX;
			gv.scaleY = _owner.scaleY;
		}
		
		public function updateFromRelations(dx:Number, dy:Number):void
		{
			for each (var gv:GearSizeValue in _storage)
			{
				gv.width += dx;
				gv.height += dy;
			}
			GearSizeValue(_default).width += dx;
			GearSizeValue(_default).height += dy;
			
			updateState();
		}
	}
}


class GearSizeValue
{
	public var width:Number;
	public var height:Number;
	public var scaleX:Number;
	public var scaleY:Number;
	
	public function GearSizeValue(width:Number=0, height:Number=0, scaleX:Number=0, scaleY:Number=0)
	{
		this.width = width;
		this.height = height;
		this.scaleX = scaleX;
		this.scaleY = scaleY;
	}
}