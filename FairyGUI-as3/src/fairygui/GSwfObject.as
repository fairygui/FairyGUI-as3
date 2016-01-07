package fairygui
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import fairygui.display.UISprite;
	
	public class GSwfObject extends GObject implements IAnimationGear
	{
		protected var _container:Sprite;
		protected var _content:DisplayObject;
		protected var _playing:Boolean;
		protected var _frame:int;
		protected var _gearAnimation:GearAnimation;
		
		public function GSwfObject()
		{
			_playing = true;
			
			_gearAnimation = new GearAnimation(this);
		}
		
		override protected function createDisplayObject():void
		{
			_container = new UISprite(this);
			setDisplayObject(_container);
		}
		
		final public function get movieClip():MovieClip
		{
			return MovieClip(_content);
		}
		
		final public function get playing():Boolean
		{
			return _playing;
		}
		
		public function set playing(value:Boolean):void
		{
			if(_playing!=value)
			{
				_playing = value;
				if(_content && (_content is MovieClip))
				{
					if(_playing)
						MovieClip(_content).gotoAndPlay(_frame+1);
					else
						MovieClip(_content).gotoAndStop(_frame+1);
				}
				if(_gearAnimation.controller)
					_gearAnimation.updateState();
			}
		}
		
		final public function get frame():int
		{
			return _frame;
		}
		
		public function set frame(value:int):void
		{
			if(_frame!=value)
			{
				_frame = value;
				if(_content && (_content is MovieClip))
				{
					if(_playing)
						MovieClip(_content).gotoAndPlay(_frame+1);
					else
						MovieClip(_content).gotoAndStop(_frame+1);
				}
				if(_gearAnimation.controller)
					_gearAnimation.updateState();
			}
		}
		
		final public function get gearAnimation():GearAnimation
		{
			return _gearAnimation;
		}
		
		override public function dispose():void
		{
			_packageItem.owner.removeItemCallback(_packageItem, __swfLoaded);
			super.dispose();
		}

		override protected function handleSizeChanged():void
		{
			if(_content)
			{
				_container.scaleX = this.width/_sourceWidth*this.scaleX;
				_container.scaleY = this.height/_sourceHeight*this.scaleY;
			}
		}

		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			if(_gearAnimation.controller==c)
				_gearAnimation.apply();
		}
		
		override public function constructFromResource(pkgItem:PackageItem):void
		{
			_packageItem = pkgItem;
			
			_sourceWidth = _packageItem.width;
			_sourceHeight = _packageItem.height;
			_initWidth = _sourceWidth;
			_initHeight = _sourceHeight;
			
			setSize(_sourceWidth, _sourceHeight);
			
			_packageItem.owner.addItemCallback(_packageItem, __swfLoaded);
		}
		
		private function __swfLoaded(content:Object):void
		{
			if(_content)
				_container.removeChild(_content);
			_content = DisplayObject(content);
			if(_content)
			{
				try
				{
					_container.addChild(_content);
				}
				catch(e:Error)
				{
					trace("__swfLoaded:"+e);
					_content = null;
				}
			}
			
			if(_content && (_content is MovieClip))
			{
				if(_playing)
					MovieClip(_content).gotoAndPlay(_frame+1);
				else
					MovieClip(_content).gotoAndStop(_frame+1);
			}
			
			handleSizeChanged();
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String = xml.@playing;
			_playing =  str!= "false";
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			var cxml:XML = xml.gearAni[0];
			if(cxml)
				_gearAnimation.setup(cxml);
		}
	}
}