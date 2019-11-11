package fairygui
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	
	import fairygui.event.ItemEvent;
	import fairygui.utils.GTimers;

	public class PopupMenu
	{
		protected var _contentPane:GComponent;
		protected var _list:GList;
		protected var _expandingItem:GObject;
		
		private var _parentMenu:PopupMenu;
		
		public var visibleItemCount:int = int.MAX_VALUE;
		public var hideOnClickItem:Boolean = true;
		
		public function PopupMenu(resourceURL:String=null)
		{
			if(!resourceURL)
			{
				resourceURL = UIConfig.popupMenu;
				if(!resourceURL)
					throw new Error("UIConfig.popupMenu not defined");
			}
			
			_contentPane = GComponent(UIPackage.createObjectFromURL(resourceURL));
			_contentPane.addEventListener(Event.ADDED_TO_STAGE, __addedToStage);
			_contentPane.addEventListener(Event.REMOVED_FROM_STAGE, __removeFromStage);
			
			_list = GList(_contentPane.getChild("list"));
			_list.removeChildrenToPool();
			
			_list.addRelation(_contentPane, RelationType.Width);
			_list.removeRelation(_contentPane, RelationType.Height);
			_contentPane.addRelation(_list, RelationType.Height);
			
			_list.addEventListener(ItemEvent.CLICK, __clickItem);
		}
		
		public function dispose():void
		{
			_contentPane.dispose();
		}
		
		public function addItem(caption:String, callback:*=null):GButton
		{
			var item:GButton = _list.addItemFromPool().asButton;
			item.title = caption;
			item.data = callback;
			item.grayed = false;
			item.useHandCursor = false;
			var c:Controller = item.getController("checked");
			if(c!=null)
				c.selectedIndex = 0;
			if(Mouse.supportsCursor)
			{
				item.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
				item.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
			}
			return item;
		}
		
		public function addItemAt(caption:String, index:int, callback:*=null):GButton
		{
			var item:GButton = _list.getFromPool().asButton;
			_list.addChildAt(item, index);
			item.title = caption;
			item.data = callback;
			item.grayed = false;
			item.useHandCursor = false;
			var c:Controller = item.getController("checked");
			if(c!=null)
				c.selectedIndex = 0;
			if(Mouse.supportsCursor)
			{
				item.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
				item.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
			}
			return item;
		}
		
		public function addSeperator():void
		{
			if(UIConfig.popupMenu_seperator==null)
				throw new Error("UIConfig.popupMenu_seperator not defined");
			
			var item:GObject = list.addItemFromPool(UIConfig.popupMenu_seperator);
			if(Mouse.supportsCursor)
			{
				item.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
				item.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
			}
		}
		
		public function getItemName(index:int):String
		{
			var item:GButton = GButton(_list.getChildAt(index));
			return item.name;
		}
		
		public function setItemText(name:String, caption:String):void 
		{
			var item:GButton = _list.getChild(name).asButton;
			item.title = caption;
		}
		
		public function setItemVisible(name:String, visible:Boolean):void
		{
			var item:GButton = _list.getChild(name).asButton;
			if (item.visible != visible)
			{
				item.visible = visible;
				_list.setBoundsChangedFlag();
			}
		}
		
		public function setItemGrayed(name:String, grayed:Boolean):void
		{
			var item:GButton = _list.getChild(name).asButton;
			item.grayed = grayed;
		}
		
		public function setItemCheckable(name:String, checkable:Boolean):void
		{
			var item:GButton = _list.getChild(name).asButton;
			var c:Controller = item.getController("checked");
			if(c!=null)
			{
				if(checkable)
				{
					if(c.selectedIndex==0)
						c.selectedIndex = 1;
				}
				else
					c.selectedIndex = 0;
			}
		}
		
		public function setItemChecked(name:String, checked:Boolean):void
		{
			var item:GButton = _list.getChild(name).asButton;
			var c:Controller = item.getController("checked");
			if(c!=null)
				c.selectedIndex = checked?2:1;
		}
		
		public function isItemChecked(name:String):Boolean
		{
			var item:GButton = _list.getChild(name).asButton;
			var c:Controller = item.getController("checked");
			if(c!=null)
				return c.selectedIndex==2;
			else
				return false;
		}
		
		public function removeItem(name:String):Boolean
		{
			var item:GButton = GButton(_list.getChild(name));
			if(item!=null)
			{
				var index:int = _list.getChildIndex(item);
				_list.removeChildToPoolAt(index);
				return true;
			}
			else
				return false;
		}
		
		public function clearItems():void
		{
			_list.removeChildrenToPool();
		}
		
		public function get itemCount():int
		{
			return _list.numChildren;
		}
		
		public function get contentPane():GComponent
		{
			return _contentPane;
		}
		
		public function get list():GList
		{
			return _list;
		}
		
		public function show(target:GObject=null, downward:Object=null, parentMenu:PopupMenu=null):void
		{
			var r:GRoot = target!=null?target.root:GRoot.inst;
			r.showPopup(this.contentPane, (target is GRoot)?null:target, downward);
			_parentMenu = parentMenu;
		}
		
		public function hide():void
		{
			if(contentPane.parent)
				GRoot(contentPane.parent).hidePopup(contentPane);
		}
		
		private function showSecondLevelMenu(item:GObject):void
		{
			_expandingItem = item;
			
			var popup:PopupMenu = PopupMenu(item.data);
			if(item is GButton)
				GButton(item).selected = true;
			popup.show(item, null, this);
			
			var pt:Point = contentPane.localToRoot(item.x + item.width-5, item.y-5);
			popup.contentPane.setXY(pt.x, pt.y);
		}
		
		private function closeSecondLevelMenu():void
		{
			if(!_expandingItem)
				return;
			
			if(_expandingItem is GButton)
				GButton(_expandingItem).selected = false;
			var popup:PopupMenu = PopupMenu(_expandingItem.data);
			if(!popup)
				return;

			_expandingItem = null;
			popup.hide();
		}

		private function __clickItem(evt:ItemEvent):void
		{
			var item:GButton = evt.itemObject.asButton;
			if(item==null)
				return;
			
			if(item.grayed)
			{
				_list.selectedIndex = -1;
				return;
			}
			
			var c:Controller = item.getController("checked");
			if(c!=null && c.selectedIndex!=0)
			{
				if(c.selectedIndex==1)
					c.selectedIndex = 2;
				else
					c.selectedIndex = 1;
			}
			
			if(hideOnClickItem)
			{
				if(_parentMenu)
					_parentMenu.hide();
				hide();
			}
			
			if((item.data!=null) && !(item.data is PopupMenu))
			{
				var func:Function = item.data as Function;
				if(func!=null)
				{
					if(func.length==1)
						func(evt);
					else
						func();
				}
			}
		}
		
		private function __addedToStage(evt:Event):void
		{
			_list.selectedIndex = -1;
			_list.resizeToFit(visibleItemCount, 10);
		}
		
		private function __removeFromStage(evt:Event):void
		{
			_parentMenu = null;
			
			if(_expandingItem)
				GTimers.inst.callLater(closeSecondLevelMenu);
		}
		
		private function __rollOver(evt:MouseEvent):void
		{
			var item:GObject = GObject(evt.currentTarget);
			if((item.data is PopupMenu) || _expandingItem)
				GTimers.inst.callDelay(100, __showSubMenu, item);
		}
		
		private function __showSubMenu(item:GObject):void
		{
			var r:GRoot = contentPane.root;
			if(!r)
				return;
			
			if(_expandingItem)
			{
				if(_expandingItem==item)
					return;
				
				closeSecondLevelMenu();
			}
			
			var popup:PopupMenu = item.data as PopupMenu;
			if(!popup)
				return;
			
			showSecondLevelMenu(item);
		}
		
		private function __rollOut(evt:MouseEvent):void
		{		
			if(!_expandingItem)
				return;
				
			GTimers.inst.remove(__showSubMenu);
			var r:GRoot = contentPane.root;
			if(r)
			{
				var popup:PopupMenu =  PopupMenu(_expandingItem.data);
				var pt:Point = popup.contentPane.globalToLocal(r.nativeStage.mouseX, r.nativeStage.mouseY);
				if(pt.x>=0 && pt.y>=0 && pt.x<popup.contentPane.width && pt.y<popup.contentPane.height)
					return;
			}

			closeSecondLevelMenu();
		}
	}
}