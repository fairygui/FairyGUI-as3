package fairygui
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.Sound;
	
	import fairygui.event.GTouchEvent;
	import fairygui.event.StateChangeEvent;
	import fairygui.utils.GTimers;
	import fairygui.utils.ToolSet;
	
	[Event(name = "stateChanged", type = "fairygui.event.StateChangeEvent")]
	public class GButton extends GComponent
	{
		protected var _titleObject:GObject;
		protected var _iconObject:GObject;
		protected var _relatedController:Controller;
		
		private var _mode:int;
		private var _selected:Boolean;
		private var _title:String;
		private var _selectedTitle:String;
		private var _icon:String;
		private var _selectedIcon:String;
		private var _sound:String;
		private var _soundVolumeScale:Number;
		private var _pageOption:PageOption;
		private var _buttonController:Controller;
		private var _changeStateOnClick:Boolean;
		private var _linkedPopup:GObject;
		private var _hasDisabledPage:Boolean;

		private var _over:Boolean;
		
		public static const UP:String = "up";
		public static const DOWN:String = "down";
		public static const OVER:String = "over";
		public static const SELECTED_OVER:String = "selectedOver";
		public static const DISABLED:String = "disabled";
		public static const SELECTED_DISABLED:String = "selectedDisabled";
		
		public function GButton()
		{
			super();
			
			_mode = ButtonMode.Common;
			_title = "";
			_icon = "";
			_sound = UIConfig.buttonSound;
			_soundVolumeScale = UIConfig.buttonSoundVolumeScale;
			_pageOption = new PageOption();
			_changeStateOnClick = true;
		}

		final public function get icon():String
		{
			return _icon;
		}

		public function set icon(value:String):void
		{
			_icon = value;
			value = (_selected && _selectedIcon)?_selectedIcon:_icon;
			if(_iconObject is GLoader)
				GLoader(_iconObject).url = value;
			else if(_iconObject is GLabel)
				GLabel(_iconObject).icon = value;
			else if(_iconObject is GButton)
				GButton(_iconObject).icon = value;
		}
		
		final public function get selectedIcon():String
		{
			return _selectedIcon;
		}
		
		public function set selectedIcon(value:String):void
		{
			_selectedIcon = value;
			value = (_selected && _selectedIcon)?_selectedIcon:_icon;
			if(_iconObject is GLoader)
				GLoader(_iconObject).url = value;
			else if(_iconObject is GLabel)
				GLabel(_iconObject).icon = value;
			else if(_iconObject is GButton)
				GButton(_iconObject).icon = value;
		}

		final public function get title():String
		{
			return _title;
		}

		public function set title(value:String):void
		{
			_title = value;
			if(_titleObject)
				_titleObject.text = (_selected && _selectedTitle)?_selectedTitle:_title;
		}
		
		final override public function get text():String
		{
			return this.title;
		}
		
		override public function set text(value:String):void
		{
			this.title = value;
		}
		
		final public function get selectedTitle():String
		{
			return _selectedTitle;
		}
		
		public function set selectedTitle(value:String):void
		{
			_selectedTitle = value;
			if(_titleObject)
				_titleObject.text = (_selected && _selectedTitle)?_selectedTitle:_title;
		}
		
		final public function get titleColor():uint
		{
			if(_titleObject is GTextField)
				return GTextField(_titleObject).color;
			else if(_titleObject is GLabel)
				return GLabel(_titleObject).titleColor;
			else if(_titleObject is GButton)
				return GButton(_titleObject).titleColor;
			else
				return 0;
		}
		
		public function set titleColor(value:uint):void
		{
			if(_titleObject is GTextField)
				GTextField(_titleObject).color = value;
			else if(_titleObject is GLabel)
				GLabel(_titleObject).titleColor = value;
			else if(_titleObject is GButton)
				GButton(_titleObject).titleColor = value;
		}
		
		final public function get sound():String
		{
			return _sound;
		}
		
		public function set sound(val:String):void
		{
			_sound = val;
		}
		
		public function get soundVolumeScale():Number
		{
			return _soundVolumeScale;
		}
		
		public function set soundVolumeScale(value:Number):void
		{
			_soundVolumeScale = value;
		}

		public function set selected(val:Boolean):void
		{
			if(_mode==ButtonMode.Common)
				return;
			
			if(_selected!=val)
			{
				_selected = val;
				if(this.grayed && _buttonController && _buttonController.hasPage(DISABLED))
				{
					if(_selected)
						setState(SELECTED_DISABLED);
					else
						setState(DISABLED);
				}
				else
				{
					if(_selected)
						setState(_over?SELECTED_OVER:DOWN);
					else
						setState(_over?OVER:UP);
				}
				if(_selectedTitle && _titleObject)
					_titleObject.text = _selected?_selectedTitle:_title;
				if(_selectedIcon)
				{
					var str:String = _selected?_selectedIcon:_icon;
					if(_iconObject is GLoader)
						GLoader(_iconObject).url = str;
					else if(_iconObject is GLabel)
						GLabel(_iconObject).icon = str;
					else if(_iconObject is GButton)
						GButton(_iconObject).icon = str;
				}
				if(_relatedController
					&& _parent
					&& !_parent._buildingDisplayList)
				{
					if(_selected)
					{
						_relatedController.selectedPageId = _pageOption.id;
						if(_relatedController._autoRadioGroupDepth)
							_parent.adjustRadioGroupDepth(this, _relatedController);
					}
					else if(_mode==ButtonMode.Check && _relatedController.selectedPageId==_pageOption.id)
						_relatedController.oppositePageId = _pageOption.id;
				}
			}
		}
		
		final public function get selected():Boolean
		{
			return _selected;
		}
		
		final public function get mode():int
		{
			return _mode;
		}
		
		public function set mode(value:int):void
		{
			if(_mode!=value)
			{
				if(value==ButtonMode.Common)
					this.selected = false;
				_mode = value;
			}
		}

		final public function get relatedController():Controller
		{
			return _relatedController;
		}
		
		public function set relatedController(val:Controller):void
		{
			if(val!=_relatedController)
			{
				_relatedController = val;
				_pageOption.controller = val;
				_pageOption.clear();
			}
		}
		
		final public function get pageOption():PageOption
		{
			return _pageOption;
		}
		
		final public function get changeStateOnClick():Boolean
		{
			return _changeStateOnClick;
		}
		
		final public function set changeStateOnClick(value:Boolean):void
		{
			_changeStateOnClick = value;
		}
		
		final public function get linkedPopup():GObject
		{
			return _linkedPopup;
		}
		
		final public function set linkedPopup(value:GObject):void
		{
			_linkedPopup = value;
		}
		
		public function addStateListener(listener:Function):void
		{
			addEventListener(StateChangeEvent.CHANGED, listener);
		}
		
		public function removeStateListener(listener:Function):void
		{
			removeEventListener(StateChangeEvent.CHANGED, listener);
		}
		
		public function fireClick(downEffect:Boolean=true):void
		{
			if(downEffect && _mode==ButtonMode.Common)
			{
				setState(OVER);
				GTimers.inst.add(100, 1, setState, DOWN);
				GTimers.inst.add(200, 1, setState, UP);
			}
			__click(null);
		}
		
		protected function setState(val:String):void
		{
			if(_buttonController)
			{
				_buttonController.selectedPage = val;
			}
		}
		
		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			
			if(_relatedController==c)
				this.selected = _pageOption.id==c.selectedPageId;
		}
		
		override protected function handleGrayChanged():void
		{
			if(_buttonController && _buttonController.hasPage(DISABLED))
			{
				if(this.grayed) {
					if(_selected)
						setState(SELECTED_DISABLED);
					else
						setState(DISABLED);
				}
				else
				{
					if(_selected)
						setState(DOWN);
					else
						setState(UP);
				}
			}
			else
				super.handleGrayChanged();
		}
		
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			
			xml = xml.Button[0];
			
			var str:String;
			str = xml.@mode;
			if(str)
				_mode = ButtonMode.parse(str);
			
			_sound = xml.@sound;
			str = xml.@volume;
			if(str)
				_soundVolumeScale = parseInt(str)/100;
			
			_buttonController = getController("button");
			_titleObject = getChild("title");
			_iconObject = getChild("icon");
						
			if(_mode==ButtonMode.Common)
				setState(UP);
			
			this.opaque = true;	
			if(!GRoot.touchScreen)
			{
				displayObject.addEventListener(MouseEvent.ROLL_OVER, __rollover);
				displayObject.addEventListener(MouseEvent.ROLL_OUT, __rollout);
			}
			this.addEventListener(GTouchEvent.BEGIN, __mousedown);
			this.addEventListener(GTouchEvent.END, __mouseup);
			this.addEventListener(GTouchEvent.CLICK, __click, false, 1000);
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			xml = xml.Button[0];
			if(xml)
			{
				var str:String;
				this.title = xml.@title;
				this.icon = xml.@icon;
				str = xml.@selectedTitle;
				if(str)
					this.selectedTitle = str;
				str = xml.@selectedIcon;;
				if(str)
					this.selectedIcon = str;
				
				str = xml.@titleColor;
				if(str)
					this.titleColor = ToolSet.convertFromHtmlColor(str);
				
				if(xml.@sound!=undefined)
					_sound = xml.@sound;
				str = xml.@volume;
				if(str)
					_soundVolumeScale = parseInt(str)/100;
				
				str = xml.@controller;
				if(str)
					_relatedController = _parent.getController(xml.@controller);
				else
					_relatedController = null;
				_pageOption.id = xml.@page;
				this.selected = xml.@checked=="true";
			}
		}
		
		private function __rollover(evt:Event):void
		{
			if(!_buttonController || !_buttonController.hasPage(OVER))
				return;
			
			_over = true;
			if(this.isDown)
				return;
			
			if(this.grayed && _buttonController.hasPage(DISABLED))
				return;
			
			setState(_selected?SELECTED_OVER:OVER);
		}
		
		private function __rollout(evt:Event):void
		{
			if(!_buttonController || !_buttonController.hasPage(OVER))
				return;
			
			_over = false;
			if(this.isDown)
				return;
			
			if(this.grayed && _buttonController.hasPage(DISABLED))
				return;

			setState(_selected?DOWN:UP);
		}
		
		private function __mousedown(evt:Event):void
		{
			if(_mode==ButtonMode.Common)
			{
				if(this.grayed && _buttonController && _buttonController.hasPage(DISABLED))
					setState(SELECTED_DISABLED);
				else
					setState(DOWN);
			}
			
			if(_linkedPopup!=null)
			{
				if(_linkedPopup is Window)
					Window(_linkedPopup).toggleStatus();
				else
					this.root.togglePopup(_linkedPopup, this);
			}
		}
		
		private function __mouseup(evt:Event):void
		{
			if(_mode==ButtonMode.Common)
			{
				if(this.grayed && _buttonController && _buttonController.hasPage(DISABLED))
					setState(DISABLED);
				else if (_over)
					setState(OVER);
				else
					setState(UP);
			}
		}
		
		private function __click(evt:Event):void
		{
			if(_sound)
			{
				var pi:PackageItem = UIPackage.getItemByURL(_sound);
				if(pi)
				{
					var sound:Sound = pi.owner.getSound(pi);
					if(sound)
						GRoot.inst.playOneShotSound(sound, _soundVolumeScale);
				}
			}
			
			if(!_changeStateOnClick)
				return;
			
			if(_mode==ButtonMode.Check)
			{
				this.selected = !_selected;
				dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
			}
			else if(_mode==ButtonMode.Radio)
			{
				if(!_selected)
				{
					this.selected = true;
					dispatchEvent(new StateChangeEvent(StateChangeEvent.CHANGED));
				}
			}
		}
	}
}