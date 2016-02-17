package fairygui
{
	import com.greensock.TweenMax;
	import com.greensock.easing.EaseLookup;
	
	import flash.media.Sound;
	import flash.utils.getTimer;
	
	import fairygui.utils.GTimers;
	import fairygui.utils.ToolSet;
	
	public class Transition
	{
		private var _name:String;
		private var _owner:GComponent;
		private var _ownerBaseX:Number;
		private var _ownerBaseY:Number;
		private var _items:Vector.<TransitionItem>;
		private var _totalTimes:int;
		private var _totalTasks:int;
		private var _playing:Boolean;
		private var _onComplete:Function;
		private var _onCompleteParam:Object;
		private var _options:int;
		private var _reversed:Boolean;
		private var _maxTime:Number;
		
		public const OPTION_IGNORE_DISPLAY_CONTROLLER:int = 1;
		
		private const FRAME_RATE:int = 24;
		
		public function Transition(owner:GComponent)
		{
			_owner = owner;
			_items = new Vector.<TransitionItem>();
			_maxTime = 0;
		}
		
		public function get name():String
		{
			return _name;
		}
		
		public function set name(value:String):void
		{
			_name = value;
		}
		
		public function play(onComplete:Function = null, onCompleteParam:Object = null,
							 times:int = 1, delay:Number = 0):void
		{
			_play(onComplete, onCompleteParam, times, delay, false);
		}
		
		public function playReverse(onComplete:Function = null, onCompleteParam:Object = null,
									times:int = 1, delay:Number = 0):void
		{
			_play(onComplete, onCompleteParam, 1, delay, true);
		}
		
		private function _play(onComplete:Function = null, onCompleteParam:Object = null,
							   times:int = 1, delay:Number = 0, reversed:Boolean = false):void
		{
			stop();
			
			if (times < 0)
				times = int.MAX_VALUE;
			else if(times==0)
				times = 1;
			_totalTimes = times;
			_reversed = reversed;
			internalPlay(delay);
			_playing = _totalTasks>0;
			
			if (_playing)
			{
				_onComplete = onComplete;
				_onCompleteParam = onCompleteParam;
				
				_owner.internalVisible++;
				if ((_options & OPTION_IGNORE_DISPLAY_CONTROLLER) != 0)
				{
					var cnt:int = _items.length;
					for (var i:int = 0; i < cnt; i++)
					{
						var item:TransitionItem = _items[i];
						if (item.target != null && item.target!=_owner)
							item.target.internalVisible++;
					}
				}
			}
			else if (onComplete != null)
			{
				if(onComplete.length>0)
					onComplete(onCompleteParam);
				else
					onComplete();
			}
		}
		
		public function stop(setToComplete:Boolean = true, processCallback:Boolean = false):void
		{
			if (_playing)
			{
				_playing = false;
				_totalTasks = 0;
				_totalTimes = 0;
				var func:Function = _onComplete;
				var param:Object = _onCompleteParam;
				_onComplete = null;
				_onCompleteParam = null;
				
				_owner.internalVisible--;
				
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
		}
		
		private function stopItem(item:TransitionItem, setToComplete:Boolean):void
		{
			if ((_options & OPTION_IGNORE_DISPLAY_CONTROLLER) != 0)
			{
				if (item.target != _owner)
					item.target.internalVisible--;
			}
			
			if(item.completed)
				return;
			
			if (item.tweener != null)
			{
				item.tweener.kill();
				item.tweener = null;
			}
			
			if (item.type == TransitionActionType.Transition)
			{
				var trans:Transition  = GComponent(item.target).getTransition(item.value.s);
				if (trans != null)
					trans.stop(setToComplete, false);
			}
			else if(item.type == TransitionActionType.Shake)
			{
				if (GTimers.inst.exists(item.__shake))
				{
					GTimers.inst.remove(item.__shake);
					item.target._gearLocked = true;
					item.target.setXY(item.target.x-item.startValue.f1, item.target.y-item.startValue.f2);
					item.target._gearLocked = false;
				}
			}
			else
			{
				if (setToComplete)
				{
					if (item.tween)
					{
						if (!item.yoyo || item.repeat % 2 == 0)
							applyValue(item, _reversed?item.startValue:item.endValue);
						else
							applyValue(item, _reversed?item.endValue:item.startValue);
					}
					else if(item.type != TransitionActionType.Sound)
						applyValue(item, item.value);
				}
			}
		}		
		
		public function get playing():Boolean
		{
			return _playing;
		}
		
		public function setValue(label:String, ...args):void
		{
			var cnt:int = _items.length;
			var value:TransitionValue;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.label == null && item.label2 == null)
					continue;
				
				if (item.label == label)
				{
					if (item.tween)
						value = item.startValue;
					else
						value = item.value;
				}
				else if (item.label2 == label)
				{
					value = item.endValue;
				}
				else
					continue;
				
				switch (item.type)
				{
					case TransitionActionType.XY:
					case TransitionActionType.Size:
					case TransitionActionType.Pivot:
					case TransitionActionType.Scale:
						value.b1 = true;
						value.b2 = true;
						value.f1 = parseFloat(args[0]);
						value.f2 = parseFloat(args[1]);
						break;
					
					case TransitionActionType.Alpha:
						value.f1 = parseFloat(args[0]);
						break;
					
					case TransitionActionType.Rotation:
						value.i = parseInt(args[0]);
						break;
					
					case TransitionActionType.Color:
						value.c = parseFloat(args[0]);
						break;
					
					case TransitionActionType.Animation:
						value.i = parseInt(args[0]);
						if (args.length > 1)
							value.b = args[1];
						break;
					
					case TransitionActionType.Visible:
						value.b = args[0];
						break;
					
					case TransitionActionType.Controller:
						value.s = args[0];
						break;
					
					case TransitionActionType.Sound:
						value.s = args[0];
						if(args.length > 1)
							value.f1 = parseFloat(args[1]);
						break;
					
					case TransitionActionType.Transition:
						value.s = args[0];
						if (args.length > 1)
							value.i = parseInt(args[1]);
						break;
					
					case TransitionActionType.Shake:
						value.f1 = parseFloat(args[0]);
						if (args.length > 1)
							value.f2 = parseFloat(args[1]);
						break;
				}
			}
		}
		
		public function setHook(label:String, callback:Function):void
		{
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.label == null && item.label2 == null)
					continue;
				
				if (item.label == label)
				{
					item.hook = callback;
				}
				else if (item.label2 == label)
				{
					item.hook2 = callback;
				}
			}
		}
		
		public function clearHooks():void
		{
			var cnt:int = _items.length;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				item.hook = null;
				item.hook2 = null;
			}
		}
		
		public function setTarget(label:String, newTarget:GObject):void
		{
			var cnt:int = _items.length;
			var value:TransitionValue;
			for (var i:int = 0; i < cnt; i++)
			{
				var item:TransitionItem = _items[i];
				if (item.label == null && item.label2 == null)
					continue;
				
				item.targetId = newTarget.id;
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
					if (item.tween)
					{
						item.startValue.f1 += dx;
						item.startValue.f2 += dy;
						item.endValue.f1 += dx;
						item.endValue.f2 += dy;
					}
					else
					{
						item.value.f1 += dx;
						item.value.f2 += dy;
					}
				}
			}
		}
		
		private function internalPlay(delay:Number):void
		{
			_ownerBaseX = _owner.x;
			_ownerBaseY = _owner.y;
			
			_totalTasks = 0;
			var cnt:int = _items.length;
			var parms:Object;
			var i:int;
			var item:TransitionItem;
			var startTime:Number;
			
			for (i = 0; i < cnt; i++)
			{
				item = _items[i];
				if (item.targetId)
					item.target = _owner.getChildById(item.targetId);
				else
					item.target = _owner;
				if (item.target == null)
					continue;
				
				if (item.tween)
				{
					item.completed = false;
					if(_reversed)
						startTime = delay + _maxTime - item.time - item.duration;
					else
						startTime = delay + item.time;
					switch (item.type)
					{
						case TransitionActionType.XY:
						case TransitionActionType.Size:
							_totalTasks++;
							if (startTime == 0)
								startTween(item);
							else
								item.tweener = TweenMax.delayedCall(startTime, __delayCall, item.params);
							break;
						
						case TransitionActionType.Scale:
						case TransitionActionType.Alpha:
						case TransitionActionType.Rotation:
							_totalTasks++;
							parms = {};
							if(_reversed)
							{
								switch(item.type)
								{
									case TransitionActionType.Scale:
										item.value.f1 = item.endValue.f1;
										item.value.f2 = item.endValue.f2;
										parms.f1 = item.startValue.f1;
										parms.f2 = item.startValue.f2;
										break;
									
									case TransitionActionType.Alpha:
										item.value.f1 = item.endValue.f1;
										parms.f1 = item.startValue.f1;
										break;
									
									case TransitionActionType.Rotation:
										item.value.i = item.endValue.i;
										parms.i = item.startValue.i;										
										break;
								}
							}
							else
							{
								switch(item.type)
								{
									case TransitionActionType.Scale:
										item.value.f1 = item.startValue.f1;
										item.value.f2 = item.startValue.f2;
										parms.f1 = item.endValue.f1;
										parms.f2 = item.endValue.f2;
										break;
									
									case TransitionActionType.Alpha:
										item.value.f1 = item.startValue.f1;
										parms.f1 = item.endValue.f1;
										break;
									
									case TransitionActionType.Rotation:
										item.value.i = item.startValue.i;
										parms.i = item.endValue.i;							
										break;
								}
							}
							parms.ease = item.easeType;
							parms.onStart = __tweenStart;
							parms.onStartParams = item.params;
							parms.onUpdate = __tweenUpdate;
							parms.onUpdateParams = item.params;
							parms.onComplete = __tweenComplete;
							parms.onCompleteParams = item.params;
							if (startTime > 0)
								parms.delay = startTime;
							else
								applyValue(item, item.value);
							if (item.repeat != 0)
							{
								if(item.repeat==-1)
									parms.repeat = int.MAX_VALUE;
								else
									parms.repeat = item.repeat;
								parms.yoyo = item.yoyo;
							}							
							item.tweener = TweenMax.to(item.value, item.duration, parms);
							break;
					}
				}
				else
				{
					if(_reversed)
						startTime = delay + _maxTime - item.time;
					else
						startTime = delay + item.time;
					
					if (startTime == 0)
						applyValue(item, item.value);
					else
					{
						item.completed = false;
						_totalTasks++;
						item.tweener =  TweenMax.delayedCall(startTime, __delayCall2, item.params);
					}
				}
			}
		}
		
		private function startTween(item:TransitionItem):void
		{
			var parms:Object = {};
			parms.ease = item.easeType;
			parms.onUpdate = __tweenUpdate;
			parms.onUpdateParams = item.params;
			parms.onComplete = __tweenComplete;
			parms.onCompleteParams = item.params;
			
			if(_reversed)
			{
				item.value.f1 = item.endValue.f1;
				item.value.f2 = item.endValue.f2;				
				parms.f1 = item.startValue.f1;
				parms.f2 = item.startValue.f2;
			}
			else
			{
				if (item.type == TransitionActionType.XY)
				{
					if (item.target == _owner)
					{
						if(!item.startValue.b1)
							item.startValue.f1 = 0;
						if(!item.startValue.b2)
							item.startValue.f2 = 0;
					}
					else
					{
						if(!item.startValue.b1)
							item.startValue.f1 = item.target.x;
						if(!item.startValue.b2)
							item.startValue.f2 = item.target.y;
					}
				}
				else
				{
					if(!item.startValue.b1)
						item.startValue.f1 = item.target.width;
					if(!item.startValue.b2)
						item.startValue.f2 = item.target.height;
				}
				
				item.value.f1 = item.startValue.f1;
				item.value.f2 = item.startValue.f2;
				
				if(!item.endValue.b1)
					item.endValue.f1 = item.value.f1;
				if(!item.endValue.b2)
					item.endValue.f2 = item.value.f2;
			
				parms.f1 = item.endValue.f1;
				parms.f2 = item.endValue.f2;
			}
			
			if (item.repeat != 0)
			{
				if(item.repeat==-1)
					parms.repeat = int.MAX_VALUE;
				else
					parms.repeat = item.repeat;
				parms.yoyo = item.yoyo;
			}
			
			applyValue(item, item.value);
			item.tweener = TweenMax.to(item.value, item.duration, parms);
			
			if (item.hook != null)
				item.hook();
		}
		
		private function __delayCall(item:TransitionItem):void
		{
			item.tweener = null;
			
			startTween(item);
		}
		
		private function __delayCall2(item:TransitionItem):void
		{
			item.tweener = null;
			_totalTasks--;
			item.completed = true;
			
			applyValue(item, item.value);
			if (item.hook != null)
				item.hook();
			
			checkAllComplete();
		}
		
		private function __tweenStart(item:TransitionItem):void
		{
			if (item.hook != null)
				item.hook();
		}        
		
		private function __tweenUpdate(item:TransitionItem):void
		{
			applyValue(item, item.value);
		}
		
		private function __tweenComplete(item:TransitionItem):void
		{
			item.tweener = null;
			_totalTasks--;
			item.completed = true;
			if (item.hook2 != null)
				item.hook2();
			
			checkAllComplete();
		}
		
		private function __playTransComplete(item:TransitionItem):void
		{
			_totalTasks--;
			item.completed = true;
			checkAllComplete();
		}
		
		private function checkAllComplete():void
		{
			if (_playing && _totalTasks == 0)
			{
				if (_totalTimes < 0)
				{
					internalPlay(0);
				}
				else
				{
					_totalTimes--;
					if (_totalTimes > 0)
						internalPlay(0);
					else
					{
						_playing = false;
						_owner.internalVisible--;
						var cnt:int = _items.length;
						
						if ((_options & OPTION_IGNORE_DISPLAY_CONTROLLER) != 0)
						{
							for (var i:int = 0; i < cnt; i++)
							{
								var item:TransitionItem = _items[i];
								if (item.target != null && item.target!=_owner)
									item.target.internalVisible--;
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
		
		private function applyValue(item:TransitionItem, value:TransitionValue):void
		{
			item.target._gearLocked = true;
			
			switch (item.type)
			{
				case TransitionActionType.XY:
					if(item.target==_owner)
					{
						var f1:Number, f2:Number;
						if (!value.b1)
							f1 = item.target.x;
						else
							f1 = value.f1+_ownerBaseX;
						if (!value.b2)
							f2 = item.target.y;
						else
							f2 = value.f2+_ownerBaseY;
						item.target.setXY(f1, f2);
					}
					else
					{
						if (!value.b1)
							value.f1 = item.target.x;
						if (!value.b2)
							value.f2 = item.target.y;
						item.target.setXY(value.f1, value.f2);
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
					item.target.setPivot(value.f1, value.f2);
					break;
				
				case TransitionActionType.Alpha:
					item.target.alpha = value.f1;
					break;
				
				case TransitionActionType.Rotation:
					item.target.rotation = value.i;
					break;
				
				case TransitionActionType.Scale: 
					item.target.setScale(value.f1, value.f2);
					break;
				
				case TransitionActionType.Color:
					IColorGear(item.target).color = value.c;
					break;
				
				case TransitionActionType.Animation:
					if (!value.b1)
						value.i = IAnimationGear(item.target).frame;
					IAnimationGear(item.target).frame = value.i;
					IAnimationGear(item.target).playing = value.b;
					break;
				
				case TransitionActionType.Visible:
					item.target.visible = value.b;
					break;
				
				case TransitionActionType.Controller:
					var arr:Array = value.s.split(",");
					for each(var str:String in arr)
					{
						var arr2:Array = str.split("=");
						var cc:Controller = GComponent(item.target).getController(arr2[0]);
						if(cc)
						{
							str = arr2[1];
							if(str.charAt(0)=="$")
							{
								str = str.substring(1);
								cc.selectedPage = str;
							}
							else
								cc.selectedIndex = parseInt(str);	
						}							
					}
					break;
				
				case TransitionActionType.Transition:
					var trans:Transition = GComponent(item.target).getTransition(value.s);
					if (trans != null)
					{
						if (value.i == 0)
							trans.stop(false, true);
						else if (trans.playing)
							trans._totalTimes = value.i==-1?int.MAX_VALUE:value.i;
						else
						{
							item.completed = false;
							_totalTasks++;
							if(_reversed)
								trans.playReverse(__playTransComplete, item, value.i);
							else
								trans.play(__playTransComplete, item, value.i);
						}
					}
					break;
				
				case TransitionActionType.Sound:
					var pi:PackageItem = UIPackage.getItemByURL(value.s);
					if(pi)
					{
						var sound:Sound = pi.owner.getSound(pi);
						if(sound)
							GRoot.inst.playOneShotSound(sound, value.f1);
					}
					break;
				
				case TransitionActionType.Shake:
					item.startValue.f1 = 0; //offsetX
					item.startValue.f2 = 0; //offsetY
					item.startValue.f3 = item.value.f2;//shakePeriod
					item.startValue.i = getTimer(); //startTime
					GTimers.inst.add(1, 0, item.__shake, this.shakeItem);
					_totalTasks++;
					item.completed = false;
					break;
			}
			
			item.target._gearLocked = false;
		}
		
		private function shakeItem(item:TransitionItem):void
		{
			var r:Number = Math.ceil(item.value.f1 * item.startValue.f3 / item.value.f2);
			var rx:Number = (Math.random()*2-1)*r;
			var ry:Number = (Math.random()*2-1)*r;
			rx = rx > 0 ? Math.ceil(rx) : Math.floor(rx);
			ry = ry > 0 ? Math.ceil(ry) : Math.floor(ry);
			
			item.target._gearLocked = true;
			item.target.setXY(item.target.x-item.startValue.f1+rx, item.target.y-item.startValue.f2+ry);
			item.target._gearLocked = false;
			
			item.startValue.f1 = rx;
			item.startValue.f2 = ry;

			var t:int = getTimer();
			item.startValue.f3 -= (t-item.startValue.i)/1000;
			item.startValue.i = t;
			if(item.startValue.f3<=0)
			{
				item.target._gearLocked = true;
				item.target.setXY(item.target.x-item.startValue.f1, item.target.y-item.startValue.f2);
				item.target._gearLocked = false;
				
				item.completed = true;
				_totalTasks--;
				GTimers.inst.remove(item.__shake);
				
				checkAllComplete();
			}
		}
		
		public function setup(xml:XML):void
		{
			this.name = xml.@name;
			var str:String = xml.@options;
			if(str)
				_options = parseInt(str); 
			var col:XMLList = xml.item;
			for each (var cxml:XML in col)
			{
				var item:TransitionItem = new TransitionItem();
				_items.push(item);
				
				item.time = parseInt(cxml.@time) / FRAME_RATE;
				item.targetId = cxml.@target;
				str = cxml.@type;
				switch(str)
				{
					case "XY":
						item.type = TransitionActionType.XY;
						break;
					case "Size":
						item.type = TransitionActionType.Size;
						break;
					case "Scale":
						item.type = TransitionActionType.Scale;
						break;
					case "Pivot":
						item.type = TransitionActionType.Pivot;
						break;
					case "Alpha":
						item.type = TransitionActionType.Alpha;
						break;
					case "Rotation":
						item.type = TransitionActionType.Rotation;
						break;
					case "Color":
						item.type = TransitionActionType.Color;
						break;
					case "Animation":
						item.type = TransitionActionType.Animation;
						break;
					case "Visible":
						item.type = TransitionActionType.Visible;
						break;
					case "Controller":
						item.type = TransitionActionType.Controller;
						break;
					case "Sound":
						item.type = TransitionActionType.Sound;
						break;
					case "Transition":
						item.type = TransitionActionType.Transition;
						break;
					case "Shake":
						item.type = TransitionActionType.Shake;
						break;
					default:
						item.type = TransitionActionType.Unknown;
						break;
				}
				item.tween = cxml.@tween=="true";
				item.label = cxml.@label;
				if(item.label.length==0)
					item.label = null;

				if (item.tween)
				{
					item.duration = parseInt(cxml.@duration) / FRAME_RATE;
					if(item.time+item.duration>_maxTime)
						_maxTime = item.time+item.duration;
					
					str = cxml.@ease;
					if (str)
					{
						var pos:int = str.indexOf(".");
						if(pos!=-1)
							str = str.substr(0,pos) + ".ease" + str.substr(pos+1);
						if(str=="Linear")
							item.easeType = EaseLookup.find("linear.easenone");
						else
							item.easeType = EaseLookup.find(str);
					}
					
					item.repeat = parseInt(cxml.@repeat);
					item.yoyo = cxml.@yoyo=="true";
					item.label2 = cxml.@label2;
					if(item.label2.length==0)
						item.label2 = null;
					
					var v:String = cxml.@endValue;
					if (v)
					{
						decodeValue(item.type, cxml.@startValue, item.startValue);
						decodeValue(item.type, v, item.endValue);
					}
					else
					{
						item.tween = false;
						decodeValue(item.type, cxml.@startValue, item.value);
					}
				}
				else
				{
					if(item.time>_maxTime)
						_maxTime = item.time;
					decodeValue(item.type, cxml.@value, item.value);
				}
			}
		}
		
		private function decodeValue(type:int, str:String, value:TransitionValue):void
		{
			var arr:Array;
			switch(type)
			{
				case TransitionActionType.XY:
				case TransitionActionType.Size:
				case TransitionActionType.Pivot:
					arr = str.split(",");
					if (arr[0] == "-")
					{
						value.b1 = false;
					}
					else
					{
						value.f1 = parseInt(arr[0]);
						value.b1 = true;
					}
					if(arr[1]=="-")
					{
						value.b2 = false;
					}
					else
					{
						value.f2 = parseInt(arr[1]);
						value.b2 = true;
					}
					break;
				
				case TransitionActionType.Alpha:
					value.f1 = parseFloat(str);
					break;
				
				case TransitionActionType.Rotation:
					value.i = parseInt(str);
					break;
				
				case TransitionActionType.Scale:
					arr = str.split(",");
					value.f1 = parseFloat(arr[0]);
					value.f2 = parseFloat(arr[1]);
					break;
				
				case TransitionActionType.Color:
					value.c = ToolSet.convertFromHtmlColor(str);
					break;
				
				case TransitionActionType.Animation:
					arr = str.split(",");
					if(arr[0]=="-")
					{
						value.b1 = false;
					}
					else
					{
						value.i = parseInt(arr[0]);
						value.b1 = true;
					}
					value.b = arr[1]=="p";
					break;
				
				case TransitionActionType.Visible:
					value.b = str=="true";
					break;
				
				case TransitionActionType.Controller:
					value.s = str;
					break;
				
				case TransitionActionType.Sound:
					arr = str.split(",");
					value.s = arr[0];
					if(arr.length>1)
					{
						var intv:int = parseInt(arr[1]);
						if(intv==0 || intv==100)
							value.f1 = 1;
						else
							value.f1 = intv/100;
					}
					else
						value.f1 = 1;
					break;
				
				case TransitionActionType.Transition:
					arr = str.split(",");
					value.s = arr[0];
					if (arr.length > 1)
						value.i = parseInt(arr[1]);
					else
						value.i = 1;
					break;
				
				case TransitionActionType.Shake:
					arr = str.split(",");
					value.f1 = parseFloat(arr[0]);
					value.f2 = parseFloat(arr[1]);
					break;
			}
		}
	}
}

import com.greensock.TweenLite;
import com.greensock.easing.Ease;
import com.greensock.easing.Quad;

import fairygui.GObject;

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
	public static const Controller:int=9;
	public static const Sound:int=10;
	public static const Transition:int=11;
	public static const Shake:int = 12;
	public static const Unknown:int = 13;
}

class TransitionItem
{
	public var time:Number;
	public var targetId:String;
	public var type:int;
	public var duration:Number;
	public var value:TransitionValue;
	public var startValue:TransitionValue;
	public var endValue:TransitionValue;
	public var easeType:Ease;
	public var repeat:int;
	public var yoyo:Boolean;
	public var tween:Boolean;
	public var label:String;
	public var label2:String;
	public var hook:Function;
	public var hook2:Function;
	public var tweener:TweenLite;
	public var completed:Boolean;
	public var target:GObject;
	
	public var params:Array;
	public function TransitionItem()
	{
		easeType = Quad.easeOut;
		value = new TransitionValue();
		startValue = new TransitionValue();
		endValue = new TransitionValue();
		params = [this];
	}
	
	public function __shake(param:Object):void
	{
		param(this);
	}
}

class TransitionValue
{
	public var f1:Number;//x, scalex, pivotx,alpha,shakeAmplitude
	public var f2:Number;//y, scaley, pivoty, shakePeriod
	public var f3:Number;
	public var i:int;//rotation,frame
	public var c:uint;//color
	public var b:Boolean;//playing
	public var s:String;//sound,transName
	
	public var b1:Boolean = true;
	public var b2:Boolean = true;
}

