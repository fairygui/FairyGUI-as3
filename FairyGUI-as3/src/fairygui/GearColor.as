package fairygui
{
	import fairygui.utils.ToolSet;

	public class GearColor extends GearBase
	{
		private var _storage:Object;
		private var _default:uint;
		
		public function GearColor(owner:GObject)
		{
			super(owner);			
		}
		
		override protected function init():void
		{
			_default = IColorGear(_owner).color;
			_storage = {};
		}
		
		override protected function addStatus(pageId:String, value:String):void
		{
			var col:uint = ToolSet.convertFromHtmlColor(value);
			if(pageId==null)
				_default = col;
			else
				_storage[pageId] = col; 
		}
		
		override public function apply():void
		{
			_owner._gearLocked = true;
			
			if(connected)
			{
				var data:* = _storage[_controller.selectedPageId];
				if(data!=undefined)
					IColorGear(_owner).color = uint(data);
				else
					IColorGear(_owner).color = uint(_default);
			}
			else
				IColorGear(_owner).color = _default;
			
			_owner._gearLocked = false;
		}
		
		override public function updateState():void
		{
			if(_owner._gearLocked)
				return;

			if(connected)
				_storage[_controller.selectedPageId] = IColorGear(_owner).color;
			else
				_default = IColorGear(_owner).color;
		}
	}
}