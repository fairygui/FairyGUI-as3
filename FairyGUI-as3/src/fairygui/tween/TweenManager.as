package fairygui.tween
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;

	public class TweenManager
	{
		private static var _activeTweens:Array = new Array(30);
		private static var _tweenerPool:Vector.<GTweener> = new Vector.<GTweener>();
		private static var _totalActiveTweens:int = 0;
		private static var _timer:Timer = null;
		private static var _lastTime:int;
		
		internal static function createTween():GTweener
		{
			if (!_timer)
			{
				_timer = new Timer(10);
				_timer.addEventListener(TimerEvent.TIMER, update);
				_timer.start();
				_lastTime = getTimer();
			}
			
			var tweener:GTweener;
			var cnt:int = _tweenerPool.length;
			if (cnt > 0)
			{
				tweener = _tweenerPool.pop();
			}
			else
				tweener = new GTweener();
			tweener._init();
			_activeTweens[_totalActiveTweens++] = tweener;
			
			if (_totalActiveTweens == _activeTweens.length)
				_activeTweens.length = _activeTweens.length + Math.ceil(_activeTweens.length * 0.5);
			
			return tweener;
		}
		
		internal static function isTweening(target:Object, propType:Object):Boolean
		{
			if (target == null)
				return false;
			
			var anyType:Boolean = propType == null;
			for (var i:int = 0; i < _totalActiveTweens; i++)
			{
				var tweener:GTweener = _activeTweens[i];
				if (tweener != null && tweener.target == target && !tweener._killed
					&& (anyType || tweener._propType == propType))
					return true;
			}
			
			return false;
		}
		
		internal static function killTweens(target:Object, completed:Boolean, propType:Object):Boolean
		{
			if (target == null)
				return false;
			
			var flag:Boolean = false;
			var cnt:int = _totalActiveTweens;
			var anyType:Boolean = propType == null;
			for (var i:int = 0; i < cnt; i++)
			{
				var tweener:GTweener = _activeTweens[i];
				if (tweener != null && tweener.target == target && !tweener._killed
					&& (anyType || tweener._propType == propType))
				{
					tweener.kill(completed);
					flag = true;
				}
			}
			
			return flag;
		}
		
		internal static function getTween(target:Object, propType:Object):GTweener
		{
			if (target == null)
				return null;
			
			var cnt:int = _totalActiveTweens;
			var anyType:Boolean = propType == null;
			for (var i:int = 0; i < cnt; i++)
			{
				var tweener:GTweener = _activeTweens[i];
				if (tweener != null && tweener.target == target && !tweener._killed
					&& (anyType || tweener._propType == propType))
				{
					return tweener;
				}
			}
			
			return null;
		}
		
		internal static function update(evt:Event):void
		{
			var time:int =  getTimer();
			var dt:Number = time-_lastTime;
			_lastTime = time;
			dt /= 1000;
			
			var cnt:int = _totalActiveTweens;
			var freePosStart:int = -1;
			var freePosCount:int = 0;
			for (var i:int = 0; i < cnt; i++)
			{
				var tweener:GTweener = _activeTweens[i];
				if (tweener == null)
				{
					if (freePosStart == -1)
						freePosStart = i;
					freePosCount++;
				}
				else if (tweener._killed)
				{
					tweener._reset();
					_tweenerPool.push(tweener);
					_activeTweens[i] = null;
					
					if (freePosStart == -1)
						freePosStart = i;
					freePosCount++;
				}
				else
				{
					if(!tweener._paused)
						tweener._update(dt);
					
					if (freePosStart != -1)
					{
						_activeTweens[freePosStart] = tweener;
						_activeTweens[i] = null;
						freePosStart++;
					}
				}
			}
			
			if (freePosStart >= 0)
			{
				if (_totalActiveTweens != cnt) //new tweens added
				{
					var j:int = cnt;
					cnt = _totalActiveTweens - cnt;
					for (i = 0; i < cnt; i++)
						_activeTweens[freePosStart++] = _activeTweens[j++];
				}
				_totalActiveTweens = freePosStart;
			}
		}
	}
}