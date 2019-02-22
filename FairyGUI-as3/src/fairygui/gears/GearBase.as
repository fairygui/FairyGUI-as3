package fairygui.gears
{
	import fairygui.tween.EaseType;
	import fairygui.Controller;
	import fairygui.GObject;

	public class GearBase
	{
		public static var disableAllTweenEffect:Boolean = false;

		protected var _owner:GObject;
		protected var _controller:Controller;
		protected var _tweenConfig:GearTweenConfig;
		
		public function GearBase(owner:GObject)
		{
			_owner = owner;
		}
		
		public function dispose():void
		{
			if (_tweenConfig != null && _tweenConfig._tweener != null)
			{
				_tweenConfig._tweener.kill();
				_tweenConfig._tweener = null;
			}
		}

		final public function get controller():Controller
		{
			return _controller;
		}
		
		public function set controller(val:Controller):void
		{
			if(val!=_controller)
			{
				_controller = val;
				if(_controller)
					init();
			}
		}
		
		public function get tweenConfig():GearTweenConfig
		{
			if (_tweenConfig == null)
				_tweenConfig = new GearTweenConfig();
			return _tweenConfig;
		}
		
		public function setup(xml:XML):void
		{
			_controller = _owner.parent.getController(xml.@controller);
			if(!_controller)
				return;
			
			init();
			
			var str:String;

			str = xml.@tween;
			if(str)
			{
				_tweenConfig = new GearTweenConfig();
				str = xml.@ease;
				if(str)
					_tweenConfig.easeType = EaseType.parseEaseType(str);
				str = xml.@duration;
				if(str)
					_tweenConfig.duration = parseFloat(str);
				str = xml.@delay;
				if(str)
					_tweenConfig.delay = parseFloat(str);
			}
			
			if(this is GearDisplay)
			{
				str = xml.@pages;
				if(str)
				{
					var arr:Array = str.split(",");
					GearDisplay(this).pages = arr;
				}
			}
			else
			{
				var pages:Array;
				var values:Array;
				
				str = xml.@pages;
				if(str)
					pages = str.split(",");
				
				if(pages)
				{
					str = xml.@values;
					values = str.split("|");
					
					for(var i:int=0;i<pages.length;i++)
					{
						str = values[i];
						if(str==null)
							str = "";
						addStatus(pages[i], str);
					}
				}
				
				str = xml.@["default"];
				if(str)
					addStatus(null, str);
			}	
		}
		
		public function updateFromRelations(dx:Number, dy:Number):void
		{
		}
		
		protected function addStatus(pageId:String, value:String):void
		{
			
		}
		
		protected function init():void
		{
			
		}
		
		public function apply():void
		{
		}
		
		public function updateState():void
		{
		}
	}
}