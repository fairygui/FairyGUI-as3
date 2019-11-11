package fairygui.gears
{
	import fairygui.tween.EaseType;
	import fairygui.tween.GTweener;

	public class GearTweenConfig
	{
		public var tween:Boolean;
		public var easeType:int;
		public var duration:Number;
		public var delay:Number;
		
		internal var _tweener:GTweener;
		internal var _displayLockToken:uint;
		
		public function GearTweenConfig()
		{
			tween = true;
			easeType = EaseType.QuadOut;
			duration = 0.3;
			delay = 0;
			_displayLockToken = 0;
		}
	}
}