package fairygui
{
	import com.greensock.easing.Ease;
	import com.greensock.easing.EaseLookup;
	import com.greensock.easing.Quad;
	
	public class GearBase
	{
		protected var _pageSet:PageOptionSet;
		protected var _tween:Boolean;
		protected var _easeType:Ease;
		protected var _tweenTime:Number;
		
		protected var _owner:GObject;
		protected var _controller:Controller;
		
		public function GearBase(owner:GObject)
		{
			_owner = owner;
			_pageSet = new PageOptionSet();
			_easeType = Quad.easeOut;
			_tweenTime = 0.3;
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
				_pageSet.controller = val;
				_pageSet.clear();
				if(_controller)
					init();
			}
		}
		
		final public function getPageSet():PageOptionSet
		{
			return _pageSet;
		}
		
		final public function get tween():Boolean
		{
			return _tween;
		}
		
		public function set tween(val:Boolean):void
		{
			_tween = val;
		}
		
		final public function get tweenTime():Number
		{
			return _tweenTime;
		}
		
		public function set tweenTime(value:Number):void
		{
			_tweenTime = value;
		}
		
		final public function get easeType():Ease
		{
			return _easeType;
		}
		
		public function set easeType(value:Ease):void
		{
			_easeType = value;
		}
		
		public function setup(xml:XML):void
		{
			_controller = _owner.parent.getController(xml.@controller);
			if(!_controller)
				return;
			
			init();
			
			var str:String;
			str = xml.@pages;
			var pages:Array;
			if(str)
				pages = str.split(",");
			else
				pages = [];
			for each(str in pages)
				_pageSet.addById(str);

			str = xml.@tween;
			if(str)
				_tween = true;
			
			str = xml.@ease;
			if(str)
			{
				var pos:int = str.indexOf(".");
				if(pos!=-1)
					str = str.substr(0,pos) + ".ease" + str.substr(pos+1);
				if(str=="Linear")
					_easeType = EaseLookup.find("linear.easenone");
				else
					_easeType = EaseLookup.find(str);
			}
			
			str = xml.@duration;
			if(str)
				_tweenTime = parseFloat(str);
			
			str = xml.@values;
			var values:Array;
			if(str)
				values = xml.@values.split("|");
			else
				values = [];

			for(var i:int=0;i<values.length;i++)
			{
				str = values[i];
				if(str!="-")
					addStatus(pages[i], str);
			}
			str = xml.@["default"];
			if(str)
				addStatus(null, str);
		}

		protected function get connected():Boolean
		{
			if(_controller && !_pageSet.empty)
				return _pageSet.containsId(_controller.selectedPageId);
			else
				return false;
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