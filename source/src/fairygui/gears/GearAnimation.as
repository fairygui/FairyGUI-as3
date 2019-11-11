package fairygui.gears
{
	import fairygui.GObject;
	import fairygui.ObjectPropID;

	public class GearAnimation extends GearBase
	{
		private var _storage:Object;
		private var _default:GearAnimationValue;
		
		public function GearAnimation(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			_default = new GearAnimationValue(_owner.getProp(ObjectPropID.Playing),
				_owner.getProp(ObjectPropID.Frame));
			_storage = {};
		}
		
		override protected function addStatus(pageId:String, value:String):void
		{
			if(value=="-" || value.length==0)
				return;
			
			var gv:GearAnimationValue;
			if(pageId==null)
				gv = _default;
			else
			{
				gv = new GearAnimationValue();
				_storage[pageId] = gv; 
			}
			var arr:Array = value.split(",");
			gv.frame = int(arr[0]);
			gv.playing = arr[1]=="p";
		}
		
		override public function apply():void
		{
			_owner._gearLocked = true;
			
			var gv:GearAnimationValue = _storage[_controller.selectedPageId];
			if(!gv)
				gv = _default;
			
			_owner.setProp(ObjectPropID.Playing, gv.playing);
			_owner.setProp(ObjectPropID.Frame, gv.frame);
			
			_owner._gearLocked = false;
		}
		
		override public function updateState():void
		{
			var gv:GearAnimationValue = _storage[_controller.selectedPageId];
			if(!gv)
			{
				gv = new GearAnimationValue();
				_storage[_controller.selectedPageId] = gv;
			}
			
			gv.playing = _owner.getProp(ObjectPropID.Playing);
			gv.frame = _owner.getProp(ObjectPropID.Frame);
		}
	}
}

class GearAnimationValue
{
	public var playing:Boolean;
	public var frame:int;
	
	public function GearAnimationValue(playing:Boolean=true, frame:int=0):void
	{
		this.playing = playing;
		this.frame = frame;
	}
}
