package fairygui
{
	
	public class GearDisplay extends GearBase
	{
		public function GearDisplay(owner:GObject)
		{
			super(owner);
		}
		
		override protected function get connected():Boolean
		{
			if(_controller && !_pageSet.empty)
				return _pageSet.containsId(_controller.selectedPageId);
			else
				return true;
		}
		
		override public function apply():void
		{
			if (connected)
				_owner.internalVisible++;
			else
				_owner.internalVisible = 0;
		}
	}
}