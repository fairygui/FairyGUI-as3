package fairygui
{
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	import fairygui.display.UIMovieClip;
	import fairygui.utils.ToolSet;
	
	public class GMovieClip extends GObject
	{	
		private var _movieClip:UIMovieClip;
		private var _color:uint;
		
		public function GMovieClip()
		{
			_color = 0xFFFFFF;
		}
		
		override protected function createDisplayObject():void
		{
			_movieClip = new UIMovieClip(this);
			_movieClip.mouseEnabled = false;
			_movieClip.mouseChildren = false;
			setDisplayObject(_movieClip);
		}
		
		final public function get playing():Boolean
		{
			return _movieClip.playing;
		}
		
		final public function set playing(value:Boolean):void
		{
			if(_movieClip.playing!=value)
			{
				_movieClip.playing = value;
				updateGear(5);
			}
		}
		
		final public function get frame():int
		{
			return _movieClip.frame;
		}
		
		public function set frame(value:int):void
		{
			if(_movieClip.frame!=value)
			{
				_movieClip.frame = value;
				updateGear(5);
			}
		}
		
		final public function get timeScale():Number
		{
			return _movieClip.timeScale;
		}
		
		public function set timeScale(value:Number):void
		{
			_movieClip.timeScale = value;
		}
		
		public function rewind():void
		{
			_movieClip.rewind();
		}
		
		public function syncStatus(anotherMc:GMovieClip):void
		{
			_movieClip.syncStatus(anotherMc._movieClip);
		}
		
		public function advance(timeInMiniseconds:int):void
		{
			_movieClip.advance(timeInMiniseconds);
		}
		
		//从start帧开始，播放到end帧（-1表示结尾），重复times次（0表示无限循环），循环结束后，停止在endAt帧（-1表示参数end）
		public function setPlaySettings(start:int = 0, end:int = -1, 
										times:int = 0, endAt:int = -1, 
										endCallback:Function = null):void
		{
			_movieClip.setPlaySettings(start, end, times, endAt, endCallback);	
		}
		
		public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void
		{
			if(_color != value)
			{
				_color = value;
				updateGear(4);
				applyColor();
			}
		}
		
		private function applyColor():void
		{
			var ct:ColorTransform = _movieClip.transform.colorTransform;
			ct.redMultiplier = ((_color>>16)&0xFF)/255;
			ct.greenMultiplier =  ((_color>>8)&0xFF)/255;
			ct.blueMultiplier = (_color&0xFF)/255;
			_movieClip.transform.colorTransform = ct;
		}
		
		public override function dispose():void
		{
			super.dispose();
		}

		override public function constructFromResource():void
		{
			var displayItem:PackageItem = packageItem.getBranch();

			sourceWidth = displayItem.width;
			sourceHeight = displayItem.height;
			initWidth = sourceWidth;
			initHeight = sourceHeight;

			setSize(sourceWidth, sourceHeight);

			displayItem = displayItem.getHighResolution();
			if(displayItem.loaded)
				__movieClipLoaded(displayItem);
			else
				displayItem.owner.addItemCallback(displayItem, __movieClipLoaded);
		}
		
		private function __movieClipLoaded(pi:PackageItem):void
		{
			_movieClip.interval = pi.interval;
			_movieClip.swing = pi.swing;
			_movieClip.repeatDelay = pi.repeatDelay;
			_movieClip.frames = pi.frames;
			_movieClip.boundsRect = new Rectangle(0, 0, sourceWidth, sourceHeight);
			_movieClip.smoothing = pi.smoothing;

			handleSizeChanged();
		}

		override protected function handleSizeChanged():void
		{
			handleScaleChanged();
		}
		
		override protected function handleScaleChanged():void
		{
			if(_movieClip.boundsRect)
			{
				_displayObject.scaleX = _width/_movieClip.boundsRect.width*_scaleX;
				_displayObject.scaleY = _height/_movieClip.boundsRect.height*_scaleY;
			}
			else
			{
				_displayObject.scaleX = _scaleX;
				_displayObject.scaleY = _scaleY;
			}
		}

		override public function getProp(index:int):*
		{
			switch(index)
			{
				case ObjectPropID.Color:
					return this.color;
				case ObjectPropID.Playing:
					return this.playing;
				case ObjectPropID.Frame:
					return this.frame;
				case ObjectPropID.TimeScale:
					return this.timeScale;
				default:
					return super.getProp(index);
			}
		}

		override public function setProp(index:int, value:*):void
		{
			switch(index)
			{
				case ObjectPropID.Color:
					this.color = value;
					break;
				case ObjectPropID.Playing:
					this.playing = value;
					break;
				case ObjectPropID.Frame:
					this.frame = value;
					break;
				case ObjectPropID.TimeScale:
					this.timeScale = value;
					break;
				case ObjectPropID.DeltaTime:
					this.advance(value);
					break;
				default:
					super.setProp(index, value);
					break;
			}
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String;
			str = xml.@frame;
			if(str)
				_movieClip.frame = parseInt(str);
			str = xml.@playing;
			_movieClip.playing = str!= "false";
			str = xml.@color;
			if(str)
				this.color = ToolSet.convertFromHtmlColor(str);
		}
	}
}