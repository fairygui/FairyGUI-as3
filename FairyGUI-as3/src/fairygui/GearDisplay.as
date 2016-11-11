package fairygui
{

	public class GearDisplay extends GearBase
	{
		public var pages:Array;
		
		public function GearDisplay(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			pages = null;
		}
		
		override public function apply():void
		{
			if(!_controller || pages==null || pages.length==0 
				|| pages.indexOf(_controller.selectedPageId)!=-1)
				_owner.internalVisible++;
			else
				_owner.internalVisible = 0;
		}
	}
}