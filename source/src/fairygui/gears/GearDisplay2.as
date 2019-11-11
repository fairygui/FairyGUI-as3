package fairygui.gears
{
	import fairygui.GObject;

	public class GearDisplay2 extends GearBase
	{
		public var pages:Array;
		public var condition:int;

		private var _visible:int;
		
		public function GearDisplay2(owner:GObject)
		{
			super(owner);
		}
		
		override protected function init():void
		{
			pages = null;
		}

		public function evaluate(connected:Boolean):Boolean
		{
			var v:Boolean = _controller==null || _visible>0;
			if(condition==0)
				v = v && connected;
			else
				v = v || connected;
			return v;
		}

		override public function apply():void
		{
			if(pages==null || pages.length==0 
				|| pages.indexOf(_controller.selectedPageId)!=-1)
				_visible = 1;
			else
				_visible = 0;
		}
	}
}