package fairygui.extention.view
{
	import flash.utils.getTimer;
	
	import fairygui.GButton;
	import fairygui.GComponent;
	import fairygui.GList;
	import fairygui.PopupMenu;
	import fairygui.event.GTouchEvent;
	import fairygui.event.ItemEvent;
	
	import once.methods.Method;
	
	import tools.storage.DictionaryBase;

	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-10-31下午1:47:17 <br/>
	 **/
	public final class TabViewCloseableIconButton extends ViewExtentionBase
	{
		private var _listTabs:GList;
		private var _btnMore:GButton;
		private var _popMenuMore:PopupMenu;
		private var _popMenuClose:PopupMenu;
		private var _mapTabInfo:DictionaryBase;
		private var _listTabInfo:Array;
		private var _listShowingTabInfo:Array;
		private var _listHidingTabInfo:Array;
		
		private var _visitingId:String;
		private var _visitingData:Object;
		
		private var _visitMethod:Method;
		public function TabViewCloseableIconButton()
		{
			super();
		}
		//***************
		//internal
		//***************
		internal function VisitRender(render:TabIconButtonCloseable):void
		{
			var index:int = _listTabs.getChildIndex(render);
			if(index > -1)
			{
				var tabInfo:TabInfo = _listShowingTabInfo[index];
				VisitTabContent(tabInfo);
			}
		}
		/**删除一个tab页签**/
		internal function DelTab(tabId:String):void
		{
			DelTabInfo(tabId);
			var tabInfo:TabInfo;
			if(tabId==_visitingId)
			{
				var lastVisitTime:uint;
				var lastVisitIndex:int = -1;
				var index:int = 0;
				for each(tabInfo in _listShowingTabInfo)
				{
					if(lastVisitTime < tabInfo._lastVisitTime)
					{
						lastVisitIndex = index;
					}
					index++;
				}
				if(lastVisitIndex!=-1)
				{
					tabInfo = _listShowingTabInfo[lastVisitIndex];
					UpdateListShow(tabInfo);
				}
				else Empty();
			}
			else if(_visitingId!=null)
			{
				tabInfo = _mapTabInfo[_visitingId];
				UpdateListShow(tabInfo);
			}
		}
		//***************
		//noticeHandler
		//***************
		
		//***************
		//protected
		//***************
		override protected function prevInitialize():void
		{
			_listTabs = getChild("tabs").asList;
			_btnMore = getChild("btnMore").asButton;
			_mapTabInfo = new DictionaryBase();
			_listTabInfo = [];
			_listShowingTabInfo = [];
			_listHidingTabInfo = [];
			if(_btnMore!=null)
			{
				_popMenuMore = new PopupMenu();
				_popMenuClose = new PopupMenu();
				_popMenuClose.addItem("关闭", CloseSelf).name = "close";
				_popMenuClose.addItem("关闭其他", CloseOthers).name = "closeOthers";
				_popMenuClose.addItem("关闭全部", CloseAll).name = "closeAll";
			}
			_listTabs.itemRenderer = ListTabRender;
		}
		override protected function addEvents():void
		{
			if(_listTabs!=null)
			{
				_listTabs.addEventListener(ItemEvent.CLICK, OnListTabItemClick);
				_listTabs.addSizeChangeCallback(OnListTabSizeChange);
			}
			_btnMore && _btnMore.addClickListener(OnBtnMore);
		}
		override protected function delEvents():void
		{
			if(_listTabs!=null)
			{
				_listTabs.removeEventListener(ItemEvent.CLICK, OnListTabItemClick);
				_listTabs.removeSizeChangeCallback(OnListTabSizeChange);
			}
			_btnMore && _btnMore.removeClickListener(OnBtnMore);
		}
		//***************
		//private
		//***************
		private function UpdateListShow(tabInfo:TabInfo):void
		{
			VisitTabContent(tabInfo);
			if(_listTabs.numItems!=_listShowingTabInfo.length) _listTabs.numItems = _listShowingTabInfo.length;
			AdJust();
			_listTabs.selectedIndex = _listShowingTabInfo.indexOf(tabInfo);
		}
		/**显示tab的具体内容**/
		private function VisitTabContent(tabInfo:TabInfo):void
		{
			if(_visitingId==tabInfo._id) return;
			_visitingId = tabInfo._id;
			_visitingData = tabInfo._data;
			tabInfo._lastVisitTime = getTimer();
			
			_visitMethod && _visitMethod.execute();
		}
		/**调整tab列表以适应宽度**/
		private function AdJust():void
		{
			var renderNums:int = _listTabs.numItems;
			var render:GComponent;
			var renderWidthTotal:int = 0;
			for each(var tabInfo:TabInfo in _listShowingTabInfo)
			{
				renderWidthTotal += tabInfo._tabWidth;
			}
			if(renderWidthTotal < _listTabs.width)
			{
				var hidingNum:int = _listHidingTabInfo.length;
				while(renderWidthTotal < _listTabs.width && hidingNum > 0)
				{
					tabInfo = _listHidingTabInfo[hidingNum - 1];
					renderWidthTotal += tabInfo._tabWidth;
					if(renderWidthTotal > _listTabs.width)
					{
						break;
					}
					_listHidingTabInfo.pop();
					_listShowingTabInfo.push(tabInfo);
					var tab:TabIconButtonCloseable = _listTabs.addItemFromPool() as TabIconButtonCloseable;
					tab.Update(tabInfo._id, tabInfo._iconUrl, tabInfo._text, this, tabInfo._toolTip);
					hidingNum--;
				}
				_btnMore.visible = hidingNum > 0;
			}
			else if(renderWidthTotal > _listTabs.width)
			{
				var listShowingList:Array = _listShowingTabInfo.concat();
				listShowingList.sortOn("_lastVisitTime", Array.NUMERIC);
				var delIndex:int = 0;
				while(renderWidthTotal > _listTabs.width)
				{
					
					tabInfo = listShowingList.shift();
					if(tabInfo!=null)
					{
						if(tabInfo._id==_visitingId)
						{
							var temp:TabInfo = tabInfo;
							tabInfo = listShowingList.shift();
							listShowingList.unshift(temp);
							if(tabInfo==null) break;
						}
						delIndex = _listShowingTabInfo.indexOf(tabInfo);
						if(delIndex > -1)
						{
							_listHidingTabInfo.push(tabInfo);
							_listShowingTabInfo.splice(delIndex, 1);
							_listTabs.removeChildToPoolAt(delIndex);
							renderWidthTotal -= tabInfo._tabWidth;
						}
					}
					else break;
				}
				_btnMore.visible = true;
			}
			_btnMore.text = (_listTabInfo.length - _listShowingTabInfo.length) + "";
			
			_popMenuClose.setItemGrayed("closeOthers", _listShowingTabInfo.length <= 1);
		}
		private function CloseSelf():void
		{
			DelTab(_visitingId);
		}
		private function CloseOthers():void
		{
			for(var tabId:String in _mapTabInfo)
			{
				tabId!=_visitingId && DelTabInfo(tabId);
			}
			UpdateListShow(_mapTabInfo[_visitingId]);
		}
		private function CloseAll():void
		{
			for(var tabId:String in _mapTabInfo)
			{
				DelTabInfo(tabId);
			}
			Empty();
		}
		private function Empty():void
		{
			_visitingId = null;
			_visitingData = null;
			_listTabs.numItems = 0;
			_btnMore.visible = false;
		}
		private function DelTabInfo(tabId:String):void
		{
			var delIndex:int = 0;
			var tabInfo:TabInfo = _mapTabInfo.Del(tabId);
			if(tabInfo!=null)
			{
				delIndex = _listTabInfo.indexOf(tabInfo);
				delIndex > -1 && _listTabInfo.splice(delIndex, 1);
				_popMenuMore.removeItem(tabInfo._id);
				
				delIndex = _listShowingTabInfo.indexOf(tabInfo);
				if(delIndex > -1)
				{
					_listShowingTabInfo.splice(delIndex, 1);
				}
				tabInfo.gc();
			}
		}
		private function PopupMenuSelect(e:ItemEvent):void
		{
			var tabInfo:TabInfo = _listTabInfo[_popMenuMore.list.getChildIndex(e.itemObject)];
			if(tabInfo!=null)
			{
				AddTab(tabInfo._id, tabInfo._text, tabInfo._data, tabInfo._iconUrl);
			}
		}
		private function ListTabRender(index:int, render:TabIconButtonCloseable):void
		{
			var tabInfo:TabInfo = _listShowingTabInfo[index];
			render.Update(tabInfo._id, tabInfo._iconUrl, tabInfo._text, this, tabInfo._toolTip);
			tabInfo._tabWidth = render.width;
		}
		//***************
		//eventHandler
		//***************
		private function OnListTabItemClick(e:ItemEvent):void
		{
			var tabInfo:TabInfo = _listShowingTabInfo[_listTabs.selectedIndex];
			if(tabInfo==null)
			{
				var list:Array = _listShowingTabInfo.concat();
				list.sortOn("_lastVisitTime", Array.NUMERIC);
				tabInfo = list[list.length - 1];
			}
			tabInfo!=null && UpdateListShow(tabInfo);
			
			if(e.rightButton)
			{
				_popMenuClose.show();
			}
		}
		private function OnListTabSizeChange():void
		{
			AdJust();
		}
		private function OnBtnMore(e:GTouchEvent):void
		{
			_popMenuMore.show();
		}
		//***************
		//public
		//***************
		/**添加一个tab页签**/
		public function AddTab(id:String, text:String, data:Object, iconUrl:String=null, toolTip:String=null):void
		{
			var tabInfo:TabInfo = _mapTabInfo[id];
			var selectIndex:int = 0;
			if(tabInfo==null)
			{
				tabInfo = TabInfo.Borrow();
				tabInfo.Update(id, text, data, iconUrl, toolTip);
				_mapTabInfo.Add(id, tabInfo);
				_listTabInfo.unshift(tabInfo);
				_listShowingTabInfo.push(tabInfo);
				var btn:GButton = _popMenuMore.addItemAt(text, 0, PopupMenuSelect);
				btn.tooltips = toolTip;
				btn.name = tabInfo._id;
				selectIndex = _listShowingTabInfo.length;
			}
			else
			{
				tabInfo.Update(id, text, data, iconUrl, toolTip);
				selectIndex = _listShowingTabInfo.indexOf(tabInfo);
				if(selectIndex==-1)
				{
					_listShowingTabInfo.push(tabInfo);
					selectIndex = _listShowingTabInfo.length-1;
				}
			}
			UpdateListShow(tabInfo);
		}
		/**正在访问的tab的id**/
		public function get visitingId():String
		{
			return _visitingId;
		}
		/**正在访问的tab所携带的数据**/
		public function get visitingData():Object
		{
			return _visitingData;
		}
		
		public function set visitMethod(method:Method):void
		{
			_visitMethod = method;
		}
		
		override public function dispose():void
		{
			_visitMethod && _visitMethod.gc();
			_visitMethod = null;
			_popMenuMore && _popMenuMore.dispose();
			_popMenuMore = null;
			var tabInfo:TabInfo;
			for(var tabId:String in _mapTabInfo)
			{
				(_mapTabInfo.Del(tabId) as TabInfo).gc();
			}
			_listTabInfo.length = 0;
			super.dispose();
			
			_listTabs = null;
			_btnMore = null;
			_listTabInfo = null;
			_mapTabInfo = null;
		}
	}
}
import flash.utils.getTimer;

class TabInfo
{
	/**id**/
	public var _id:String;
	/**页签内容**/
	public var _text:String;
	/**页签数据**/
	public var _data:Object;
	/**页签图标url**/
	public var _iconUrl:String;
	/**toolTip**/
	public var _toolTip:String;
	/**页签最后访问时间**/
	public var _lastVisitTime:uint;
	/**页签的宽度**/
	public var _tabWidth:int;
	
	private static const Pool:Vector.<TabInfo> = new Vector.<TabInfo>();
	public function TabInfo():void
	{
		
	}
	
	public static function Borrow():TabInfo
	{
		if(Pool.length > 0) return Pool.pop();
		return new TabInfo();
	}
	
	public function Update(id:String, text:String, data:Object, iconUrl:String=null, toolTip:String=null):void
	{
		_id = id;
		_text = text;
		_data = data;
		_iconUrl = iconUrl;
		_toolTip = toolTip;
		_lastVisitTime = getTimer();
	}
	
	public function gc():void
	{
		_id = null;
		_text = null;
		_data = null;
		_iconUrl = null;
		_toolTip = null;
		
		Pool.push(this);
	}
}