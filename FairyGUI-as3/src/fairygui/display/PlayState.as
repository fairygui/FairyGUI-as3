package fairygui.display
{
	import fairygui.utils.GTimers;

	public class PlayState
	{
		public var reachEnding:Boolean; //是否已播放到结尾
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
			_curFrameDelay += elapsed;
			var interval:int = mc.interval + mc.frames[_curFrame].addDelay + ((_curFrame == 0 && repeatedCount > 0) ? mc.repeatDelay : 0);
			if (_curFrameDelay < interval)
				return;
			
			_curFrameDelay = 0;			
			if (mc.swing)
			{
				if(reversed)
				{
					_curFrame--;
					if(_curFrame<0)
					{
						_curFrame = Math.min(1, mc.frameCount-1);
						repeatedCount++;
						reversed = !reversed;
					}
				}
				else
				{
					_curFrame++;
					if (_curFrame > mc.frameCount - 1)
					{
						_curFrame = Math.max(0, mc.frameCount-2);
						repeatedCount++;
						reachEnding = true;
						reversed = !reversed;
					}
				}				
			}
			else
			{
				_curFrame++;
				if (_curFrame > mc.frameCount - 1)
				{
					_curFrame = 0;
					repeatedCount++;
					reachEnding = true;
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