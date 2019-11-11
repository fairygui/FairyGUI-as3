package fairygui
{
	import flash.filters.ColorMatrixFilter;
	
	import fairygui.tween.EaseType;
	import fairygui.tween.GTween;
	import fairygui.tween.GTweener;
	import fairygui.utils.ColorMatrix;
	import fairygui.utils.ToolSet;
	import fairygui.tween.GPath;
	import fairygui.tween.CurveType;
	import fairygui.tween.GPathPoint;
	
	public class Transition
	{
		public var name:String;
		
		private var _owner:GComponent;
		private var _ownerBaseX:Number;
		private var _ownerBaseY:Number;
		private var _items:Vector.<TransitionItem>;
		private var _totalTimes:int;
		private var _totalTasks:int;
		private var _playing:Boolean;
		private var _paused:Boolean;
		private var _onComplete:Function;
		private var _onCompleteParam:Object;
		private var _options:int;
		private var _reversed:Boolean;
		private var _totalDuration:Number;
		private var _autoPlay:Boolean;
		private var _autoPlayTimes:int;
		private var _autoPlayDelay:Number;
		private var _timeScale:Number;
		private var _startTime:Number;
		private var _endTime:Number;
		
		private const OPTION_IGNORE_DISPLAY_CONTROLLER:int = 1;
		private const OPTION_AUTO_STOP_DISABLED:int = 2;
		private const OPTION_AUTO_STOP_AT_END:int = 4;

		private var helperPathPoints:Vector.<GPathPoint> = new Vector.<GPathPoint>();

		public function Transition(owner:GComponent)
		{
			_owner = owner;
			_items = new Vector.<TransitionItem>();
			_totalDuration = 0;
			_autoPlayTimes = 1;
			_autoPlayDelay = 0;
			_timeScale = 1;
			_startTime = 0;
			_endTime = 0;
		}
		
		public function play(onComplete:Function = null, onCompleteParam:Object = null,
							 times:int = 1, delay:Number = 0, startTime:Number = 0, endTime:Number = -1):void
		{
			_play(onComplete, onCompleteParam, times, delay, startTime, endTime, false);
		}
		
		public function playReverse(onComplete:Function = null, onCompleteParam:Object = null,
									times:int = 1, delay:Number = 0, startTime:Number = 0, endTime:Number = -1):void
		{
			_play(onComplete, onCompleteParam, 1, delay, startTime, endTime, true);
		}
		
		
		public function changePlayTimes(value:int):void
		{
			_totalTimes = value;
		}
		
		public function setAutoPlay(value:Boolean, times:int = 1, delay:Number = 0):void
		{
			if (_autoPlay != value)
			{
				_autoPlay = value;
				_autoPlayTimes = times;
				_autoPlayDelay = delay;
				
				if (_autoPlay)
				{
					if (_owner.onStage)
						play(null, null, _autoPlayTimes, _autoPlayDelay);
				}
				else
				{
					if (!_owner.onStage)
						stop(false, true);
				}
			}
		}
		
		private function _play(onComplete:Function = null, onCompleteParam:Object = null,
							   times:int = 1, delay:Number = 0, startTime:Number = 0, endTime:Number = -1, 
							   reversed:Boolean = false):void
		{
			stop(true, true);
			
			_totalTimes = times;
			_reversed = reversed;
			_startTime = startTime;
			_endTime = endTime;
			_playing = true;
			_paused = false;
			_onComplete = onComplete;
			_onCompleteParam = onCompleteParam;
			
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if(item.target == null)
				{
					if (item.targetId)
						item.target = _owner.getChildById(item.targetId);
					else
						item.target = _owner;
				}
				else if (item.target != _owner && item.target.parent != _owner)
					item.target = null;
				
				if (item.target != null && item.type == TransitionActionType.Transition)
				{
					var trans:Transition = GComponent(item.target).getTransition(item.value.transName);
					if(trans==this)
						trans = null;
					if (trans != null)
					{
						if (item.value.playTimes == 0) //stop
						{
							var j:int;
							for (j = i - 1; j >= 0; j--)
							{
								var item2:TransitionItem = _items[j];
								if (item2.type == TransitionActionType.Transition)
								{
									if (item2.value.trans == trans)
									{
										item2.value.stopTime = item.time - item2.time;
										break;
									}
								}
							}
							if(j<0)
								item.value.stopTime = 0;
							else
								trans = null;//no need to handle stop anymore
						}
						else
							item.value.stopTime = -1;
					}
					item.value.trans = trans;
				}
			}
			
			if(delay==0)
				onDelayedPlay();
			else
				GTween.delayedCall(delay).onComplete(onDelayedPlay);
		}
		
		public function stop(setToComplete:Boolean = true, processCallback:Boolean = false):void
		{
			if (!_playing)
				return;
			
			_playing = false;
			_totalTasks = 0;
			_totalTimes = 0;
			var func:Function = _onComplete;
			var param:Object = _onCompleteParam;
			_onComplete = null;
			_onCompleteParam = null;
			
			GTween.kill(this);//delay start
			
			var cnt:int = _items.length;
			if(_reversed)
			{
				for (var i:int = cnt-1; i >=0 ; i--)
				{
					var item:TransitionItem = _items[i];
					if(item.target==null)
						continue;
					
					stopItem(item, setToComplete);
				}
			}
			else
			{
				for (i = 0; i < cnt; i++)
				{
					item = _items[i];
					if(item.target==null)
						continue;
					
					stopItem(item, setToComplete);
				}
			}
			
			if (processCallback && func != null)
			{
				if(func.length>0)
					func(param);
				else
					func();
			}
		}
		
		private function stopItem(item:TransitionItem, setToComplete:Boolean):void
		{
			if (item.displayLockToken!=0)
			{
				item.target.releaseDisplayLock(item.displayLockToken);
				item.displayLockToken = 0;
			}
			
			if (item.tweener != null)
			{
				item.tweener.kill(setToComplete);
				item.tweener = null;
				
				if (item.type == TransitionActionType.Shake && !setToComplete) //震动必须归位，否则下次就越震越远了。
				{
					item.target._gearLocked = true;
					item.target.setXY(item.target.x - item.value.lastOffsetX, item.target.y - item.value.lastOffsetY);
					item.target._gearLocked = false;
				}
			}
			
			if (item.type == TransitionActionType.Transition)
			{
				var trans:Transition = item.value.trans;
				if (trans != null)
					trans.stop(setToComplete, false);
			}
		}
		
		public function setPaused(paused:Boolean):void
		{
			if (!_playing || _paused == paused)
				return;
			
			_paused = paused;
			var tweener:GTweener = GTween.getTween(this);
			if (tweener != null)
				tweener.setPaused(paused);
			
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.target == null)
					continue;
				
				if (item.type == TransitionActionType.Transition)
				{
					if (item.value.trans != null)
						item.value.trans.setPaused(paused);
				}
				else if (item.type == TransitionActionType.Animation)
				{
					if (paused)
					{
						item.value.flag = item.target.getProp(ObjectPropID.Playing);
						item.target.setProp(ObjectPropID.Playing, false);
					}
					else
						item.target.setProp(ObjectPropID.Playing, item.value.flag);
				}
				
				if (item.tweener != null)
					item.tweener.setPaused(paused);
			}
		}
		
		public function dispose():void
		{
			if(_playing)
				GTween.kill(this);//delay start
			
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.tweener != null)
				{
					item.tweener.kill();
					item.tweener = null;
				}
				
				item.target = null;
				item.hook = null;
				if (item.tweenConfig != null)
					item.tweenConfig.endHook = null;
			}
			
			_items.length = 0;
			_playing = false;
			_onComplete = null;
			_onCompleteParam = null;
		}
		
		public function get playing():Boolean
		{
			return _playing;
		}
		
		public function setValue(label:String, ...args):void
		{
			var cnt:int = _items.length;
			var value:Object;
			var found:Boolean = false;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.label == label)
				{
					if (item.tweenConfig != null)
						value = item.tweenConfig.startValue;
					else
						value = item.value;
					found = true;
				}
				else if (item.tweenConfig != null && item.tweenConfig.endLabel == label)
				{
					value = item.tweenConfig.endValue;
					found = true;
				}
				else
					continue;
				
				switch (item.type)
				{
					case TransitionActionType.XY:
					case TransitionActionType.Size:
					case TransitionActionType.Pivot:
					case TransitionActionType.Scale:
					case TransitionActionType.Skew:
						value.b1 = true;
						value.b2 = true;
						value.f1 = parseFloat(args[0]);
						value.f2 = parseFloat(args[1]);
						break;
					
					case TransitionActionType.Alpha:
						value.f1 = parseFloat(args[0]);
						break;
					
					case TransitionActionType.Rotation:
						value.f1 = parseFloat(args[0]);
						break;
					
					case TransitionActionType.Color:
						value.f1 = parseFloat(args[0]);
						break;
					
					case TransitionActionType.Animation:
						value.frame = parseInt(args[0]);
						if (args.length > 1)
							value.playing = args[1];
						break;
					
					case TransitionActionType.Visible:
						value.visible = args[0];
						break;
					
					case TransitionActionType.Sound:
						value.sound = args[0];
						if(args.length > 1)
							value.volume = parseFloat(args[1]);
						break;
					
					case TransitionActionType.Transition:
						value.transName = args[0];
						if (args.length > 1)
							value.playTimes = parseInt(args[1]);
						break;
					
					case TransitionActionType.Shake:
						value.amplitude = parseFloat(args[0]);
						if (args.length > 1)
							value.duration = parseFloat(args[1]);
						break;
					
					case TransitionActionType.ColorFilter:
						value.f1 = parseFloat(args[0]);
						value.f2 = parseFloat(args[1]);
						value.f3 = parseFloat(args[2]);
						value.f4 = parseFloat(args[3]);
						break;
					
					case TransitionActionType.Text:
					case TransitionActionType.Icon:
						value.text = args[0];
						break;
				}
			}
			
			if (!found)
				throw new Error("label not exists");
		}
		
		public function setHook(label:String, callback:Function):void
		{
			var found:Boolean = false;
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.label == label)
				{
					item.hook = callback;
					found = true;
					break;
				}
				else if (item.tweenConfig != null && item.tweenConfig.endLabel == label)
				{
					item.tweenConfig.endHook = callback;
					found = true;
					break;
				}
			}
			
			if (!found)
				throw new Error("label not exists");
		}
		
		public function clearHooks():void
		{
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				item.hook = null;
				if (item.tweenConfig != null)
					item.tweenConfig.endHook = null;
			}
		}
		
		public function setTarget(label:String, newTarget:GObject):void
		{
			var cnt:int = _items.length;
			var found:Boolean = false;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.label == label)
				{
					item.targetId = (newTarget == _owner || newTarget == null) ? "" : newTarget.id;
					if (_playing)
					{
						if (item.targetId.length > 0)
							item.target = _owner.getChildById(item.targetId);
						else
							item.target = _owner;
					}
					else
						item.target = null;
					found = true;
				}
			}
			
			if (!found)
				throw new Error("label not exists");
		}
		
		public function setDuration(label:String, value:Number):void
		{
			var cnt:int = _items.length;
			var found:Boolean = false;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.tweenConfig != null && item.label == label)
				{
					item.tweenConfig.duration = value;
					found = true;
				}
			}
			
			if (!found)
				throw new Error("label not exists");
		}
		
		public function getLabelTime(label:String):Number
		{
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.label == label)
					return item.time;
				else if (item.tweenConfig != null && item.tweenConfig.endLabel == label)
					return item.time + item.tweenConfig.duration;
			}
			
			return Number.NaN;
		}
		
		public function get timeScale():Number
		{
			return _timeScale;
		}
		
		public function set timeScale(value:Number):void
		{
			if(_timeScale != value)
			{		
				_timeScale = value;
				if (_playing)
				{
					var cnt:int = _items.length;
					for (var i:int = 0; i < cnt; i++)
					{
						var item:TransitionItem = _items[i];
						if (item.tweener != null)
							item.tweener.setTimeScale(value);
						else if (item.type == TransitionActionType.Transition)
						{
							if(item.value.trans != null)
								item.value.trans.timeScale = value;
						}
						else if(item.type == TransitionActionType.Animation)
						{
							if(item.target != null)
								item.target.setProp(ObjectPropID.TimeScale, value);
						}
					}
				}
			}
		}
		
		internal function updateFromRelations(targetId:String, dx:Number, dy:Number):void
		{
			var cnt:int = _items.length;
			if (cnt == 0)
				return;
			
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.type == TransitionActionType.XY && item.targetId == targetId)
				{
					if (item.tweenConfig!=null)
					{
						if(!item.tweenConfig.startValue.b3)
						{
							item.tweenConfig.startValue.f1 += dx;
							item.tweenConfig.startValue.f2 += dy;
						}
						if(!item.tweenConfig.endValue.b3)
						{
							item.tweenConfig.endValue.f1 += dx;
							item.tweenConfig.endValue.f2 += dy;
						}
					}
					else
					{
						if(!item.value.b3)
						{
							item.value.f1 += dx;
							item.value.f2 += dy;
						}
					}
				}
			}
		}
		
		internal function onOwnerAddedToStage():void
		{
			if (_autoPlay && !_playing)
				play(null, null, _autoPlayTimes, _autoPlayDelay);
		}
		
		internal function onOwnerRemovedFromStage():void
		{
			if ((_options & OPTION_AUTO_STOP_DISABLED) == 0)
				stop((_options & OPTION_AUTO_STOP_AT_END) != 0 ? true : false, false);
		}
		
		private function onDelayedPlay():void
		{
			internalPlay();
			
			_playing = _totalTasks>0;
			if (_playing)
			{				
				if ((_options & OPTION_IGNORE_DISPLAY_CONTROLLER) != 0)
				{
					var cnt:int = _items.length;
					for (var i:int = 0; i < cnt; i++)
					{
						var item:TransitionItem = _items[i];
						if (item.target != null && item.target!=_owner)
							item.displayLockToken = item.target.addDisplayLock();
					}
				}
			}
			else if (_onComplete != null)
			{
				var func:Function = _onComplete;
				var param:Object = _onCompleteParam;
				_onComplete = null;
				_onCompleteParam = null;
				if(func.length>0)
					func(param);
				else
					func();
			}
		}
		
		private function internalPlay():void
		{
			_ownerBaseX = _owner.x;
			_ownerBaseY = _owner.y;
			
			_totalTasks = 0;
			
			var cnt:int = _items.length;
			var item:TransitionItem;
			var needSkipAnimations:Boolean = false;
			
			if (!_reversed)
			{
				for (var i:int = 0; i < cnt; i++)
				{
					item = _items[i];
					if (item.target == null)
						continue;
					
					if (item.type == TransitionActionType.Animation && _startTime != 0 && item.time <= _startTime)
					{
						needSkipAnimations = true;
						item.value.flag = false;
					}
					else
						playItem(item);
				}
			}
			else
			{
				for (i = cnt - 1; i >= 0; i--)
				{
					item = _items[i];
					if (item.target == null)
						continue;
					
					playItem(item);
				}
			}
			
			if (needSkipAnimations)
				skipAnimations();
		}
		
		private function playItem(item:TransitionItem):void
		{
			var time:Number;
			if (item.tweenConfig != null)
			{
				if (_reversed)
					time = (_totalDuration - item.time - item.tweenConfig.duration);
				else
					time = item.time;
				if (_endTime == -1 || time <= _endTime)
				{
					var startValue:TValue;
					var endValue:TValue;
					if(_reversed)
					{
						startValue = item.tweenConfig.endValue;
						endValue = item.tweenConfig.startValue;
					}
					else
					{
						startValue = item.tweenConfig.startValue;
						endValue = item.tweenConfig.endValue;
					}
					
					item.value.b1 = startValue.b1 || endValue.b1;
					item.value.b2 = startValue.b2 || endValue.b2;
					
					switch(item.type)
					{
						case TransitionActionType.XY:
						case TransitionActionType.Size:
						case TransitionActionType.Scale:
						case TransitionActionType.Skew:
							item.tweener = GTween.to2(startValue.f1, startValue.f2, endValue.f1, endValue.f2, item.tweenConfig.duration);
							break;
						
						case TransitionActionType.Alpha:
						case TransitionActionType.Rotation:
							item.tweener = GTween.to(startValue.f1, endValue.f1, item.tweenConfig.duration);
							break;
						
						case TransitionActionType.Color:
							item.tweener = GTween.toColor(startValue.f1, endValue.f1, item.tweenConfig.duration);
							break;
						
						case TransitionActionType.ColorFilter:
							item.tweener = GTween.to4(startValue.f1,startValue.f2,startValue.f3,startValue.f4,
								endValue.f1,endValue.f2,endValue.f3,endValue.f4, item.tweenConfig.duration);
							break;
					}
					
					item.tweener.setDelay(time)
						.setEase(item.tweenConfig.easeType)
						.setRepeat(item.tweenConfig.repeat, item.tweenConfig.yoyo)
						.setTimeScale(_timeScale)
						.setTarget(item)
						.onStart(onTweenStart)
						.onUpdate(onTweenUpdate)
						.onComplete(onTweenComplete);
					
					if (_endTime >= 0)
						item.tweener.setBreakpoint(_endTime - time);
					
					_totalTasks++;
				}
			}
			else if(item.type==TransitionActionType.Shake)
			{
				if (_reversed)
					time = (_totalDuration - item.time - item.value.duration);
				else
					time = item.time;
				
				item.value.offsetX = item.value.offsetY = 0;
				item.value.lastOffsetX = item.value.lastOffsetY = 0;
				item.tweener = GTween.shake(0, 0, item.value.amplitude, item.value.duration)
					.setDelay(time)
					.setTimeScale(_timeScale)
					.setTarget(item)
					.onUpdate(onTweenUpdate)
					.onComplete(onTweenComplete);
				
				if (_endTime >= 0)
					item.tweener.setBreakpoint(_endTime - item.time);
				
				_totalTasks++;
			}
			else
			{
				if (_reversed)
					time = (_totalDuration - item.time);
				else
					time = item.time;
				
				if (time <= _startTime)
				{
					applyValue(item);
					callHook(item, false);
				}
				else if (_endTime == -1 || time <= _endTime)
				{
					_totalTasks++;
					item.tweener = GTween.delayedCall(time)
						.setTimeScale(_timeScale)
						.setTarget(item)
						.onComplete(onDelayedPlayItem);
				}
			}
			
			if (item.tweener != null)
				item.tweener.seek(_startTime);
		}
		
		private function skipAnimations():void
		{
			var frame:int;
			var playStartTime:Number;
			var playTotalTime:Number;
			var value:TValue_Animation;
			var target:GObject;
			var item:TransitionItem;
			
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				item = _items[i];
				if (item.type != TransitionActionType.Animation || item.time > _startTime)
					continue;
				
				value = TValue_Animation(item.value);
				if (value.flag)
					continue;
				
				target = item.target;
				frame = target.getProp(ObjectPropID.Frame);
				playStartTime = target.getProp(ObjectPropID.Playing) ? 0 : -1;
				playTotalTime = 0;
				
				for (var j:int = i; j < cnt; j++)
				{
					item = _items[j];
					if (item.type != TransitionActionType.Animation || item.target != target || item.time > _startTime)
						continue;
					
					value = TValue_Animation(item.value);
					value.flag = true;
					
					if (value.frame != -1)
					{
						frame = value.frame;
						if (value.playing)
							playStartTime = item.time;
						else
							playStartTime = -1;
						playTotalTime = 0;
					}
					else
					{
						if (value.playing)
						{
							if (playStartTime < 0)
								playStartTime = item.time;
						}
						else
						{
							if (playStartTime >= 0)
								playTotalTime += (item.time - playStartTime);
							playStartTime = -1;
						}
					}
					
					callHook(item, false);
				}
				
				if (playStartTime >= 0)
					playTotalTime += (_startTime - playStartTime);
				
				target.setProp(ObjectPropID.Playing, playStartTime>=0);
				target.setProp(ObjectPropID.Frame, frame);
				if (playTotalTime > 0)
					target.setProp(ObjectPropID.DeltaTime, playTotalTime*1000);
			}
		}
		
		private function onDelayedPlayItem(tweener:GTweener):void
		{
			var item:TransitionItem = TransitionItem(tweener.target);
			item.tweener = null;
			_totalTasks--;
			
			applyValue(item);
			callHook(item, false);
			
			checkAllComplete();
		}
		
		private function onTweenStart(tweener:GTweener):void
		{
			var item:TransitionItem = TransitionItem(tweener.target);

			if (item.type == TransitionActionType.XY || item.type == TransitionActionType.Size) //位置和大小要到start才最终确认起始值
			{
				var startValue:TValue;
				var endValue:TValue;
				
				if (_reversed)
				{
					startValue = item.tweenConfig.endValue;
					endValue = item.tweenConfig.startValue;
				}
				else
				{
					startValue = item.tweenConfig.startValue;
					endValue = item.tweenConfig.endValue;
				}
				
				if (item.type == TransitionActionType.XY)
				{
					if (item.target != _owner)
					{
						if (!startValue.b1)
							tweener.startValue.x = item.target.x;
						else if(startValue.b3) //percent
							tweener.startValue.x = startValue.f1 * _owner.width;

						if (!startValue.b2)
							tweener.startValue.y = item.target.y;
						else if(startValue.b3) //percent
							tweener.startValue.y = startValue.f2 * _owner.height;

						if (!endValue.b1)
							tweener.endValue.x = tweener.startValue.x;
						else if(endValue.b3)
							tweener.endValue.x = endValue.f1 * _owner.width;
						
						if (!endValue.b2)
							tweener.endValue.y = tweener.startValue.y;
						else if(endValue.b3)
							tweener.endValue.y = endValue.f2 * _owner.height;
					}
					else
					{
						if (!startValue.b1)
							tweener.startValue.x = item.target.x - _ownerBaseX;
						if (!startValue.b2)
							tweener.startValue.y = item.target.y - _ownerBaseY;

						if (!endValue.b1)
							tweener.endValue.x = tweener.startValue.x;
						if (!endValue.b2)
							tweener.endValue.y = tweener.startValue.y;
					}
				}
				else
				{
					if (!startValue.b1)
						tweener.startValue.x = item.target.width;
					if (!startValue.b2)
						tweener.startValue.y = item.target.height;

					if (!endValue.b1)
						tweener.endValue.x = tweener.startValue.x;
					if (!endValue.b2)
						tweener.endValue.y = tweener.startValue.y;
				}

				if(item.tweenConfig.path)
				{
					item.value.b1 = item.value.b2 = true;
					tweener.setPath(item.tweenConfig.path);
				}
			}
			
			callHook(item, false);
		}
		
		private function onTweenUpdate(tweener:GTweener):void
		{
			var item:TransitionItem = TransitionItem(tweener.target);
			switch (item.type)
			{
				case TransitionActionType.XY:
				case TransitionActionType.Size:
				case TransitionActionType.Scale:
				case TransitionActionType.Skew:
					item.value.f1 = tweener.value.x;
					item.value.f2 = tweener.value.y;
					if(item.tweenConfig.path)
					{
						item.value.f1 += tweener.startValue.x;
						item.value.f2 += tweener.startValue.y;
					}
					break;
				
				case TransitionActionType.Alpha:
				case TransitionActionType.Rotation:
					item.value.f1 = tweener.value.x;
					break;
				
				case TransitionActionType.Color:
					item.value.f1 = tweener.value.color;
					break;
				
				case TransitionActionType.ColorFilter:
					item.value.f1 = tweener.value.x;
					item.value.f2 = tweener.value.y;
					item.value.f3 = tweener.value.z;
					item.value.f4 = tweener.value.w;
					break;
				
				case TransitionActionType.Shake:
					item.value.offsetX = tweener.deltaValue.x;
					item.value.offsetY = tweener.deltaValue.y;
					break;
			}
			
			applyValue(item);
		}
		
		private function onTweenComplete(tweener:GTweener):void
		{
			var item:TransitionItem = TransitionItem(tweener.target);
			item.tweener = null;
			_totalTasks--;
			
			if (tweener.allCompleted) //当整体播放结束时间在这个tween的中间时不应该调用结尾钩子
				callHook(item, true);
			
			checkAllComplete();
		}
		
		private function onPlayTransCompleted(item:TransitionItem):void
		{
			_totalTasks--;
			
			checkAllComplete();
		}
		
		private function callHook(item:TransitionItem, tweenEnd:Boolean):void
		{
			if (tweenEnd)
			{
				if (item.tweenConfig!=null && item.tweenConfig.endHook != null)
					item.tweenConfig.endHook();
			}
			else
			{
				if (item.time >= _startTime && item.hook != null)
					item.hook();
			}
		}
		
		private function checkAllComplete():void
		{
			if (_playing && _totalTasks == 0)
			{
				if (_totalTimes < 0)
				{
					internalPlay();
				}
				else
				{
					_totalTimes--;
					if (_totalTimes > 0)
						internalPlay();
					else
					{
						_playing = false;
						
						var cnt:int = _items.length;				
						for (var i:int = 0; i < cnt; i++)
						{
							var item:TransitionItem = _items[i];
							if (item.target != null && item.displayLockToken!=0)
							{
								item.target.releaseDisplayLock(item.displayLockToken);
								item.displayLockToken = 0;
							}
						}
						
						if (_onComplete != null)
						{
							var func:Function = _onComplete;
							var param:Object = _onCompleteParam;
							_onComplete = null;
							_onCompleteParam = null;
							if(func.length>0)
								func(param);
							else
								func();
						}
					}
				}
			}
		}
		
		private function applyValue(item:TransitionItem):void
		{
			item.target._gearLocked = true;
			var value:Object = item.value;
			
			switch (item.type)
			{
				case TransitionActionType.XY:
					if(item.target==_owner)
					{
						if (value.b1 && value.b2)
							item.target.setXY(value.f1+_ownerBaseX, value.f2+_ownerBaseY);
						else if (value.b1)
							item.target.x = value.f1+_ownerBaseX;
						else
							item.target.y = value.f2+_ownerBaseY;
					}
					else
					{
						if(value.b3) //position in percent
						{
							if(value.b1 && value.b2)
								item.target.setXY(value.f1*_owner.width, value.f2*_owner.height);
							else if(value.b1)
								item.target.x = value.f1*_owner.width;
							else if(value.b2)
								item.target.y = value.f2*_owner.height;
						}
						else
						{
							if(value.b1 && value.b2)
								item.target.setXY(value.f1, value.f2);
							else if(value.b1)
								item.target.x = value.f1;
							else if(value.b2)
								item.target.y = value.f2;
						}
					}
					break;
				
				case TransitionActionType.Size:
					if (!value.b1)
						value.f1 = item.target.width;
					if (!value.b2)
						value.f2 = item.target.height;
					item.target.setSize(value.f1, value.f2);
					break;
				
				case TransitionActionType.Pivot:
					item.target.setPivot(value.f1, value.f2, item.target.pivotAsAnchor);
					break;
				
				case TransitionActionType.Alpha:
					item.target.alpha = value.f1;
					break;
				
				case TransitionActionType.Rotation:
					item.target.rotation = value.f1;
					break;
				
				case TransitionActionType.Scale: 
					item.target.setScale(value.f1, value.f2);
					break;
				
				case TransitionActionType.Skew:
					//todo
					break;
				
				case TransitionActionType.Color:
					item.target.setProp(ObjectPropID.Color, value.f1);
					break;
				
				case TransitionActionType.Animation:
					if (value.frame>=0)
						item.target.setProp(ObjectPropID.Frame, value.frame);
					item.target.setProp(ObjectPropID.Playing, value.playing);
					item.target.setProp(ObjectPropID.TimeScale, _timeScale);
					break;
				
				case TransitionActionType.Visible:
					item.target.visible = value.visible;
					break;
				
				case TransitionActionType.Transition:
					if (_playing)
					{
						var trans:Transition = value.trans;
						if (trans != null)
						{
							_totalTasks++;
							var startTime:Number = _startTime > item.time ? (_startTime - item.time) : 0;
							var endTime:Number = _endTime >= 0 ? (_endTime - item.time) : -1;
							if (value.stopTime >= 0 && (endTime < 0 || endTime > value.stopTime))
								endTime = value.stopTime;
							trans.timeScale = _timeScale;
							trans._play(onPlayTransCompleted, item, value.playTimes, 0, startTime, endTime, _reversed);
						}
					}
					break;
				
				case TransitionActionType.Sound:
					if (_playing && item.time >= _startTime)
					{
						if(value.audioClip==null)
						{
							var pi:PackageItem = UIPackage.getItemByURL(value.sound);
							if(pi)
								value.audioClip = pi.owner.getSound(pi);
						}
						if(value.audioClip)
							GRoot.inst.playOneShotSound(value.audioClip, value.volume);
					}
					break;
				
				case TransitionActionType.Shake:
					item.target.setXY(item.target.x - value.lastOffsetX + value.offsetX, item.target.y - value.lastOffsetY + value.offsetY);
					value.lastOffsetX = value.offsetX;
					value.lastOffsetY = value.offsetY;
					break;
				
				case TransitionActionType.ColorFilter:
					{
						var cf:ColorMatrixFilter;
						var arr:Array = item.target.filters;
						
						if (arr == null || !(arr[0] is ColorMatrixFilter))
						{
							cf = new ColorMatrixFilter();	
							arr = [cf];
						}
						else
							cf = ColorMatrixFilter(arr[0]);
						
						var cm:ColorMatrix = new ColorMatrix();
						cm.adjustBrightness(value.f1);
						cm.adjustContrast(value.f2);
						cm.adjustSaturation(value.f3);
						cm.adjustHue(value.f4);
						cf.matrix = cm;
						item.target.filters = arr;
					}
					break;
				
				case TransitionActionType.Text:
					item.target.text = value.text;
					break;
				
				case TransitionActionType.Icon:
					item.target.icon = value.text;
					break;
			}
			
			item.target._gearLocked = false;
		}
		
		public function setup(xml:XML):void
		{
			this.name = xml.@name;
			var str:String = xml.@options;
			if(str)
				_options = parseInt(str); 
			_autoPlay = xml.@autoPlay=="true";
			if(_autoPlay) {
				str = xml.@autoPlayRepeat;
				if(str)
					_autoPlayTimes = parseInt(str);
				str = xml.@autoPlayDelay;
				if(str)
					_autoPlayDelay = parseFloat(str);
			}
			str = xml.@fps;
			var frameInterval:Number;
			if(str)
				frameInterval = 1/parseInt(str);
			else
				frameInterval = 1/24;
			
			var col:XMLList = xml.item;
			for each (var cxml:XML in col)
			{
				var item:TransitionItem = new TransitionItem(parseItemType(cxml.@type));
				_items.push(item);
				
				item.time = parseInt(cxml.@time) * frameInterval;
				item.targetId = cxml.@target;
				
				if(cxml.@tween=="true")
					item.tweenConfig = new TweenConfig();
				item.label = cxml.@label;
				if(item.label.length==0)
					item.label = null;
				
				if (item.tweenConfig != null)
				{
					item.tweenConfig.duration = parseInt(cxml.@duration) * frameInterval;
					if(item.time+item.tweenConfig.duration>_totalDuration)
						_totalDuration = item.time+item.tweenConfig.duration;
					
					str = cxml.@ease;
					if (str)
						item.tweenConfig.easeType = EaseType.parseEaseType(str);
					
					item.tweenConfig.repeat = parseInt(cxml.@repeat);
					item.tweenConfig.yoyo = cxml.@yoyo=="true";
					item.tweenConfig.endLabel = cxml.@label2;
					if(item.tweenConfig.endLabel.length==0)
						item.tweenConfig.endLabel = null;
					
					var v:String = cxml.@endValue;
					if (v)
					{
						decodeValue(item, cxml.@startValue, item.tweenConfig.startValue);
						decodeValue(item, v, item.tweenConfig.endValue);
					}
					else
					{
						item.tweenConfig = null;
						decodeValue(item, cxml.@startValue, item.value);
					}

					str = cxml.@path;
					if(str)
					{
						var arr:Array = str.split(",");
						var path:GPath = new GPath();
						item.tweenConfig.path = path;
						helperPathPoints.length = 0;

						var cnt:int = arr.length;
						var i:int = 0;
						while(i<cnt)
						{
							var ppt:GPathPoint = new GPathPoint();
							ppt.curveType = parseInt(arr[i++]);
							switch(ppt.curveType)
							{
								case CurveType.Bezier:
									ppt.x = parseInt(arr[i++]);
									ppt.y = parseInt(arr[i++]);
									ppt.control1_x = parseInt(arr[i++]);
									ppt.control1_y = parseInt(arr[i++]);
									break;

								case CurveType.CubicBezier:
									ppt.x = parseInt(arr[i++]);
									ppt.y = parseInt(arr[i++]);
									ppt.control1_x = parseInt(arr[i++]);
									ppt.control1_y = parseInt(arr[i++]);
									ppt.control2_x = parseInt(arr[i++]);
									ppt.control2_y = parseInt(arr[i++]);
									ppt.smooth = arr[i++]=="1";
									break;

								default:
									ppt.x = parseInt(arr[i++]);
									ppt.y = parseInt(arr[i++]);
									break;
							}
							helperPathPoints.push(ppt);
						}

						path.create(helperPathPoints);
					}
				}
				else
				{
					if(item.time>_totalDuration)
						_totalDuration = item.time;
					decodeValue(item, cxml.@value, item.value);
				}
			}
		}
		
		private function parseItemType(str:String):int
		{
			var type:int;
			switch(str)
			{
				case "XY":
					type = TransitionActionType.XY;
					break;
				case "Size":
					type = TransitionActionType.Size;
					break;
				case "Scale":
					type = TransitionActionType.Scale;
					break;
				case "Pivot":
					type = TransitionActionType.Pivot;
					break;
				case "Alpha":
					type = TransitionActionType.Alpha;
					break;
				case "Rotation":
					type = TransitionActionType.Rotation;
					break;
				case "Color":
					type = TransitionActionType.Color;
					break;
				case "Animation":
					type = TransitionActionType.Animation;
					break;
				case "Visible":
					type = TransitionActionType.Visible;
					break;
				case "Sound":
					type = TransitionActionType.Sound;
					break;
				case "Transition":
					type = TransitionActionType.Transition;
					break;
				case "Shake":
					type = TransitionActionType.Shake;
					break;
				case "ColorFilter":
					type = TransitionActionType.ColorFilter;
					break;
				case "Skew":
					type = TransitionActionType.Skew;
					break;
				case "Text":
					type = TransitionActionType.Text;
					break;
				case "Icon":
					type = TransitionActionType.Icon;
					break;
				default:
					type = TransitionActionType.Unknown;
					break;
			}
			return type;
		}
		
		private function decodeValue(item:TransitionItem, str:String, value:Object):void
		{
			var arr:Array;
			switch(item.type)
			{
				case TransitionActionType.XY:
				case TransitionActionType.Size:
				case TransitionActionType.Pivot:
				case TransitionActionType.Skew:
					arr = str.split(",");
					if (arr[0] == "-")
					{
						value.b1 = false;
					}
					else
					{
						value.f1 = parseFloat(arr[0]);
						value.b1 = true;
					}
					if(arr[1]=="-")
					{
						value.b2 = false;
					}
					else
					{
						value.f2 = parseFloat(arr[1]);
						value.b2 = true;
					}

					if(arr.length>2 && item.type==TransitionActionType.XY)
					{
						value.b3 = true;
						value.f1 = parseFloat(arr[2]);
						value.f2 = parseFloat(arr[3]);
					}
					break;
				
				case TransitionActionType.Alpha:
					value.f1 = parseFloat(str);
					break;
				
				case TransitionActionType.Rotation:
					value.f1 = parseFloat(str);
					break;
				
				case TransitionActionType.Scale:
					arr = str.split(",");
					value.f1 = parseFloat(arr[0]);
					value.f2 = parseFloat(arr[1]);
					break;
				
				case TransitionActionType.Color:
					value.f1 = ToolSet.convertFromHtmlColor(str);
					break;
				
				case TransitionActionType.Animation:
					arr = str.split(",");
					if(arr[0]=="-")
						value.frame = -1;
					else
						value.frame = parseInt(arr[0]);
					value.playing = arr[1]=="p";
					break;
				
				case TransitionActionType.Visible:
					value.visible = str=="true";
					break;
				
				case TransitionActionType.Sound:
					arr = str.split(",");
					value.sound = arr[0];
					if(arr.length>1)
					{
						var intv:int = parseInt(arr[1]);
						if(intv==0 || intv==100)
							value.volume = 1;
						else
							value.volume = intv/100;
					}
					else
						value.volume = 1;
					break;
				
				case TransitionActionType.Transition:
					arr = str.split(",");
					value.transName = arr[0];
					if (arr.length > 1)
						value.playTimes = parseInt(arr[1]);
					else
						value.playTimes = 1;
					break;
				
				case TransitionActionType.Shake:
					arr = str.split(",");
					value.amplitude = parseFloat(arr[0]);
					value.duration = parseFloat(arr[1]);
					break;
				
				case TransitionActionType.ColorFilter:
					arr = str.split(",");
					value.f1 = parseFloat(arr[0]);
					value.f2 = parseFloat(arr[1]);
					value.f3 = parseFloat(arr[2]);
					value.f4 = parseFloat(arr[3]);
					break;
				
				case TransitionActionType.Text:
				case TransitionActionType.Icon:
					value.text = str;
					break;
			}
		}
	}
}

import flash.media.Sound;

import fairygui.GObject;
import fairygui.Transition;
import fairygui.tween.EaseType;
import fairygui.tween.GTweener;
import fairygui.tween.GPath;

class TransitionActionType
{
	public static const XY:int=0;
	public static const Size:int=1;
	public static const Scale:int=2;
	public static const Pivot:int=3;
	public static const Alpha:int=4;
	public static const Rotation:int=5;
	public static const Color:int=6;
	public static const Animation:int=7;
	public static const Visible:int = 8;
	public static const Sound:int=9;
	public static const Transition:int=10;
	public static const Shake:int = 11;
	public static const ColorFilter:int = 12;
	public static const Skew:int = 13;
	public static const Text:int = 14;
	public static const Icon:int = 15;
	public static const Unknown:int = 16;
}

class TransitionItem
{
	public var time:Number;
	public var targetId:String;
	public var type:int;
	public var tweenConfig:TweenConfig;
	public var label:String;
	public var value:Object;
	public var hook:Function;
	
	public var tweener:GTweener;
	public var target:GObject;
	public var displayLockToken:uint;
	
	public function TransitionItem(type:int)
	{
		this.type = type;
		
		switch (type)
		{
			case TransitionActionType.XY:
			case TransitionActionType.Size:
			case TransitionActionType.Scale:
			case TransitionActionType.Pivot:
			case TransitionActionType.Skew:
			case TransitionActionType.Alpha:
			case TransitionActionType.Rotation:
			case TransitionActionType.Color:
			case TransitionActionType.ColorFilter:
				value = new TValue();
				break;
			
			case TransitionActionType.Animation:
				value = new TValue_Animation();
				break;
			
			case TransitionActionType.Shake:
				value = new TValue_Shake();
				break;
			
			case TransitionActionType.Sound:
				value = new TValue_Sound();
				break;
			
			case TransitionActionType.Transition:
				value = new TValue_Transition();
				break;
			
			case TransitionActionType.Visible:
				value = new TValue_Visible();
				break;
			
			case TransitionActionType.Text:
			case TransitionActionType.Icon:
				value = new TValue_Text();
				break;
		}
	}
}

class TweenConfig
{
	public var duration:Number;
	public var easeType:int;
	public var repeat:int;
	public var yoyo:Boolean;
	public var startValue:TValue;
	public var endValue:TValue;
	public var path:GPath;
	public var endLabel:String;
	public var endHook:Function;
	
	public function TweenConfig()
	{
		easeType = EaseType.QuadOut;
		startValue = new TValue();
		endValue = new TValue();
	}
}

class TValue_Visible
{
	public var visible:Boolean;
	public function TValue_Visible()
	{
	}
}

class TValue_Animation
{
	public var frame:int;
	public var playing:Boolean;
	public var flag:Boolean;
	public function TValue_Animation()
	{
	}
}

class TValue_Sound
{
	public var sound:String;
	public var volume:Number;
	public var audioClip:Sound;
	public function TValue_Sound()
	{
	}
}

class TValue_Transition
{
	public var transName:String;
	public var playTimes:int;
	public var trans:Transition;
	public var stopTime:Number;
	public function TValue_Transition()
	{
	}
}

class TValue_Shake
{
	public var amplitude:Number;
	public var duration:Number;
	public var offsetX:Number;
	public var offsetY:Number;
	public var lastOffsetX:Number;
	public var lastOffsetY:Number;
	public function TValue_Shake()
	{
	}
}

class TValue_Text
{
	public var text:String;
	public function TValue_Text()
	{
	}
}

class TValue
{
	public var f1:Number;
	public var f2:Number;
	public var f3:Number;
	public var f4:Number;
	
	public var b1:Boolean;
	public var b2:Boolean;
	public var b3:Boolean;
	
	public function TValue()
	{
		b1 = b2 = true;
	}
}