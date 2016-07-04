package fairygui
{
	public class GearDisplay extends GearBase
	{
		public var pages:Vector.<String>;
		
		public function GearDisplay(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			if(pages==null)
				pages = new Vector.<String>();
			else
				pages.length = 0;
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