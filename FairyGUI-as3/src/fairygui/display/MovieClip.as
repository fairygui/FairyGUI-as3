package fairygui.display
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import fairygui.utils.GTimers;
	
	public class MovieClip extends Sprite
	{
		/**
		 * Fixed time between frames, in miniseconds.
		 */
		public var interval:int;
		public var swing:Boolean;
		public var repeatDelay:int;
		public var timeScale:Number;
		
		private var _bitmap:Bitmap;
		private var _frameCount:int;
		private var _frames:Vector.<Frame>;
		private var _boundsRect:Rectangle;
		private var _smoothing:Boolean;
		
		private var _frame:int;
		private var _playing:Boolean;
		private var _ready:Boolean;
		private var _start:int;
		private var _end:int;
		private var _times:int;
		private var _endAt:int;
		private var _status:int; //0-none, 1-next loop, 2-ending, 3-ended

		private var _frameElapsed:Number; //当前帧延迟
		private var _reversed:Boolean;
		private var _repeatedCount:int;
		private var _callback:Function;
		
		public function MovieClip()
		{
			_bitmap = new Bitmap();
			addChild(_bitmap);
			
			_playing = true;
			_frameCount = 0;
			_frame = 0;
			_smoothing = true;
			_reversed = false;
			_frameElapsed = 0;
			_repeatedCount = 0;
			timeScale = 1;
			
			setPlaySettings();
			
			this.addEventListener(Event.ADDED_TO_STAGE, __addedToStage);
			this.addEventListener(Event.REMOVED_FROM_STAGE, __removedFromStage);
		}
		
		public function get frames():Vector.<Frame>
		{
			return _frames;
		}
		
		public function set frames(value:Vector.<Frame>):void
		{
			_frames = value;
			if(_frames!=null)
				_frameCount = _frames.length;
			else
				_frameCount = 0;
			
			if(_end==-1 || _end>_frameCount - 1)
				_end = _frameCount - 1;
			if(_endAt==-1 || _endAt>_frameCount - 1)
				_endAt = _frameCount - 1;
			
			if(_frame<0 || _frame>_frameCount - 1)
				_frame = _frameCount - 1;			
			
			_ready = checkReady();
			drawFrame();

			_frameElapsed = 0;
			_repeatedCount = 0;
			_reversed = false;
			
			checkTimer();
		}
		
		public function get frameCount():int
		{
			return _frameCount;
		}
		
		public function get boundsRect():Rectangle
		{
			return _boundsRect;
		}
		
		public function set boundsRect(value:Rectangle):void
		{
			_boundsRect = value;
		}
		
		public function get frame():int
		{
			return _frame;
		}
		
		public function set frame(value:int):void
		{
			if (_frame != value)
			{
				if(_frames!=null && value>=_frameCount)
					value = _frameCount-1;
				
				_frame = value;
				_frameElapsed = 0;
				drawFrame();
			}
		}
		
		public function get playing():Boolean
		{
			return _playing;
		}
		
		public function set playing(value:Boolean):void
		{
			if(_playing!=value)
			{
				_playing = value;
				checkTimer();
			}
		}
		
		public function get smoothing():Boolean
		{
			return _smoothing;
		}
		
		public function set smoothing(value:Boolean):void
		{
			_smoothing = value;
			_bitmap.smoothing = _smoothing;
		}
		
		public function rewind():void
		{
			_frame = 0;
			_frameElapsed = 0;
			_reversed = false;
			_repeatedCount = 0;
			
			drawFrame();
		}

		public function syncStatus(anotherMc:MovieClip):void
		{
			_frame = anotherMc._frame;
			_frameElapsed = anotherMc._frameElapsed;
			_reversed = anotherMc._reversed;
			_repeatedCount = anotherMc._repeatedCount;
			
			drawFrame();
		}
		
		public function advance(timeInMiniseconds:Number):void
		{
			var beginFrame:int = _frame;
			var beginReversed:Boolean = _reversed;
			var backupTime:int = timeInMiniseconds;
			while (true)
			{
				var tt:int = interval + _frames[_frame].addDelay;
				if (_frame == 0 && _repeatedCount > 0)
					tt += repeatDelay;
				if (timeInMiniseconds < tt)
				{
					_frameElapsed = 0;
					break;
				}
				
				timeInMiniseconds -= tt;
				
				if (swing)
				{
					if (_reversed)
					{
						_frame--;
						if (_frame <= 0)
						{
							_frame = 0;
							_repeatedCount++;
							_reversed = !_reversed;
						}
					}
					else
					{
						_frame++;
						if (_frame > _frameCount - 1)
						{
							_frame = Math.max(0, _frameCount - 2);
							_repeatedCount++;
							_reversed = !_reversed;
						}
					}
				}
				else
				{
					_frame++;
					if (_frame > _frameCount - 1)
					{
						_frame = 0;
						_repeatedCount++;
					}
				}
				
				if (_frame == beginFrame && _reversed == beginReversed) //走了一轮了
				{
					var roundTime:int = backupTime - timeInMiniseconds; //这就是一轮需要的时间
					timeInMiniseconds -= Math.floor(timeInMiniseconds / roundTime) * roundTime; //跳过
				}
			}
			
			drawFrame();
		}
		
		//从start帧开始，播放到end帧（-1表示结尾），重复times次（0表示无限循环），循环结束后，停止在endAt帧（-1表示参数end）
		public function setPlaySettings(start:int = 0, end:int = -1, times:int = 0, endAt:int = -1, endCallback:Function = null):void
		{
			_start = start;
			_end = end;
			if(_end==-1 || _end>_frameCount - 1)
				_end = _frameCount - 1;
			_times = times;
			_endAt = endAt;
			if (_endAt == -1)
				_endAt = _end;
			_status = 0;
			_callback = endCallback;
			this.frame = start;
		}
		
		private function checkReady():Boolean
		{
			for(var i:int=0;i<_frameCount;i++)
			{
				var frame:Frame = _frames[i];
				if(frame.rect.width!=0 && frame.image==null)
					return false;
			}
			
			return true;
		}
		
		private function update():void
		{
			if(!_ready)
			{
				if(checkReady())
				{
					_ready = true;
					if(!_playing)
					{
						GTimers.inst.remove(update);
						drawFrame();
					}
				}
			}
			
			if (!_playing || _frameCount == 0 || _status == 3)
				return;
			
			var dt:int = GTimers.deltaTime;
			if(timeScale!=1)
				dt *= timeScale;
			
			_frameElapsed += dt;
			var tt:int = interval + _frames[_frame].addDelay;
			if (_frame == 0 && _repeatedCount > 0)
				tt += repeatDelay;
			if (_frameElapsed < tt)
				return;
			
			_frameElapsed -= tt;
			if (_frameElapsed > interval)
				_frameElapsed = interval;
			
			if (swing)
			{
				if (_reversed)
				{
					_frame--;
					if (_frame <= 0)
					{
						_frame = 0;
						_repeatedCount++;
						_reversed = !_reversed;
					}
				}
				else
				{
					_frame++;
					if (_frame > _frameCount - 1)
					{
						_frame = Math.max(0, _frameCount - 2);
						_repeatedCount++;
						_reversed = !_reversed;
					}
				}
			}
			else
			{
				_frame++;
				if (_frame > _frameCount - 1)
				{
					_frame = 0;
					_repeatedCount++;
				}
			}
			
			if (_status == 1) //new loop
			{
				_frame = _start;
				_frameElapsed = 0;
				_status = 0;
			}
			else if (_status == 2) //ending
			{
				_frame = _endAt;
				_frameElapsed = 0;
				_status = 3; //ended
				
				//play end
				if(_callback!=null)
				{
					var f:Function = _callback;
					_callback = null;
					if(f.length == 1)
						f(this);
					else
						f();
				}
			}
			else
			{
				if (_frame == _end)
				{
					if (_times > 0)
					{
						_times--;
						if (_times == 0)
							_status = 2;  //ending
						else
							_status = 1; //new loop
					}
					else if (_start != 0)
						_status = 1; //new loop
				}
			}
			
			drawFrame();
		}

		private function drawFrame():void
		{
			if (_frameCount>0 && _frame < _frames.length)
			{
				var frame:Frame = _frames[_frame];
				_bitmap.bitmapData = frame.image;
				if(_bitmap.smoothing!=_smoothing)
					_bitmap.smoothing = _smoothing;
				_bitmap.x = frame.rect.x;
				_bitmap.y = frame.rect.y;
			}
			else
				_bitmap.bitmapData = null;
		}
		
		private function checkTimer():void
		{
			if ((_playing || !_ready) && _frameCount>0 && this.stage!=null)
				GTimers.inst.add(1,0,update);
			else
				GTimers.inst.remove(update);
		}
		
		private function __addedToStage(evt:Event):void
		{
			if ((_playing || !_ready) && _frameCount>0)
				GTimers.inst.add(1,0,update);
		}
		
		private function __removedFromStage(evt:Event):void
		{
			GTimers.inst.remove(update);
		}
	}
}
