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
		
		private static var Classes:Array = null;

		private static const NameToIndex:Object = {
			"gearDisplay":0,
			"gearXY":1,
			"gearSize":2,
			"gearLook":3,
			"gearColor":4,
			"gearAni":5,
			"gearText":6,
			"gearIcon":7,
			"gearDisplay2":8,
			"gearFontSize":9
		};

		public static function create(owner: GObject, index: int): GearBase {
			if(!Classes)
			 Classes = [
					GearDisplay, GearXY, GearSize, GearLook, GearColor,
					GearAnimation, GearText, GearIcon, GearDisplay2, GearFontSize
				];
			return new GearBase.Classes[index](owner);
		}

		public static function getIndexByName(name:String):int {
			var index:* = NameToIndex[name];
			if(index==undefined)
				return -1;
			else
				return int(index);
		}

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
			
			var pages:Array;
			var values:Array;
			
			str = xml.@pages;
			if(str)
				pages = str.split(",");
				
			if(this is GearDisplay)
				GearDisplay(this).pages = pages;
			else if(this is GearDisplay2)
			{
				GearDisplay2(this).pages = pages;
				GearDisplay2(this).condition = xml.@condition;
			}
			else
			{
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