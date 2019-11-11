package fairygui.gears
{
	import fairygui.GObject;
	import fairygui.ObjectPropID;

	public class GearFontSize extends GearBase
	{
		private var _storage:Object;
		private var _default:int;
		
		public function GearFontSize(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			_default = _owner.getProp(ObjectPropID.FontSize);
			_storage = {};
		}
		
		override protected function addStatus(pageId:String, value:String):void
		{
			if(pageId==null)
				_default = parseInt(value);
			else
				_storage[pageId] = value;
		}
		
		override public function apply():void
		{
			_owner._gearLocked = true;

			var data:* = _storage[_controller.selectedPageId];
			if(data!=undefined)
				_owner.setProp(ObjectPropID.FontSize, int(data));
			else
				_owner.setProp(ObjectPropID.FontSize, _default);
			
			_owner._gearLocked = false;
		}
		
		override public function updateState():void
		{
			_storage[_controller.selectedPageId] = _owner.text;
		}
	}
}