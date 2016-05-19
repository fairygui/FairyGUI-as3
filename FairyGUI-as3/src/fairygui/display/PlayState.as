package fairygui.display
{
	import fairygui.utils.GTimers;

	public class PlayState
	{
		public var reachEnding:Boolean; //是否已播放到结尾
		public var frameStarting:Boolean; //是否刚开始新的一帧
		public var reversed:Boolean; //是否已反向播放
		public var repeatedCount:int; //重复次数
		
		private var _curFrame:int; //当前帧
		private var _lastTime:Number;
		private var _curFrameDelay:int; //当前帧延迟
		private var _lastUpdateSeq:uint;
		
		public function PlayState()
		{
			_lastTime = GTimers.time;
		}
		
		public function update(mc:MovieClip):void
		{
			if (_lastUpdateSeq == GTimers.workCount)//PlayState may be shared, only update once per frame
				return;
			
			_lastUpdateSeq = GTimers.workCount;
			var tt:Number = GTimers.time;
			var elapsed:Number = tt - _lastTime;
			_lastTime = tt;
			
			reachEnding = false;
			frameStarting = false;
			_curFrameDelay += elapsed;
			var realFrame:int = reversed ? mc.frameCount - _curFrame - 1 : _curFrame;
			var interval:int = mc.interval + mc.frames[realFrame].addDelay + ((realFrame == 0 && repeatedCount > 0) ? mc.repeatDelay : 0);
			if (_curFrameDelay < interval)
				return;
			
			_curFrameDelay = 0;
			_curFrame++;
			frameStarting = true;
			
			if (_curFrame > mc.frameCount - 1)
			{
				_curFrame = 0;
				repeatedCount++;
				reachEnding = true;
				if (mc.swing)
				{
					reversed = !reversed;
					_curFrame++;
				}
			}
		}
		
		public function get currentFrame():int
		{
			return _curFrame;
		}
		
		public function set currentFrame(value:int):void
		{
			_curFrame = value; 
			_curFrameDelay = 0;
		}
		
		public function rewind():void
		{
			_curFrame = 0;
			_curFrameDelay = 0;
			reversed = false;
			reachEnding = false;
		}
		
		public function reset():void
		{
			_curFrame = 0;
			_curFrameDelay = 0;
			repeatedCount = 0;
			reachEnding = false;
			reversed = false;
		}
		
		public function copy(src:PlayState):void
		{
			_curFrame = src._curFrame;
			_curFrameDelay = src._curFrameDelay;
			repeatedCount = src.repeatedCount;
			reachEnding = src.reachEnding;
			reversed = src.reversed;
		}
	}
}