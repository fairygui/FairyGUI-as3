package fairygui
{
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	import fairygui.display.UIMovieClip;
	import fairygui.utils.ToolSet;
	
	public class GMovieClip extends GObject implements IAnimationGear, IColorGear
	{	
		private var _gearAnimation:GearAnimation;
		private var _gearColor:GearColor;
		
		private var _movieClip:UIMovieClip;
		private var _color:uint;
		
		public function GMovieClip()
		{
			_gearAnimation = new GearAnimation(this);
			_gearColor = new GearColor(this);
			
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
				if(_gearAnimation.controller)
					_gearAnimation.updateState();
			}
		}
		
		final public function get frame():int
		{
			return _movieClip.currentFrame;
		}
		
		public function set frame(value:int):void
		{
			if(_movieClip.currentFrame!=value)
			{
				_movieClip.currentFrame = value;
				if(_gearAnimation.controller)
					_gearAnimation.updateState();
			}
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
				if (_gearColor.controller != null)
					_gearColor.updateState();
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
		
		final public function get gearAnimation():GearAnimation
		{
			return _gearAnimation;
		}
		
		final public function get gearColor():GearColor
		{
			return _gearColor;
		}
		
		public override function dispose():void
		{
			super.dispose();
		}
		
		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			if(_gearAnimation.controller==c)
				_gearAnimation.apply();
			if(_gearColor.controller==c)
				_gearColor.apply();
		}
		
		override protected function handleSizeChanged():void
		{
			displayObject.scaleX = this.width/_sourceWidth*this.scaleX*GRoot.contentScaleFactor;
			displayObject.scaleY = this.height/_sourceHeight*this.scaleY*GRoot.contentScaleFactor;
		}
		
		override public function constructFromResource(pkgItem:PackageItem):void
		{
			_packageItem = pkgItem;
			
			_sourceWidth = _packageItem.width;
			_sourceHeight = _packageItem.height;
			_initWidth = _sourceWidth;
			_initHeight = _sourceHeight;

			setSize(_sourceWidth, _sourceHeight);
			
			if(_packageItem.loaded)
				__movieClipLoaded(_packageItem);
			else
				_packageItem.owner.addItemCallback(_packageItem, __movieClipLoaded);
		}
		
		private function __movieClipLoaded(pi:PackageItem):void
		{
			_movieClip.interval = _packageItem.interval;
			_movieClip.frames = _packageItem.frames;
			_movieClip.boundsRect = new Rectangle(0, 0, sourceWidth, sourceHeight);
		}

		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String;
			str = xml.@frame;
			if(str)
				_movieClip.currentFrame = parseInt(str);
			str = xml.@playing;
			_movieClip.playing = str!= "false";
			str = xml.@color;
			if(str)
				this.color = ToolSet.convertFromHtmlColor(str);
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			var cxml:XML = xml.gearAni[0];
			if(cxml)
				_gearAnimation.setup(cxml);
			cxml = xml.gearColor[0];
			if(cxml)
				_gearColor.setup(cxml);
		}
	}
}