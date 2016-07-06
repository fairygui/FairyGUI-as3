package fairygui
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import fairygui.display.UIDisplayObject;
	import fairygui.event.GTouchEvent;
	import fairygui.event.ItemEvent;
	import fairygui.utils.GTimers;

	[Event(name = "itemClick", type = "fairygui.event.ItemEvent")]
	public class GList extends GComponent
	{
		/**
		 * itemRenderer(int index, GObject item);
		 */
		public var itemRenderer:Function;
		public var scrollItemToViewOnClick: Boolean;
		
		private var _layout:int;
		private var _lineItemCount:int;
		private var _lineGap:int;
		private var _columnGap:int;
		private var _defaultItem:String;
		private var _autoResizeItem:Boolean;
		private var _selectionMode:int;
		private var _lastSelectedIndex:int;
		private var _pool:GObjectPool;
		
		//Virtual List support
		private var _virtual:Boolean;
		private var _loop:Boolean;
		private var _numItems:int;
		private var _firstIndex:int; //the top left index
		private var _viewCount:int; //item count in view
		private var _curLineItemCount:int; //item count in one line
		private var _itemSize:Point;
		private var _virtualListChanged:int; //1-content changed, 2-size changed
		private var _eventLocked:Boolean;
		
		public function GList()
		{
			super();

			_trackBounds = true;
			_pool = new GObjectPool();
			_layout = ListLayoutType.SingleColumn;
			_autoResizeItem = true;
			_lastSelectedIndex = -1;
			this.opaque = true;
			scrollItemToViewOnClick = true;
		}
		
		public override function dispose():void
		{
			_pool.clear();
			super.dispose();
		}

		final public function get layout():int
		{
			return _layout;
		}

		final public function set layout(value:int):void
		{
			if(_layout != value)
			{
				_layout = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}
		
		final public function get lineItemCount():int
		{
			return _lineItemCount;
		}
		
		final public function set lineItemCount(value:int):void
		{
			if (_lineItemCount != value)
			{
				_lineItemCount = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}

		final public function get lineGap():int
		{
			return _lineGap;
		}

		final public function set lineGap(value:int):void
		{
			if(_lineGap != value)
			{
				_lineGap = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}

		final public function get columnGap():int
		{
			return _columnGap;
		}

		final public function set columnGap(value:int):void
		{
			if(_columnGap != value)
			{
				_columnGap = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}
		
		final public function get virtualItemSize():Point
		{
			return _itemSize;
		}
		
		final public function set virtualItemSize(value:Point):void
		{
			if(_virtual)
			{
				if(_itemSize==null)
					_itemSize = new Point();
				_itemSize.copyFrom(value);
				setVirtualListChangedFlag(true);
			}
		}
		
		final public function get defaultItem():String
		{
			return _defaultItem;
		}
		
		final public function set defaultItem(val:String):void
		{
			_defaultItem = val;
		}
		
		final public function get autoResizeItem():Boolean
		{
			return _autoResizeItem;
		}
		
		final public function set autoResizeItem(value:Boolean):void
		{
			_autoResizeItem = value;
		}
		
		final public function get selectionMode():int
		{
			return _selectionMode;
		}
		
		final public function set selectionMode(value:int):void
		{
			_selectionMode = value;
		}
		
		public function get itemPool():GObjectPool
		{
			return _pool;
		}
		
		public function getFromPool(url:String=null):GObject
		{
			if(!url)
				url = _defaultItem;

			var ret:GObject = _pool.getObject(url);
			if(ret!=null)
				ret.visible = true;
			return ret;			
		}
		
		public function returnToPool(obj:GObject):void
		{
			_pool.returnObject(obj);
		}
		
		override public function addChildAt(child:GObject, index:int):GObject
		{
			if(_autoResizeItem)
			{
				if(_layout==ListLayoutType.SingleColumn)
					child.width = this.viewWidth;
				else if(_layout==ListLayoutType.SingleRow)
					child.height = this.viewHeight;
			}
			
			super.addChildAt(child, index);
			
			if(child is GButton)
			{
				var button:GButton = GButton(child);
				button.selected = false;
				button.changeStateOnClick = false;
				button.useHandCursor = false;
			}
			child.addEventListener(GTouchEvent.CLICK, __clickItem);
			child.addEventListener("rightClick", __rightClickItem);
			
			return child;
		}
		
		public function addItem(url:String=null):GObject
		{
			if(!url)
				url = _defaultItem;
			
			return addChild(UIPackage.createObjectFromURL(url));
		}

		public function addItemFromPool(url:String=null):GObject
		{
			return addChild(getFromPool(url));
		}
		
		override public function removeChildAt(index:int, dispose:Boolean=false):GObject
		{
			var child:GObject = super.removeChildAt(index, dispose);
			child.removeEventListener(GTouchEvent.CLICK, __clickItem);
			child.removeEventListener("rightClick", __rightClickItem);
			
			return child;
		}
		
		public function removeChildToPoolAt(index:int):void
		{
			var child:GObject = super.removeChildAt(index);
			returnToPool(child);
		}
		
		public function removeChildToPool(child:GObject):void
		{
			super.removeChild(child);
			returnToPool(child);
		}
		
		public function removeChildrenToPool(beginIndex:int=0, endIndex:int=-1):void
		{
			if (endIndex < 0 || endIndex >= _children.length) 
				endIndex = _children.length - 1;
			
			for (var i:int=beginIndex; i<=endIndex; ++i)
				removeChildToPoolAt(beginIndex);
		}

		public function get selectedIndex():int
		{
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GButton = _children[i].asButton;
				if (obj != null && obj.selected)
				{
					var j:int = _firstIndex + i;
					if (_loop && _numItems>0)
						j = j%_numItems;
					return j;
				}
			}
			return -1;
		}
		
		public function set selectedIndex(value:int):void
		{
			clearSelection();
			if (value >= 0 && value < this.numItems)
				addSelection(value);
		}
		
		public function getSelection():Vector.<int>
		{
			var ret:Vector.<int> = new Vector.<int>();
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GButton = _children[i].asButton;
				if (obj != null && obj.selected)
				{
					var j:int = _firstIndex + i;
					if (_loop && _numItems>0)
						j = j%_numItems;
					ret.push(j);
				}
			}
			return ret;
		}
		
		public function addSelection(index:int, scrollItToView:Boolean=false):void
		{
			if(_selectionMode==ListSelectionMode.None)
				return;
			
			if(_selectionMode==ListSelectionMode.Single)
				clearSelection();

			if (scrollItToView)
				scrollToView(index);
			
			if(_loop && _numItems>0)
			{
				var j:int = _firstIndex % _numItems;
				if (index >= j)
					index = _firstIndex + (index - j);
				else
					index = _firstIndex + _numItems + (j - index);
			}
			else
				index -= _firstIndex;

			if (index<0 || index >= _children.length)
				return;
			
			var obj:GButton = getChildAt(index).asButton;
			if (obj != null && !obj.selected)
				obj.selected = true;
		}
		
		public function removeSelection(index:int):void
		{
			if(_selectionMode==ListSelectionMode.None)
				return;
			
			if (_loop && _numItems > 0)
			{
				var j:int = _firstIndex % _numItems;
				if (index >= j)
					index = _firstIndex + (index - j);
				else
					index = _firstIndex + _numItems + (j - index);
			}
			else
				index -= _firstIndex;
			if (index < 0 || index >= _children.length)
				return;
			
			var obj:GButton = getChildAt(index).asButton;
			if(obj!=null && obj.selected)
				obj.selected = false;
		}
		
		public function clearSelection():void
		{
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GButton = _children[i].asButton;
				if(obj!=null)
					obj.selected = false;
			}
		}
		
		public function selectAll():void
		{
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GButton = _children[i].asButton;
				if(obj!=null)
					obj.selected = true;
			}
		}
		
		public function selectNone():void
		{
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GButton = _children[i].asButton;
				if(obj!=null)
					obj.selected = false;
			}
		}
		
		public function selectReverse():void
		{
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GButton = _children[i].asButton;
				if(obj!=null)
					obj.selected = !obj.selected;
			}
		}
		
		public function handleArrowKey(dir:int):void
		{
			var index:int = this.selectedIndex;
			if(index==-1)
				return;
			
			switch(dir)
			{
				case 1://up
					if(_layout==ListLayoutType.SingleColumn || _layout==ListLayoutType.FlowVertical)
					{
						index--;
						if(index>=0)
						{
							clearSelection();
							addSelection(index, true);
						}
					}
					else if(_layout==ListLayoutType.FlowHorizontal)
					{
						var current:GObject = _children[index];
						var k:int = 0;
						for(var i:int = index-1;i>=0;i--)
						{
							var obj:GObject = _children[i];
							if(obj.y!=current.y)
							{
								current = obj;
								break;
							}
							k++;
						}
						for(;i>=0;i--)
						{
							obj = _children[i];
							if(obj.y!=current.y)
							{
								clearSelection();
								addSelection(i+k+1, true);
								break;
							}
						}
					}
					break;

				case 3://right
					if(_layout==ListLayoutType.SingleRow || _layout==ListLayoutType.FlowHorizontal)
					{
						index++;
						if(index<_children.length)
						{
							clearSelection();
							addSelection(index, true);
						}
					}
					else if(_layout==ListLayoutType.FlowVertical)
					{
						current = _children[index];
						k = 0;
						var cnt:int = _children.length;
						for(i = index+1;i<cnt;i++)
						{
							obj = _children[i];
							if(obj.x!=current.x)
							{
								current = obj;
								break;
							}
							k++;
						}
						for(;i<cnt;i++)
						{
							obj = _children[i];
							if(obj.x!=current.x)
							{
								clearSelection();
								addSelection(i-k-1, true);
								break;
							}
						}
					}
					break;
				
				case 5://down
					if(_layout==ListLayoutType.SingleColumn || _layout==ListLayoutType.FlowVertical)
					{
						index++;
						if(index<_children.length)
						{
							clearSelection();
							addSelection(index, true);
						}
					}
					else if(_layout==ListLayoutType.FlowHorizontal)
					{
						current = _children[index];
						k = 0;
						cnt = _children.length;
						for(i = index+1;i<cnt;i++)
						{
							obj = _children[i];
							if(obj.y!=current.y)
							{
								current = obj;
								break;
							}
							k++;
						}
						for(;i<cnt;i++)
						{
							obj = _children[i];
							if(obj.y!=current.y)
							{
								clearSelection();
								addSelection(i-k-1, true);
								break;
							}
						}
					}
					break;
				
				case 7://left
					if(_layout==ListLayoutType.SingleRow || _layout==ListLayoutType.FlowHorizontal)
					{
						index--;
						if(index>=0)
						{
							clearSelection();
							addSelection(index, true);
						}
					}
					else if(_layout==ListLayoutType.FlowVertical)
					{
						current = _children[index];
						k = 0;
						for(i = index-1;i>=0;i--)
						{
							obj = _children[i];
							if(obj.x!=current.x)
							{
								current = obj;
								break;
							}
							k++;
						}
						for(;i>=0;i--)
						{
							obj = _children[i];
							if(obj.x!=current.x)
							{
								clearSelection();
								addSelection(i+k+1, true);
								break;
							}
						}
					}
					break;
			}
		}
		
		public function getItemNear(globalX:Number, globalY:Number):GObject
		{
			ensureBoundsCorrect();
			
			var objs:Array = root.nativeStage.getObjectsUnderPoint(new Point(globalX, globalY));
			if(!objs || objs.length==0)
				return null;
			
			for each(var obj:DisplayObject in objs)
			{
				while (obj != null && !(obj is Stage))
				{
					if (obj is UIDisplayObject)
					{
						var gobj:GObject = UIDisplayObject(obj).owner;
						while(gobj!=null && gobj.parent!=this)
							gobj = gobj.parent;
						
						if(gobj!=null)
							return gobj;
					}
					
					obj = obj.parent;
				}
			}
			return null;
		}

		private function __clickItem(evt:GTouchEvent):void
		{
			var item:GObject = GObject(evt.currentTarget);
			setSelectionOnEvent(item);
			
			if (scrollPane != null && scrollItemToViewOnClick)
				scrollPane.scrollToView(item, true);
			
			var ie:ItemEvent = new ItemEvent(ItemEvent.CLICK, item);
			ie.stageX = evt.stageX;
			ie.stageY = evt.stageY;
			ie.clickCount = evt.clickCount;
			this.dispatchEvent(ie);
		}
		
		private function __rightClickItem(evt:MouseEvent):void
		{
			var item:GObject = GObject(evt.currentTarget);
			if((item is GButton) && !GButton(item).selected)
				setSelectionOnEvent(item);
			
			if (scrollPane != null && scrollItemToViewOnClick)
				scrollPane.scrollToView(item, true);
			
			var ie:ItemEvent = new ItemEvent(ItemEvent.CLICK, item);
			ie.stageX = evt.stageX;
			ie.stageY = evt.stageY;
			ie.rightButton = true;
			this.dispatchEvent(ie);
		}
		
		private function setSelectionOnEvent(item:GObject):void
		{
			if(!(item is GButton) || _selectionMode==ListSelectionMode.None)
				return;
			
			var dontChangeLastIndex:Boolean = false;
			var button:GButton = GButton(item);
			var index:int = getChildIndex(item);
			
			if(_selectionMode==ListSelectionMode.Single)
			{
				if(!button.selected)
				{
					clearSelectionExcept(button);
					button.selected = true;
				}
			}
			else
			{
				var r:GRoot = this.root;
				if(r.shiftKeyDown)
				{
					if(!button.selected)
					{
						if(_lastSelectedIndex!=-1)
						{
							var min:int = Math.min(_lastSelectedIndex, index);
							var max:int = Math.max(_lastSelectedIndex, index);
							max = Math.min(max, _children.length-1);
							for(var i:int=min;i<=max;i++)
							{
								var obj:GButton = getChildAt(i).asButton;
								if(obj!=null && !obj.selected)
									obj.selected = true;
							}
							
							dontChangeLastIndex = true;
						}
						else
						{
							button.selected = true;
						}
					}
				}
				else if(r.ctrlKeyDown || _selectionMode==ListSelectionMode.Multiple_SingleClick)
				{
					button.selected = !button.selected;
				}
				else
				{
					if(!button.selected)
					{
						clearSelectionExcept(button);
						button.selected = true;
					}
					else
						clearSelectionExcept(button);
				}
			}
			
			if(!dontChangeLastIndex)
				_lastSelectedIndex = index;
		}
		
		private function clearSelectionExcept(obj:GObject):void
		{
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var button:GButton = _children[i].asButton;
				if(button!=null && button!=obj && button.selected)
					button.selected = false;
			}
		}
		
		public function resizeToFit(itemCount:int=int.MAX_VALUE, minSize:int=0):void
		{
			ensureBoundsCorrect();
			
			var curCount:int = this.numItems;
			if(itemCount>curCount)
				itemCount = curCount;
			
			if (_virtual)
			{
				var lineCount:int = Math.ceil(itemCount / _curLineItemCount);
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
					this.viewHeight = lineCount * _itemSize.y + Math.max(0, lineCount - 1) * _lineGap;
				else
					this.viewWidth = lineCount * _itemSize.x + Math.max(0, lineCount - 1) * _columnGap;
			}
			else if (itemCount == 0)
			{
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
					this.viewHeight = minSize;
				else
					this.viewWidth = minSize;
			}
			else
			{
				var i:int = itemCount - 1;
				var obj:GObject = null;
				while (i >= 0)
				{
					obj = this.getChildAt(i);
					if (obj.visible)
						break;
					i--;
				}
				if (i < 0)
				{
					if (_layout==ListLayoutType.SingleColumn || _layout==ListLayoutType.FlowHorizontal)
						this.viewHeight = minSize;
					else
						this.viewWidth = minSize;
				}
				else
				{
					var size:int;
					if(_layout==ListLayoutType.SingleColumn || _layout==ListLayoutType.FlowHorizontal)
					{
						size = obj.y + obj.height;
						if (size < minSize)
							size = minSize;
						this.viewHeight = size;
					}
					else
					{
						size = obj.x + obj.width;
						if (size < minSize)
							size = minSize;
						this.viewWidth = size;
					}
				}
			}
		}
		
		public function getMaxItemWidth():int
		{
			var cnt:int = _children.length;				
			var max:int = 0;
			for(var i:int=0;i<cnt;i++)
			{
				var child:GObject = getChildAt(i);
				if(child.width>max)
					max = child.width;
			}
			return max;
		}

		override protected function handleSizeChanged():void
		{
			super.handleSizeChanged();
			
			if(_autoResizeItem)
				adjustItemsSize();
			
			if(_layout==ListLayoutType.FlowHorizontal || _layout==ListLayoutType.FlowVertical)
			{
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}
		
		public function adjustItemsSize():void
		{
			if(_layout==ListLayoutType.SingleColumn)
			{
				var cnt:int = _children.length;				
				var cw:int = this.viewWidth;
				for(var i:int=0;i<cnt;i++)
				{
					var child:GObject = getChildAt(i);
					child.width = cw;
				}
			}
			else if(_layout==ListLayoutType.SingleRow)
			{
				cnt = _children.length;
				var ch:int = this.viewHeight;
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					child.height = ch;
				}
			}
		}
		
		override public function GetSnappingPosition(xValue:Number, yValue:Number, resultPoint:Point=null):Point
		{
			if (_virtual)
			{
				if(!resultPoint)
					resultPoint = new Point();
				
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					var i:int = Math.floor(yValue / (_itemSize.y + _lineGap));
					if (yValue > i * (_itemSize.y + _lineGap) + _itemSize.y / 2)
						i++;
					
					resultPoint.x = xValue;
					resultPoint.y = i * (_itemSize.y + _lineGap);
				}
				else
				{
					i = Math.floor(xValue / (_itemSize.x + _columnGap));
					if (xValue > i * (_itemSize.x + _columnGap) + _itemSize.x / 2)
						i++;
					
					resultPoint.x = i * (_itemSize.x + _columnGap);
					resultPoint.y = yValue;
				}
				
				return resultPoint;
			}
			else
				return super.GetSnappingPosition(xValue, yValue, resultPoint);
		}
		
		public function scrollToView(index:int, ani:Boolean=false, setFirst:Boolean=false):void
		{
			if (_virtual)
			{
				if(this._virtualListChanged!=0) { 
					this.refreshVirtualList();
					GTimers.inst.remove(this.refreshVirtualList);
				}
				
				if (this.scrollPane != null)
					scrollPane.scrollToView(getItemRect(index), ani, setFirst);
				else if (parent != null && parent.scrollPane != null)
					parent.scrollPane.scrollToView(getItemRect(index), ani, setFirst);
			}
			else
			{
				var obj:GObject = getChildAt(index);
				if (this.scrollPane != null)
					scrollPane.scrollToView(obj, ani, setFirst);
				else if (parent != null && parent.scrollPane != null)
					parent.scrollPane.scrollToView(obj, ani, setFirst);
			}
		}
		
		override public function getFirstChildInView():int
		{
			var ret:int = super.getFirstChildInView();
			if (ret != -1)
			{
				ret += _firstIndex;
				if (_loop &&  _numItems>0)
					ret = ret % _numItems;
				return ret;
			}
			else
				return -1;
		}
		
		public function setVirtual():void
		{
			_setVirtual(false);
		}
		
		/// <summary>
		/// Set the list to be virtual list, and has loop behavior.
		/// </summary>
		public function setVirtualAndLoop():void
		{
			_setVirtual(true);
		}
		
		/// <summary>
		/// Set the list to be virtual list.
		/// </summary>
		private function _setVirtual(loop:Boolean):void
		{
			if (!_virtual)
			{
				if (this.scrollPane == null)
					throw new Error("Virtual list must be scrollable!");
				
				if (loop)
				{
					if (_layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.FlowVertical)
						throw new Error("Only single row or single column layout type is supported for loop list!");
					
					this.scrollPane.bouncebackEffect = false;
				}
				
				_virtual = true;
				_loop = loop;
				_itemSize = new Point();
				removeChildrenToPool();
				
				if(_itemSize==null)
				{
					_itemSize = new Point();
					var obj:GObject = getFromPool(null);
					_itemSize.x = obj.width;
					_itemSize.y = obj.height;
					returnToPool(obj);
				}
				
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
					this.scrollPane.scrollSpeed = _itemSize.y;
				else
					this.scrollPane.scrollSpeed = _itemSize.x;
				
				this.scrollPane.addEventListener(Event.SCROLL, __scrolled, true);
				setVirtualListChangedFlag(true);
			}
		}
		
		/// <summary>
		/// Set the list item count. 
		/// If the list is not virtual, specified number of items will be created. 
		/// If the list is virtual, only items in view will be created.
		/// </summary>
		public function get numItems():int
		{
			if (_virtual)
				return _numItems;
			else
				return _children.length;
		}
		
		public function set numItems(value:int):void
		{
			if (_virtual)
			{
				_numItems = value;
				setVirtualListChangedFlag();
			}
			else
			{
				var cnt:int = _children.length;
				if (value > cnt)
				{
					for (var i:int = cnt; i < value; i++)
						addItemFromPool();
				}
				else
				{
					removeChildrenToPool(value, cnt);
				}
				
				if (itemRenderer != null)
				{
					for (i = 0; i < value; i++)
						itemRenderer(i, getChildAt(i));
				}
			}
		}
		
		private function __parentSizeChanged():void
		{
			setVirtualListChangedFlag(true);
		}
		
		private function setVirtualListChangedFlag(layoutChanged:Boolean=false):void
		{
			if (layoutChanged)
				_virtualListChanged = 2;
			else if (_virtualListChanged == 0)
				_virtualListChanged = 1;
			
			GTimers.inst.callLater(refreshVirtualList);
		}
		
		private function refreshVirtualList():void
		{
			if (_virtualListChanged == 0)
				return;
			
			var layoutChanged:Boolean = _virtualListChanged == 2;
			_virtualListChanged = 0;
			_eventLocked = true;
			
			if(layoutChanged)
			{
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					if (_layout == ListLayoutType.SingleColumn)
						_curLineItemCount = 1;
					else if (_lineItemCount != 0)
						_curLineItemCount = _lineItemCount;
					else
						_curLineItemCount = Math.floor((_scrollPane.viewWidth + _columnGap) / (_itemSize.x + _columnGap));
					_viewCount = (Math.ceil((_scrollPane.viewHeight + _lineGap) / (_itemSize.y + _lineGap)) + 1) * _curLineItemCount;
					var numChildren:int = _children.length;
					if (numChildren < _viewCount)
					{
						for (var i:int = numChildren; i < _viewCount; i++)
							this.addItemFromPool();
					}
					else if (numChildren > _viewCount)
						this.removeChildrenToPool(_viewCount, numChildren);
				}
				else
				{
					if (_layout == ListLayoutType.SingleRow)
						_curLineItemCount = 1;
					else if (_lineItemCount != 0)
						_curLineItemCount = _lineItemCount;
					else
						_curLineItemCount = Math.floor((_scrollPane.viewHeight + _lineGap) / (_itemSize.y + _lineGap));
					_viewCount = (Math.ceil((_scrollPane.viewWidth + _columnGap) / (_itemSize.x + _columnGap)) + 1) * _curLineItemCount;
					numChildren = _children.length;
					if (numChildren < _viewCount)
					{
						for (i = numChildren; i < _viewCount; i++)
							this.addItemFromPool();
					}
					else if (numChildren > _viewCount)
						this.removeChildrenToPool(_viewCount, numChildren);
				}
			}
			
			ensureBoundsCorrect();			
			
			if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
			{
				var ch:Number;
				if (_layout == ListLayoutType.SingleColumn)
				{
					ch = _numItems * _itemSize.y + Math.max(0, _numItems - 1) * _lineGap;
					if (_loop && ch > 0)
						ch = ch * 5 + _lineGap * 4;
				}
				else
				{
					var lineCount:int = Math.ceil(_numItems / _curLineItemCount);
					ch = lineCount * _itemSize.y + Math.max(0, lineCount - 1) * _lineGap;
				}
				
				this.scrollPane.setContentSize(this.scrollPane.contentWidth, ch);
			}
			else
			{
				var cw:Number;
				if (_layout == ListLayoutType.SingleRow)
				{
					cw = _numItems * _itemSize.x + Math.max(0, _numItems - 1) * _columnGap;
					if (_loop && cw > 0)
						cw = cw * 5 + _columnGap * 4;
				}
				else
				{
					lineCount = Math.ceil(_numItems / _curLineItemCount);
					cw = lineCount * _itemSize.x + Math.max(0, lineCount - 1) * _columnGap;
				}
				
				this.scrollPane.setContentSize(cw, this.scrollPane.contentHeight);
			}
			
			_eventLocked = false;
			__scrolled(null);
		}
		
		private function renderItems(beginIndex:int, endIndex:int):void
		{
			for (var i:int = 0; i < _viewCount; i++)
			{
				var obj:GObject = getChildAt(i);
				var j:int = _firstIndex + i;
				if (_loop && _numItems>0)
					j = j%_numItems;
				
				if (j < _numItems)
				{
					obj.visible = true;
					if (i >= beginIndex && i < endIndex)
						itemRenderer(j, obj);
				}
				else
					obj.visible = false;
			}
		}
		
		private function getItemRect(index:int):Rectangle
		{
			var rect:Rectangle;
			var index1:int = index / _curLineItemCount;
			var index2:int = index % _curLineItemCount;
			switch (_layout)
			{
				case ListLayoutType.SingleColumn:
					rect = new Rectangle(0, index1 * _itemSize.y + Math.max(0, index1 - 1) * _lineGap,
						this.viewWidth, _itemSize.y);
					break;
				
				case ListLayoutType.FlowHorizontal:
					rect = new Rectangle(index2 * _itemSize.x + Math.max(0, index2 - 1) * _columnGap,
						index1 * _itemSize.y + Math.max(0, index1 - 1) * _lineGap,
						_itemSize.x, _itemSize.y);
					break;
				
				case ListLayoutType.SingleRow:
					rect = new Rectangle(index1 * _itemSize.x + Math.max(0, index1 - 1) * _columnGap, 0,
						_itemSize.x, this.viewHeight);
					break;
				
				case ListLayoutType.FlowVertical:
					rect = new Rectangle(index1 * _itemSize.x + Math.max(0, index1 - 1) * _columnGap,
						index2 * _itemSize.y + Math.max(0, index2 - 1) * _lineGap,
						_itemSize.x, _itemSize.y);
					break;
			}
			return rect;
		}
		
		private function __scrolled(evt:Event):void
		{
			if(_eventLocked)
				return;
			
			if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
			{
				if (_loop)
				{
					if (_scrollPane.percY == 0)
						_scrollPane.posY = _numItems * (_itemSize.y + _lineGap);
					else if (_scrollPane.percY == 1)
						_scrollPane.posY = this.scrollPane.contentHeight - _numItems * (_itemSize.y + _lineGap) - this.viewHeight;
				}
				
				var firstLine:int = Math.floor((_scrollPane.posY + _lineGap) / (_itemSize.y + _lineGap));
				var newFirstIndex:int = firstLine * _curLineItemCount;
				for (var i:int = 0; i < _viewCount; i++)
				{
					var obj:GObject = getChildAt(i);
					obj.y = (firstLine + Math.floor(i / _curLineItemCount)) * (_itemSize.y + _lineGap);
				}
				if (newFirstIndex >= _numItems)
					newFirstIndex -= _numItems;
				
				if (newFirstIndex != _firstIndex || evt == null)
				{
					var oldFirstIndex:int = _firstIndex;
					_firstIndex = newFirstIndex;
					
					if (evt == null || oldFirstIndex + _viewCount < newFirstIndex || oldFirstIndex > newFirstIndex + _viewCount)
					{
						//no intersection, render all
						for (i = 0; i < _viewCount; i++)
						{
							obj = getChildAt(i);
							if (obj is GButton)
								GButton(obj).selected = false;
						}
						renderItems(0, _viewCount);
					}
					else if (oldFirstIndex > newFirstIndex)
					{
						var j1:int = oldFirstIndex - newFirstIndex;
						var j2:int = _viewCount - j1;
						for (i = j2 - 1; i >= 0; i--)
						{
							var obj1:GObject = getChildAt(i);
							var obj2:GObject = getChildAt(i + j1);
							if (obj2 is GButton)
								GButton(obj2).selected = false;
							var tmp:Number = obj1.y;
							obj1.y = obj2.y;
							obj2.y = tmp;
							swapChildrenAt(i + j1, i);
						}
						renderItems(0, j1);
					}
					else
					{
						j1 = newFirstIndex - oldFirstIndex;
						j2 = _viewCount - j1;
						for (i = 0; i < j2; i++)
						{
							obj1 = getChildAt(i);
							obj2 = getChildAt(i + j1);
							if (obj1 is GButton)
								GButton(obj1).selected = false;
							tmp = obj1.y;
							obj1.y = obj2.y;
							obj2.y = tmp;
							swapChildrenAt(i + j1, i);
						}
						renderItems(j2, _viewCount);
					}
				}
				
				if (this.childrenRenderOrder == ChildrenRenderOrder.Arch)
				{
					var mid:Number = this.scrollPane.posY + this.viewHeight / 2;
					var minDist:Number = int.MAX_VALUE;
					var dist:Number;
					var apexIndex:int = 0;
					for (i = 0; i < _viewCount; i++)
					{
						obj = getChildAt(i);
						if (obj.visible)
						{
							dist = Math.abs(mid - obj.y - obj.height / 2);
							if (dist < minDist)
							{
								minDist = dist;
								apexIndex = i;
							}
						}
					}
					this.apexIndex = apexIndex;
				}
			}
			else
			{
				if (_loop)
				{
					if (_scrollPane.percX == 0)
						_scrollPane.posX = _numItems * (_itemSize.x + _columnGap);
					else if (_scrollPane.percX == 1)
						_scrollPane.posX = this.scrollPane.contentWidth - _numItems * (_itemSize.x + _columnGap) - this.viewWidth;
				}
				
				firstLine = Math.floor((_scrollPane.posX + _columnGap) / (_itemSize.x + _columnGap));
				newFirstIndex = firstLine * _curLineItemCount;
				
				for (i = 0; i < _viewCount; i++)
				{
					obj = getChildAt(i);
					obj.x = (firstLine + Math.floor(i / _curLineItemCount)) * (_itemSize.x + _columnGap);
				}
				
				if (newFirstIndex >= _numItems)
					newFirstIndex -= _numItems;
				
				if (newFirstIndex != _firstIndex || evt == null)
				{
					oldFirstIndex = _firstIndex;
					_firstIndex = newFirstIndex;
					if (evt == null || oldFirstIndex + _viewCount < newFirstIndex || oldFirstIndex > newFirstIndex + _viewCount)
					{
						//no intersection, render all
						for (i = 0; i < _viewCount; i++)
						{
							obj = getChildAt(i);
							if (obj is GButton)
								GButton(obj).selected = false;
						}
						
						renderItems(0, _viewCount);
					}
					else if (oldFirstIndex > newFirstIndex)
					{
						j1 = oldFirstIndex - newFirstIndex;
						j2 = _viewCount - j1;
						for (i = j2 - 1; i >= 0; i--)
						{
							obj1 = getChildAt(i);
							obj2 = getChildAt(i + j1);
							if (obj2 is GButton)
								GButton(obj2).selected = false;
							tmp = obj1.x;
							obj1.x = obj2.x;
							obj2.x = tmp;
							swapChildrenAt(i + j1, i);
						}
						
						renderItems(0, j1);
					}
					else
					{
						j1 = newFirstIndex - oldFirstIndex;
						j2 = _viewCount - j1;
						for (i = 0; i < j2; i++)
						{
							obj1 = getChildAt(i);
							obj2 = getChildAt(i + j1);
							if (obj1 is GButton)
								GButton(obj1).selected = false;
							tmp = obj1.x;
							obj1.x = obj2.x;
							obj2.x = tmp;
							swapChildrenAt(i + j1, i);
						}
						
						renderItems(j2, _viewCount);
					}
				}
				
				if (this.childrenRenderOrder == ChildrenRenderOrder.Arch)
				{
					mid = this.scrollPane.posX + this.viewWidth / 2;
					minDist = int.MAX_VALUE;
					apexIndex = 0;
					for (i = 0; i < _viewCount; i++)
					{
						obj = getChildAt(i);
						if (obj.visible)
						{
							dist = Math.abs(mid - obj.x - obj.width / 2);
							if (dist < minDist)
							{
								minDist = dist;
								apexIndex = i;
							}
						}
					}
					this.apexIndex = apexIndex;
				}
			}
			
			_boundsChanged = false;
		}
		
		override protected function updateBounds():void
		{
			var cnt:int = _children.length;
			var i:int;
			var child:GObject;
			var curX:int;
			var curY:int;
			var maxWidth:int;
			var maxHeight:int;
			var cw:int, ch:int;
			
			for(i=0;i<cnt;i++)
			{
				child = getChildAt(i);
				child.ensureSizeCorrect();
			}
			
			if(_layout==ListLayoutType.SingleColumn)
			{
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					if (!child.visible)
						continue;
					
					if (curY != 0)
						curY += _lineGap;
					child.y = curY;
					curY += child.height;
					if(child.width>maxWidth)
						maxWidth = child.width;
				}
				cw = curX+maxWidth;
				ch = curY;
			}
			else if(_layout==ListLayoutType.SingleRow)
			{
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					if (!child.visible)
						continue;
					
					if(curX!=0)
						curX += _columnGap;
					child.x = curX;
					curX += child.width;
					if(child.height>maxHeight)
						maxHeight = child.height;
				}
				cw = curX;
				ch = curY+maxHeight;
			}
			else if(_layout==ListLayoutType.FlowHorizontal)
			{
				var j:int = 0;
				var viewWidth:Number = this.viewWidth;
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					if (!child.visible)
						continue;
					
					if(curX!=0)
						curX += _columnGap;
					
					if (_lineItemCount != 0 && j >= _lineItemCount
						|| _lineItemCount == 0 && curX + child.width > viewWidth && maxHeight != 0)
					{
						//new line
						curX -= _columnGap;
						if (curX > maxWidth)
							maxWidth = curX;
						curX = 0;
						curY += maxHeight + _lineGap;
						maxHeight = 0;
						j = 0;
					}
					child.setXY(curX, curY);
					curX += child.width;
					if (child.height > maxHeight)
						maxHeight = child.height;
					j++;
				}
				ch = curY + maxHeight;
				cw = maxWidth;
			}
			else
			{
				j = 0;
				var viewHeight:Number = this.viewHeight;
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					if (!child.visible)
						continue;
					
					if(curY!=0)
						curY += _lineGap;
					
					if (_lineItemCount != 0 && j >= _lineItemCount
						|| _lineItemCount == 0 && curY + child.height > viewHeight && maxWidth != 0)
					{
						curY -= _lineGap;
						if (curY > maxHeight)
							maxHeight = curY;
						curY = 0;
						curX += maxWidth + _columnGap;
						maxWidth = 0;
						j = 0;
					}
					child.setXY(curX, curY);
					curY += child.height;
					if (child.width > maxWidth)
						maxWidth = child.width;
					j++;
				}
				cw = curX + maxWidth;
				ch = maxHeight;
			}
			setBounds(0,0,cw,ch);
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String;
			str = xml.@layout;
			if(str)
				_layout = ListLayoutType.parse(str);

			var overflow:int;
			str = xml.@overflow;
			if(str)
				overflow = OverflowType.parse(str);
			else
				overflow = OverflowType.Visible;
			
			str = xml.@margin;
			if(str)
				_margin.parse(str);
			
			if(overflow==OverflowType.Scroll)
			{
				var scroll:int;
				str = xml.@scroll;
				if(str)
					scroll = ScrollType.parse(str);
				else
					scroll = ScrollType.Vertical;
	
				var scrollBarDisplay:int;
				str = xml.@scrollBar;
				if(str)
					scrollBarDisplay = ScrollBarDisplayType.parse(str);
				else
					scrollBarDisplay = ScrollBarDisplayType.Default;
				var scrollBarFlags:int = parseInt(xml.@scrollBarFlags);
				
				var scrollBarMargin:Margin = new Margin();
				str = xml.@scrollBarMargin;
				if(str)
					scrollBarMargin.parse(str);
				
				var vtScrollBarRes:String;
				var hzScrollBarRes:String;
				str = xml.@scrollBarRes;
				if(str)
				{
					var arr:Array = str.split(",");
					vtScrollBarRes = arr[0];
					hzScrollBarRes = arr[1];
				}
				
				setupScroll(scrollBarMargin, scroll, scrollBarDisplay, scrollBarFlags, 
					vtScrollBarRes, hzScrollBarRes);
			}
			else
				setupOverflow(overflow);
			
			str = xml.@lineGap;
			if(str)
				_lineGap = parseInt(str);
			
			str = xml.@colGap;
			if(str)
				_columnGap = parseInt(str);
			
			str = xml.@lineItemCount;
			if(str)
				_lineItemCount = parseInt(str);
			
			str = xml.@selectionMode;
			if(str)
				_selectionMode = ListSelectionMode.parse(str);
			
			str = xml.@defaultItem;
			if(str)
				_defaultItem = str;
			
			str = xml.@autoItemSize;
			_autoResizeItem = str!="false";
			
			var col:XMLList = xml.item;
			for each(var cxml:XML in col)
			{
				var url:String = cxml.@url;
				if(!url)
					url = _defaultItem;
				if(!url)
					continue;
				
				var obj:GObject = getFromPool(url);
				if(obj!=null)
				{
					addChild(obj);
					if(obj is GButton)
					{
						GButton(obj).title = String(cxml.@title);
						GButton(obj).icon = String(cxml.@icon);
					}
					else if(obj is GLabel)
					{
						GLabel(obj).title = String(cxml.@title);
						GLabel(obj).icon = String(cxml.@icon);
					}
				}
			}
		}
	}
}
