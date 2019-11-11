package fairygui
{
	import fairygui.display.UIDisplayObject;
	import fairygui.event.GTouchEvent;
	import fairygui.event.ItemEvent;
	import fairygui.utils.GTimers;

	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	[Event(name = "itemClick", type = "fairygui.event.ItemEvent")]
	public class GList extends GComponent
	{
		/**
		 * itemRenderer(index:int, item:GObject):void;
		 */
		public var itemRenderer:Function;
		/**
		 * itemProvider(index:int):String;
		 */
		public var itemProvider:Function;

		public var scrollItemToViewOnClick:Boolean;
		public var foldInvisibleItems:Boolean;
		
		private var _layout:int;
		private var _lineCount:int;
		private var _columnCount:int;
		private var _lineGap:int;
		private var _columnGap:int;
		private var _defaultItem:String;
		private var _autoResizeItem:Boolean;
		private var _selectionMode:int;
		private var _align:int;
		private var _verticalAlign:int;
		private var _selectionController:Controller;
		
		private var _lastSelectedIndex:int;
		private var _pool:GObjectPool;
		
		//Virtual List support
		private var _virtual:Boolean;
		private var _loop:Boolean;
		private var _numItems:int;
		private var _realNumItems:int;
		private var _firstIndex:int; //the top left index
		private var _curLineItemCount:int; //item count in one line
		private var _curLineItemCount2:int; //只用在页面模式，表示垂直方向的项目数
		private var _itemSize:Point;
		private var _virtualListChanged:int; //1-content changed, 2-size changed
		private var _eventLocked:Boolean;
		private var _virtualItems:Vector.<ItemInfo>;
		private var itemInfoVer:uint = 0; //用来标志item是否在本次处理中已经被重用了
		
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
			_align = AlignType.Left;
			_verticalAlign = VertAlignType.Top;
			
			_container = new Sprite();
			_rootContainer.addChild(_container);
		}
		
		public override function dispose():void
		{
			_pool.clear();
			scrollItemToViewOnClick = false;
			
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
		
		final public function get lineCount():int
		{
			return _lineCount;
		}
		
		final public function set lineCount(value:int):void
		{
			if (_lineCount != value)
			{
				_lineCount = value;
				if (_layout == ListLayoutType.FlowVertical || _layout == ListLayoutType.Pagination)
				{
					setBoundsChangedFlag();
					if (_virtual)
						setVirtualListChangedFlag(true);
				}
			}
		}
		
		final public function get columnCount():int
		{
			return _columnCount;
		}
		
		final public function set columnCount(value:int):void
		{
			if (_columnCount != value)
			{
				_columnCount = value;
				if (_layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination)
				{
					setBoundsChangedFlag();
					if (_virtual)
						setVirtualListChangedFlag(true);
				}
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
		
		public function get align():int
		{
			return _align;
		}
		
		public function set align(value:int):void
		{
			if(_align!=value)
			{
				_align = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}
		
		final public function get verticalAlign():int
		{
			return _verticalAlign;
		}
		
		public function set verticalAlign(value:int):void
		{
			if(_verticalAlign!=value)
			{
				_verticalAlign = value;
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
			if(_autoResizeItem != value)
			{
				_autoResizeItem = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}
		
		final public function get selectionMode():int
		{
			return _selectionMode;
		}
		
		final public function set selectionMode(value:int):void
		{
			_selectionMode = value;
		}
		
		final public function get selectionController():Controller
		{
			return _selectionController;
		}
		
		final public function set selectionController(value:Controller):void
		{
			_selectionController = value;
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
			super.addChildAt(child, index);
			
			if((child is GButton) && _selectionMode!=ListSelectionMode.None)
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
			var i:int;
			if (_virtual)
			{
				for (i = 0; i < _realNumItems; i++)
				{
					var ii:ItemInfo = _virtualItems[i];
					if ((ii.obj is GButton) && GButton(ii.obj).selected
						|| ii.obj == null && ii.selected)
					{
						if (_loop)
							return i % _numItems;
						else
							return i;
					}
				}
			}
			else
			{
				var cnt:int = _children.length;
				for (i = 0; i < cnt; i++)
				{
					var obj:GButton = _children[i].asButton;
					if (obj != null && obj.selected)
						return i;
				}
			}
			
			return -1;
		}
		
		public function set selectedIndex(value:int):void
		{
			if (value >= 0 && value < this.numItems)
			{
				if(_selectionMode!=ListSelectionMode.Single)
					clearSelection();
				addSelection(value);
			}
			else
				clearSelection();
		}
		
		public function getSelection(result:Vector.<int>=null):Vector.<int>
		{
			if(result==null)
				result = new Vector.<int>();
			var i:int;
			if (_virtual)
			{
				for (i = 0; i < _realNumItems; i++)
				{
					var ii:ItemInfo = _virtualItems[i];
					if ((ii.obj is GButton) && GButton(ii.obj).selected
						|| ii.obj == null && ii.selected)
					{
						if (_loop)
						{
							var j:int = i % _numItems;
							if (result.indexOf(j)!=-1)
								continue;
						}
						result.push(i);
					}
				}
			}
			else
			{
				var cnt:int = _children.length;
				for (i = 0; i < cnt; i++)
				{
					var obj:GButton = _children[i].asButton;
					if (obj != null && obj.selected)
						result.push(i);
				}
			}
			return result;
		}
		
		public function addSelection(index:int, scrollItToView:Boolean=false):void
		{
			if(_selectionMode==ListSelectionMode.None)
				return;
			
			checkVirtualList();
			
			if(_selectionMode==ListSelectionMode.Single)
				clearSelection();

			if (scrollItToView)
				scrollToView(index);
			
			_lastSelectedIndex = index;
			var obj:GButton = null;
			if (_virtual)
			{
				var ii:ItemInfo = _virtualItems[index];
				if (ii.obj != null)
					obj = ii.obj.asButton;
				ii.selected = true;
			}
			else
				obj = getChildAt(index).asButton;
			
			if (obj != null && !obj.selected)
			{
				obj.selected = true;
				updateSelectionController(index);
			}
		}
		
		public function removeSelection(index:int):void
		{
			if(_selectionMode==ListSelectionMode.None)
				return;
			
			var obj:GButton = null;
			if (_virtual)
			{
				var ii:ItemInfo = _virtualItems[index];
				if (ii.obj != null)
					obj = ii.obj.asButton;
				ii.selected = false;
			}
			else
				obj = getChildAt(index).asButton;
			
			if (obj != null)
				obj.selected = false;
		}
		
		public function clearSelection():void
		{
			var i:int;
			if (_virtual)
			{
				for (i = 0; i < _realNumItems; i++)
				{
					var ii:ItemInfo = _virtualItems[i];
					if (ii.obj is GButton)
						GButton(ii.obj).selected = false;
					ii.selected = false;
				}
			}
			else
			{
				var cnt:int = _children.length;
				for (i = 0; i < cnt; i++)
				{
					var obj:GButton = _children[i].asButton;
					if (obj != null)
						obj.selected = false;
				}
			}
		}
		
		private function clearSelectionExcept(g:GObject):void
		{
			var i:int;
			if (_virtual)
			{
				for (i = 0; i < _realNumItems; i++)
				{
					var ii:ItemInfo = _virtualItems[i];
					if (ii.obj != g)
					{
						if ((ii.obj is GButton))
							GButton(ii.obj).selected = false;
						ii.selected = false;
					}
				}
			}
			else
			{
				var cnt:int = _children.length;
				for (i = 0; i < cnt; i++)
				{
					var obj:GButton = _children[i].asButton;
					if (obj != null && obj != g)
						obj.selected = false;
				}
			}
		}
			
		public function selectAll():void
		{
			checkVirtualList();
			
			var last:int = -1;
			var i:int;
			if (_virtual)
			{
				for (i = 0; i < _realNumItems; i++)
				{
					var ii:ItemInfo = _virtualItems[i];
					if ((ii.obj is GButton) && !GButton(ii.obj).selected)
					{
						GButton(ii.obj).selected = true;
						last = i;
					}
					ii.selected = true;
				}
			}
			else
			{
				var cnt:int = _children.length;
				for (i = 0; i < cnt; i++)
				{
					var obj:GButton = _children[i].asButton;
					if (obj != null && !obj.selected)
					{
						obj.selected = true;
						last = i;
					}
				}
			}
			
			if(last!=-1)
				updateSelectionController(last);
		}
		
		public function selectNone():void
		{
			clearSelection();
		}
		
		public function selectReverse():void
		{
			checkVirtualList();
			
			var last:int = -1;
			var i:int;
			if (_virtual)
			{
				for (i = 0; i < _realNumItems; i++)
				{
					var ii:ItemInfo = _virtualItems[i];
					if (ii.obj is GButton)
					{
						GButton(ii.obj).selected = !GButton(ii.obj).selected;
						if (GButton(ii.obj).selected)
							last = i;
					}
					ii.selected = !ii.selected;
				}
			}
			else
			{
				var cnt:int = _children.length;
				for (i = 0; i < cnt; i++)
				{
					var obj:GButton = _children[i].asButton;
					if (obj != null)
					{
						obj.selected = !obj.selected;
						if (obj.selected)
							last = i;
					}
				}
			}
			
			if(last!=-1)
				updateSelectionController(last);
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
					else if (_layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination)
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
					if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination)
					{
						index++;
						if(index<this.numItems)
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
						if(index<this.numItems)
						{
							clearSelection();
							addSelection(index, true);
						}
					}
					else if (_layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination)
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
					if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination)
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
			if (this._scrollPane != null && this._scrollPane.isDragged)
				return;
			
			var item:GObject = GObject(evt.currentTarget);
			setSelectionOnEvent(item);
			
			if (_scrollPane != null && scrollItemToViewOnClick)
				_scrollPane.scrollToView(item, true);
			
			var ie:ItemEvent = new ItemEvent(ItemEvent.CLICK, item);
			ie.stageX = evt.stageX;
			ie.stageY = evt.stageY;
			ie.clickCount = evt.clickCount;
			dispatchItemEvent(ie);
		}

		protected function dispatchItemEvent(evt:ItemEvent):void
		{
			this.dispatchEvent(evt);
		}
		
		private function __rightClickItem(evt:MouseEvent):void
		{
			var item:GObject = GObject(evt.currentTarget);
			if((item is GButton) && !GButton(item).selected)
				setSelectionOnEvent(item);
			
			if (_scrollPane != null && scrollItemToViewOnClick)
				_scrollPane.scrollToView(item, true);
			
			var ie:ItemEvent = new ItemEvent(ItemEvent.CLICK, item);
			ie.stageX = evt.stageX;
			ie.stageY = evt.stageY;
			ie.rightButton = true;
			dispatchItemEvent(ie);
		}
		
		private function setSelectionOnEvent(item:GObject):void
		{
			if(!(item is GButton) || _selectionMode==ListSelectionMode.None)
				return;
			
			var dontChangeLastIndex:Boolean = false;
			var button:GButton = GButton(item);
			var index:int = childIndexToItemIndex(getChildIndex(item));
			
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
							max = Math.min(max, this.numItems-1);
							var i:int;
							if (_virtual)
							{
								for (i = min; i <= max; i++)
								{
									var ii:ItemInfo = _virtualItems[i];
									if (ii.obj is GButton)
										GButton(ii.obj).selected = true;
									ii.selected = true;
								}
							}
							else
							{
								for(i=min;i<=max;i++)
								{
									var obj:GButton = getChildAt(i).asButton;
									if(obj!=null)
										obj.selected = true;
								}
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
			
			if(button.selected)
				updateSelectionController(index);
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
					if (!foldInvisibleItems || obj.visible)
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
			
			setBoundsChangedFlag();
			if (_virtual)
				setVirtualListChangedFlag(true);
		}
		
		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			
			if (_selectionController == c)
				this.selectedIndex = c.selectedIndex;
		}
		
		private function updateSelectionController(index:int):void
		{
			if (_selectionController != null && !_selectionController.changing
				&& index < _selectionController.pageCount)
			{
				var c:Controller = _selectionController;
				_selectionController = null;
				c.selectedIndex = index;
				_selectionController = c;
			}
		}

		override public function getSnappingPosition(xValue:Number, yValue:Number, resultPoint:Point=null):Point
		{
			if (_virtual)
			{
				if(!resultPoint)
					resultPoint = new Point();
				
				var saved:Number;
				var index:int;
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					saved = yValue;
					GList.pos_param = yValue;
					index = getIndexOnPos1(false);
					yValue = GList.pos_param;
					if (index < _virtualItems.length && saved - yValue > _virtualItems[index].height / 2 && index < _realNumItems)
						yValue += _virtualItems[index].height + _lineGap;
				}
				else if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowVertical)
				{
					saved = xValue;
					GList.pos_param = xValue;
					index = getIndexOnPos2(false);
					xValue = GList.pos_param;
					if (index < _virtualItems.length && saved - xValue > _virtualItems[index].width / 2 && index < _realNumItems)
						xValue += _virtualItems[index].width + _columnGap;
				}
				else
				{
					saved = xValue;
					GList.pos_param = xValue;
					index = getIndexOnPos3(false);
					xValue = GList.pos_param;
					if (index < _virtualItems.length && saved - xValue > _virtualItems[index].width / 2 && index < _realNumItems)
						xValue += _virtualItems[index].width + _columnGap;
				}
				
				resultPoint.x = xValue;
				resultPoint.y = yValue;
				return resultPoint;
			}
			else
				return super.getSnappingPosition(xValue, yValue, resultPoint);
		}
		
		public function scrollToView(index:int, ani:Boolean=false, setFirst:Boolean=false):void
		{
			if (_virtual)
			{
				if(_numItems==0)
					return;
				
				checkVirtualList();
				
				if (index >= _virtualItems.length)
					throw new Error("Invalid child index: " + index + ">" + _virtualItems.length);
				
				if(_loop)
					index = Math.floor(_firstIndex/_numItems)*_numItems+index;
				
				var rect:Rectangle;
				var ii:ItemInfo = _virtualItems[index];
				var pos:Number = 0;
				var i:int;
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					for (i = _curLineItemCount-1; i < index; i += _curLineItemCount)
						pos += _virtualItems[i].height + _lineGap;
					rect = new Rectangle(0, pos, _itemSize.x, ii.height);
				}
				else if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowVertical)
				{
					for (i = _curLineItemCount-1; i < index; i += _curLineItemCount)
						pos += _virtualItems[i].width + _columnGap;
					rect = new Rectangle(pos, 0, ii.width, _itemSize.y);
				}
				else
				{
					var page:int = index / (_curLineItemCount * _curLineItemCount2);
					rect = new Rectangle(page * viewWidth + (index % _curLineItemCount) * (ii.width + _columnGap),
						(index / _curLineItemCount) % _curLineItemCount2 * (ii.height + _lineGap),
						ii.width, ii.height);
				}
				
				if(this.itemProvider!=null)
					setFirst = true;//因为在可变item大小的情况下，只有设置在最顶端，位置才不会因为高度变化而改变，所以只能支持setFirst=true
				if (_scrollPane != null)
					_scrollPane.scrollToView(rect, ani, setFirst);
			}
			else
			{
				var obj:GObject = getChildAt(index);
				if (_scrollPane != null)
					_scrollPane.scrollToView(obj, ani, setFirst);
				else if (parent != null && parent.scrollPane != null)
					parent.scrollPane.scrollToView(obj, ani, setFirst);
			}
		}
		
		override public function getFirstChildInView():int
		{
			return childIndexToItemIndex(super.getFirstChildInView());
		}
		
		public function childIndexToItemIndex(index:int):int
		{
			if (!_virtual)
				return index;
			
			if (_layout == ListLayoutType.Pagination)
			{
				for (var i:int = _firstIndex; i < _realNumItems; i++)
				{
					if (_virtualItems[i].obj != null)
					{
						index--;
						if (index < 0)
							return i;
					}
				}
				
				return index;
			}
			else
			{
				index += _firstIndex;
				if (_loop && _numItems > 0)
					index = index % _numItems;
				
				return index;
			}
		}
		
		public function itemIndexToChildIndex(index:int):int
		{
			if (!_virtual)
				return index;
			
			if (_layout == ListLayoutType.Pagination)
			{
				return getChildIndex(_virtualItems[index].obj);
			}
			else
			{
				if (_loop && _numItems > 0)
				{
					var j:int = _firstIndex % _numItems;
					if (index >= j)
						index = index - j;
					else
						index = _numItems - j + index;
				}
				else
					index -= _firstIndex;
				
				return index;
			}
		}
		
		public function setVirtual():void
		{
			_setVirtual(false);
		}
	
		public function setVirtualAndLoop():void
		{
			_setVirtual(true);
		}

		private function _setVirtual(loop:Boolean):void
		{
			if (!_virtual)
			{
				if (_scrollPane == null)
					throw new Error("FairyGUI: Virtual list must be scrollable!");
				
				if (loop)
				{
					if (_layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.FlowVertical)
						throw new Error("FairyGUI: Loop list is not supported for FlowHorizontal or FlowVertical layout!");
					
					_scrollPane.bouncebackEffect = false;
				}
				
				_virtual = true;
				_loop = loop;
				_virtualItems = new Vector.<ItemInfo>();
				removeChildrenToPool();
				
				if(_itemSize==null)
				{
					_itemSize = new Point();
					var obj:GObject = getFromPool(null);
					if (obj == null)
					{
						throw new Error("FairyGUI: Virtual List must have a default list item resource.");
						_itemSize.x = 100;
						_itemSize.y = 100;
					}
					else
					{
						_itemSize.x = obj.width;
						_itemSize.y = obj.height;
						returnToPool(obj);
					}
				}
				
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					_scrollPane.scrollStep = _itemSize.y;
					if(_loop)
						this._scrollPane._loop = 2;
				}
				else
				{
					_scrollPane.scrollStep = _itemSize.x;
					if(_loop)
						this._scrollPane._loop = 1;
				}
				
				_scrollPane.addEventListener(Event.SCROLL, __scrolled);
				setVirtualListChangedFlag(true);
			}
		}
		
		public function get numItems():int
		{
			if (_virtual)
				return _numItems;
			else
				return _children.length;
		}
		
		public function set numItems(value:int):void
		{
			var i:int;
			
			if (_virtual)
			{
				if (itemRenderer == null)
					throw new Error("FairyGUI: Set itemRenderer first!");
				
				_numItems = value;
				if (_loop)
					_realNumItems = _numItems * 6;//设置6倍数量，用于循环滚动
				else
					_realNumItems = _numItems;
				
				//_virtualItems的设计是只增不减的
				var oldCount:int = _virtualItems.length;
				if (_realNumItems > oldCount)
				{
					for (i = oldCount; i < _realNumItems; i++)
					{
						var ii:ItemInfo = new ItemInfo();
						ii.width = _itemSize.x;
						ii.height = _itemSize.y;
						
						_virtualItems.push(ii);
					}
				}
				else
				{
					for (i = _realNumItems; i < oldCount; i++)
						_virtualItems[i].selected = false;
				}
				
				if (this._virtualListChanged != 0)
					GTimers.inst.remove(_refreshVirtualList);
				
				//立即刷新
				_refreshVirtualList();
			}
			else
			{
				var cnt:int = _children.length;
				if (value > cnt)
				{
					for (i = cnt; i < value; i++)
					{
						if (itemProvider == null)
							addItemFromPool();
						else
							addItemFromPool(itemProvider(i));
					}
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
		
		public function refreshVirtualList():void
		{
			setVirtualListChangedFlag(false);
		}
		
		private function checkVirtualList():void
		{
			if(this._virtualListChanged!=0) { 
				this._refreshVirtualList();
				GTimers.inst.remove(_refreshVirtualList);
			}
		}
		
		private function setVirtualListChangedFlag(layoutChanged:Boolean=false):void
		{
			if (layoutChanged)
				_virtualListChanged = 2;
			else if (_virtualListChanged == 0)
				_virtualListChanged = 1;
			
			GTimers.inst.callLater(_refreshVirtualList);
		}
		
		private function _refreshVirtualList():void
		{
			var layoutChanged:Boolean = _virtualListChanged == 2;
			_virtualListChanged = 0;
			_eventLocked = true;
			
			if (layoutChanged)
			{
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.SingleRow)
					_curLineItemCount = 1;
				else if (_layout == ListLayoutType.FlowHorizontal)
				{
					if (_columnCount > 0)
						_curLineItemCount = _columnCount;
					else
					{
						_curLineItemCount = Math.floor((_scrollPane.viewWidth + _columnGap) / (_itemSize.x + _columnGap));
						if (_curLineItemCount <= 0)
							_curLineItemCount = 1;
					}
				}
				else if (_layout == ListLayoutType.FlowVertical)
				{
					if (_lineCount > 0)
						_curLineItemCount = _lineCount;
					else
					{
						_curLineItemCount = Math.floor((_scrollPane.viewHeight + _lineGap) / (_itemSize.y + _lineGap));
						if (_curLineItemCount <= 0)
							_curLineItemCount = 1;
					}
				}
				else //pagination
				{
					if (_columnCount > 0)
						_curLineItemCount = _columnCount;
					else
					{
						_curLineItemCount = Math.floor((_scrollPane.viewWidth + _columnGap) / (_itemSize.x + _columnGap));
						if (_curLineItemCount <= 0)
							_curLineItemCount = 1;
					}
					
					if (_lineCount > 0)
						_curLineItemCount2 = _lineCount;
					else
					{
						_curLineItemCount2 = Math.floor((_scrollPane.viewHeight + _lineGap) / (_itemSize.y + _lineGap));
						if (_curLineItemCount2 <= 0)
							_curLineItemCount2 = 1;
					}
				}
			}
			
			var ch:Number = 0, cw:Number = 0;
			if (_realNumItems > 0)
			{
				var i:int;
				var len:int = Math.ceil(_realNumItems / _curLineItemCount) * _curLineItemCount;
				var len2:int = Math.min(_curLineItemCount, _realNumItems);
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					for (i = 0; i < len; i += _curLineItemCount)
						ch += _virtualItems[i].height + _lineGap;
					if (ch > 0)
						ch -= _lineGap;
					
					if (_autoResizeItem)
						cw = _scrollPane.viewWidth;
					else
					{
						for (i = 0; i < len2; i++)
							cw += _virtualItems[i].width + _columnGap;
						if (cw > 0)
							cw -= _columnGap;
					}
				}
				else if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowVertical)
				{
					for (i = 0; i < len; i += _curLineItemCount)
						cw += _virtualItems[i].width + _columnGap;
					if (cw > 0)
						cw -= _columnGap;
					
					if (_autoResizeItem)
						ch = _scrollPane.viewHeight;
					else
					{
						for (i = 0; i < len2; i++)
							ch += _virtualItems[i].height + _lineGap;
						if (ch > 0)
							ch -= _lineGap;
					}
				}
				else
				{
					var pageCount:int = Math.ceil(len / (_curLineItemCount * _curLineItemCount2));
					cw = pageCount * viewWidth;
					ch = viewHeight;
				}
			}

			handleAlign(cw, ch);
			_scrollPane.setContentSize(cw, ch);
			
			_eventLocked = false;
			
			handleScroll(true);
		}
		
		private function __scrolled(evt:Event):void
		{
			handleScroll(false);
		}

		private function getIndexOnPos1(forceUpdate:Boolean):int
		{
			if (_realNumItems < _curLineItemCount)
			{
				pos_param = 0;
				return 0;
			}
			
			var i:int;
			var pos2:Number;
			var pos3:Number;
			
			if (numChildren > 0 && !forceUpdate)
			{
				pos2 = this.getChildAt(0).y;
				if (pos2 > pos_param)
				{
					for (i = _firstIndex - _curLineItemCount; i >= 0; i -= _curLineItemCount)
					{
						pos2 -= (_virtualItems[i].height + _lineGap);
						if (pos2 <= pos_param)
						{
							pos_param = pos2;
							return i;
						}
					}
					
					pos_param = 0;
					return 0;
				}
				else
				{
					for (i = _firstIndex; i < _realNumItems; i += _curLineItemCount)
					{
						pos3 = pos2 + _virtualItems[i].height + _lineGap;
						if (pos3 > pos_param)
						{
							pos_param = pos2;
							return i;
						}
						pos2 = pos3;
					}
					
					pos_param = pos2;
					return _realNumItems - _curLineItemCount;
				}
			}
			else
			{
				pos2 = 0;
				for (i = 0; i < _realNumItems; i += _curLineItemCount)
				{
					pos3 = pos2 + _virtualItems[i].height + _lineGap;
					if (pos3 > pos_param)
					{
						pos_param = pos2;
						return i;
					}
					pos2 = pos3;
				}
				
				pos_param = pos2;
				return _realNumItems - _curLineItemCount;
			}
		}
		
		private function getIndexOnPos2(forceUpdate:Boolean):int
		{
			if (_realNumItems < _curLineItemCount)
			{
				pos_param = 0;
				return 0;
			}
			
			var i:int;
			var pos2:Number;
			var pos3:Number;
			
			if (numChildren > 0 && !forceUpdate)
			{
				pos2 = this.getChildAt(0).x;
				if (pos2 > pos_param)
				{
					for (i = _firstIndex - _curLineItemCount; i >= 0; i -= _curLineItemCount)
					{
						pos2 -= (_virtualItems[i].width + _columnGap);
						if (pos2 <= pos_param)
						{
							pos_param = pos2;
							return i;
						}
					}
					
					pos_param = 0;
					return 0;
				}
				else
				{
					for (i = _firstIndex; i < _realNumItems; i += _curLineItemCount)
					{
						pos3 = pos2 + _virtualItems[i].width + _columnGap;
						if (pos3 > pos_param)
						{
							pos_param = pos2;
							return i;
						}
						pos2 = pos3;
					}
					
					pos_param = pos2;
					return _realNumItems - _curLineItemCount;
				}
			}
			else
			{
				pos2 = 0;
				for (i = 0; i < _realNumItems; i += _curLineItemCount)
				{
					pos3 = pos2 + _virtualItems[i].width + _columnGap;
					if (pos3 > pos_param)
					{
						pos_param = pos2;
						return i;
					}
					pos2 = pos3;
				}
				
				pos_param = pos2;
				return _realNumItems - _curLineItemCount;
			}
		}
		
		private function getIndexOnPos3(forceUpdate:Boolean):int
		{
			if (_realNumItems < _curLineItemCount)
			{
				pos_param = 0;
				return 0;
			}
			
			var viewWidth:Number = this.viewWidth;
			var page:int = Math.floor(pos_param / viewWidth);
			var startIndex:int = page * (_curLineItemCount * _curLineItemCount2);
			var pos2:Number = page * viewWidth;
			var i:int;
			var pos3:Number;
			for (i = 0; i < _curLineItemCount; i++)
			{
				pos3 = pos2 + _virtualItems[startIndex + i].width + _columnGap;
				if (pos3 > pos_param)
				{
					pos_param = pos2;
					return startIndex + i;
				}
				pos2 = pos3;
			}
			
			pos_param = pos2;
			return startIndex + _curLineItemCount - 1;
		}
		
		private function handleScroll(forceUpdate:Boolean):void
		{
			if (_eventLocked)
				return;

			if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
			{
				var enterCounter:int = 0;
				while(handleScroll1(forceUpdate))
				{
					enterCounter++;
					forceUpdate = false;
					if(enterCounter>20)
					{
						trace("FairyGUI: list will never be filled as the item renderer function always returns a different size.");
						break;
					}
				}
				handleArchOrder1();
			}
			else if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowVertical)
			{
				enterCounter = 0;
				while(handleScroll2(forceUpdate))
				{
					enterCounter++;
					forceUpdate = false;
					if(enterCounter>20)
					{
						trace("FairyGUI: list will never be filled as the item renderer function always returns a different size.");
						break;
					}
				}
				handleArchOrder2();
			}
			else
			{
				handleScroll3(forceUpdate);
			}
			
			_boundsChanged = false;
		}
		
		private static var pos_param:Number;
		
		private function handleScroll1(forceUpdate:Boolean):Boolean
		{
			var pos:Number = _scrollPane.scrollingPosY;
			var max:Number = pos + _scrollPane.viewHeight;
			var end:Boolean = max == _scrollPane.contentHeight;//这个标志表示当前需要滚动到最末，无论内容变化大小
			
			//寻找当前位置的第一条项目
			GList.pos_param = pos;
			var newFirstIndex:int = getIndexOnPos1(forceUpdate);
			pos = GList.pos_param;
			if (newFirstIndex == _firstIndex && !forceUpdate)
				return false;

			var oldFirstIndex:int = _firstIndex;
			_firstIndex = newFirstIndex;
			var curIndex:int = newFirstIndex;
			var forward:Boolean = oldFirstIndex > newFirstIndex;
			var childCount:int = this.numChildren;
			var lastIndex:int = oldFirstIndex + childCount - 1;
			var reuseIndex:int = forward ? lastIndex : oldFirstIndex;
			var curX:Number = 0, curY:Number = pos;
			var needRender:Boolean;
			var deltaSize:Number = 0;
			var firstItemDeltaSize:Number = 0;
			var url:String = defaultItem;
			var ii:ItemInfo, ii2:ItemInfo;
			var i:int,j:int;
			var partSize:int = (_scrollPane.viewWidth - _columnGap * (_curLineItemCount - 1)) / _curLineItemCount;

			itemInfoVer++;
			
			while (curIndex < _realNumItems && (end || curY < max))
			{
				ii = _virtualItems[curIndex];
				
				if (ii.obj == null || forceUpdate)
				{
					if (itemProvider != null)
					{
						url = itemProvider(curIndex % _numItems);
						if (url == null)
							url = _defaultItem;
						url = UIPackage.normalizeURL(url);
					}
					
					if (ii.obj != null && ii.obj.resourceURL != url)
					{
						if (ii.obj is GButton)
							ii.selected = GButton(ii.obj).selected;
						removeChildToPool(ii.obj);
						ii.obj = null;
					}
				}
				
				if (ii.obj == null)
				{
					//搜索最适合的重用item，保证每次刷新需要新建或者重新render的item最少
					if (forward)
					{
						for (j = reuseIndex; j >= oldFirstIndex; j--)
						{
							ii2 = _virtualItems[j];
							if (ii2.obj != null && ii2.updateFlag != itemInfoVer && ii2.obj.resourceURL == url)
							{
								if (ii2.obj is GButton)
									ii2.selected = GButton(ii2.obj).selected;
								ii.obj = ii2.obj;
								ii2.obj = null;
								if (j == reuseIndex)
									reuseIndex--;
								break;
							}
						}
					}
					else
					{
						for (j = reuseIndex; j <= lastIndex; j++)
						{
							ii2 = _virtualItems[j];
							if (ii2.obj != null && ii2.updateFlag != itemInfoVer && ii2.obj.resourceURL == url)
							{
								if (ii2.obj is GButton)
									ii2.selected = GButton(ii2.obj).selected;
								ii.obj = ii2.obj;
								ii2.obj = null;
								if (j == reuseIndex)
									reuseIndex++;
								break;
							}
						}
					}
					
					if (ii.obj != null)
					{
						setChildIndex(ii.obj, forward ? curIndex - newFirstIndex : numChildren);
					}
					else
					{
						ii.obj = _pool.getObject(url);
						if (forward)
							this.addChildAt(ii.obj, curIndex - newFirstIndex);
						else
							this.addChild(ii.obj);
					}
					if (ii.obj is GButton)
						GButton(ii.obj).selected = ii.selected;
					
					needRender = true;
				}
				else
					needRender = forceUpdate;
				
				if (needRender)
				{
					if (_autoResizeItem && (_layout == ListLayoutType.SingleColumn || _columnCount > 0))
						ii.obj.setSize(partSize, ii.obj.height, true);

					itemRenderer(curIndex % _numItems, ii.obj);
					if (curIndex % _curLineItemCount == 0)
					{
						deltaSize += Math.ceil(ii.obj.height) - ii.height;
						if (curIndex == newFirstIndex && oldFirstIndex > newFirstIndex)
						{
							//当内容向下滚动时，如果新出现的项目大小发生变化，需要做一个位置补偿，才不会导致滚动跳动
							firstItemDeltaSize = Math.ceil(ii.obj.height) - ii.height;
						}
					}
					ii.width = Math.ceil(ii.obj.width);
					ii.height = Math.ceil(ii.obj.height);
				}
				
				ii.updateFlag = itemInfoVer;
				ii.obj.setXY(curX, curY);
				if (curIndex == newFirstIndex) //要显示多一条才不会穿帮
					max += ii.height;
				
				curX += ii.width + _columnGap;
				
				if (curIndex % _curLineItemCount == _curLineItemCount - 1)
				{
					curX = 0;
					curY += ii.height + _lineGap;
				}
				curIndex++;
			}
			
			for (i = 0; i < childCount; i++)
			{
				ii = _virtualItems[oldFirstIndex + i];
				if (ii.updateFlag != itemInfoVer && ii.obj != null)
				{
					if (ii.obj is GButton)
						ii.selected = GButton(ii.obj).selected;
					removeChildToPool(ii.obj);
					ii.obj = null;
				}
			}
			
			childCount = _children.length;
			for (i = 0; i < childCount; i++)
			{
				var obj:GObject = _virtualItems[newFirstIndex + i].obj;
				if (_children[i] != obj)
					setChildIndex(obj, i);
			}
			
			if (deltaSize != 0 || firstItemDeltaSize != 0)
				_scrollPane.changeContentSizeOnScrolling(0, deltaSize, 0, firstItemDeltaSize);
			
			if (curIndex > 0 && this.numChildren > 0 && _container.y <= 0 && getChildAt(0).y > -_container.y)//最后一页没填满！
				return true;
			else
				return false;
		}
		
		private function handleScroll2(forceUpdate:Boolean):Boolean
		{
			var pos:Number = _scrollPane.scrollingPosX;
			var max:Number = pos + _scrollPane.viewWidth;
			var end:Boolean = pos == _scrollPane.contentWidth;//这个标志表示当前需要滚动到最末，无论内容变化大小
			
			//寻找当前位置的第一条项目
			GList.pos_param = pos;
			var newFirstIndex:int = getIndexOnPos2(forceUpdate);
			pos = GList.pos_param;
			if (newFirstIndex == _firstIndex && !forceUpdate)
				return false;
			
			var oldFirstIndex:int = _firstIndex;
			_firstIndex = newFirstIndex;
			var curIndex:int = newFirstIndex;
			var forward:Boolean = oldFirstIndex > newFirstIndex;
			var childCount:int = this.numChildren;
			var lastIndex:int = oldFirstIndex + childCount - 1;
			var reuseIndex:int = forward ? lastIndex : oldFirstIndex;
			var curX:Number = pos, curY:Number = 0;
			var needRender:Boolean;
			var deltaSize:Number = 0;
			var firstItemDeltaSize:Number  = 0;
			var url:String = defaultItem;
			var ii:ItemInfo, ii2:ItemInfo;
			var i:int,j:int;
			var partSize:int = (_scrollPane.viewHeight - _lineGap * (_curLineItemCount - 1)) / _curLineItemCount;

			itemInfoVer++;
			
			while (curIndex < _realNumItems && (end || curX < max))
			{
				ii = _virtualItems[curIndex];
				
				if (ii.obj == null || forceUpdate)
				{
					if (itemProvider != null)
					{
						url = itemProvider(curIndex % _numItems);
						if (url == null)
							url = _defaultItem;
						url = UIPackage.normalizeURL(url);
					}
					
					if (ii.obj != null && ii.obj.resourceURL != url)
					{
						if (ii.obj is GButton)
							ii.selected = GButton(ii.obj).selected;
						removeChildToPool(ii.obj);
						ii.obj = null;
					}
				}
				
				if (ii.obj == null)
				{
					if (forward)
					{
						for (j = reuseIndex; j >= oldFirstIndex; j--)
						{
							ii2 = _virtualItems[j];
							if (ii2.obj != null && ii2.updateFlag != itemInfoVer && ii2.obj.resourceURL == url)
							{
								if (ii2.obj is GButton)
									ii2.selected = GButton(ii2.obj).selected;
								ii.obj = ii2.obj;
								ii2.obj = null;
								if (j == reuseIndex)
									reuseIndex--;
								break;
							}
						}
					}
					else
					{
						for (j = reuseIndex; j <= lastIndex; j++)
						{
							ii2 = _virtualItems[j];
							if (ii2.obj != null && ii2.updateFlag != itemInfoVer && ii2.obj.resourceURL == url)
							{
								if (ii2.obj is GButton)
									ii2.selected = GButton(ii2.obj).selected;
								ii.obj = ii2.obj;
								ii2.obj = null;
								if (j == reuseIndex)
									reuseIndex++;
								break;
							}
						}
					}
					
					if (ii.obj != null)
					{
						setChildIndex(ii.obj, forward ? curIndex - newFirstIndex : numChildren);
					}
					else
					{
						ii.obj = _pool.getObject(url);
						if (forward)
							this.addChildAt(ii.obj, curIndex - newFirstIndex);
						else
							this.addChild(ii.obj);
					}
					if (ii.obj is GButton)
						GButton(ii.obj).selected = ii.selected;
					
					needRender = true;
				}
				else
					needRender = forceUpdate;
				
				if (needRender)
				{
					if (_autoResizeItem && (_layout == ListLayoutType.SingleRow || _lineCount > 0))
						ii.obj.setSize(ii.obj.width, partSize, true);

					itemRenderer(curIndex % _numItems, ii.obj);
					if (curIndex % _curLineItemCount == 0)
					{
						deltaSize += Math.ceil(ii.obj.width) - ii.width;
						if (curIndex == newFirstIndex && oldFirstIndex > newFirstIndex)
						{
							//当内容向下滚动时，如果新出现的一个项目大小发生变化，需要做一个位置补偿，才不会导致滚动跳动
							firstItemDeltaSize = Math.ceil(ii.obj.width) - ii.width;
						}
					}
					ii.width = Math.ceil(ii.obj.width);
					ii.height = Math.ceil(ii.obj.height);
				}
				
				ii.updateFlag = itemInfoVer;
				ii.obj.setXY(curX, curY);
				if (curIndex == newFirstIndex) //要显示多一条才不会穿帮
					max += ii.width;
				
				curY += ii.height + _lineGap;
				
				if (curIndex % _curLineItemCount == _curLineItemCount - 1)
				{
					curY = 0;
					curX += ii.width + _columnGap;
				}
				curIndex++;
			}
			
			for (i = 0; i < childCount; i++)
			{
				ii = _virtualItems[oldFirstIndex + i];
				if (ii.updateFlag != itemInfoVer && ii.obj != null)
				{
					if (ii.obj is GButton)
						ii.selected = GButton(ii.obj).selected;
					removeChildToPool(ii.obj);
					ii.obj = null;
				}
			}
			
			childCount = _children.length;
			for (i = 0; i < childCount; i++)
			{
				var obj:GObject = _virtualItems[newFirstIndex + i].obj;
				if (_children[i] != obj)
					setChildIndex(obj, i);
			}
			
			if (deltaSize != 0 || firstItemDeltaSize != 0)
				_scrollPane.changeContentSizeOnScrolling(deltaSize, 0, firstItemDeltaSize, 0);
			
			if (curIndex > 0 && this.numChildren > 0 && _container.x <= 0 && getChildAt(0).x > - _container.x)//最后一页没填满！
				return true;
			else
				return false;
		}
		
		private function handleScroll3(forceUpdate:Boolean):void
		{
			var pos:Number = _scrollPane.scrollingPosX;
			
			//寻找当前位置的第一条项目
			GList.pos_param = pos;
			var newFirstIndex:int = getIndexOnPos3(forceUpdate);
			pos = GList.pos_param;
			if (newFirstIndex == _firstIndex && !forceUpdate)
				return;
			
			var oldFirstIndex:int = _firstIndex;
			_firstIndex = newFirstIndex;
			
			//分页模式不支持不等高，所以渲染满一页就好了
			
			var reuseIndex:int = oldFirstIndex;
			var virtualItemCount:int = _virtualItems.length;
			var pageSize:int = _curLineItemCount * _curLineItemCount2;
			var startCol:int = newFirstIndex % _curLineItemCount;
			var viewWidth:Number = this.viewWidth;
			var page:int = int(newFirstIndex / pageSize);
			var startIndex:int = page * pageSize;
			var lastIndex:int = startIndex + pageSize * 2; //测试两页
			var needRender:Boolean;
			var i:int;
			var ii:ItemInfo, ii2:ItemInfo;
			var col:int;
			var url:String = _defaultItem;
			var partWidth:int = (_scrollPane.viewWidth - _columnGap * (_curLineItemCount - 1)) / _curLineItemCount;
			var partHeight:int = (_scrollPane.viewHeight - _lineGap * (_curLineItemCount2 - 1)) / _curLineItemCount2;
			
			itemInfoVer++;
			
			//先标记这次要用到的项目
			for (i = startIndex; i < lastIndex; i++)
			{
				if (i >= _realNumItems)
					continue;
				
				col = i % _curLineItemCount;
				if (i - startIndex < pageSize)
				{
					if (col < startCol)
						continue;
				}
				else
				{
					if (col > startCol)
						continue;
				}
				
				ii = _virtualItems[i];
				ii.updateFlag = itemInfoVer;
			}
			
			var lastObj:GObject = null;
			var insertIndex:int = 0;
			for (i = startIndex; i < lastIndex; i++)
			{
				if (i >= _realNumItems)
					continue;
				
				ii = _virtualItems[i];
				if (ii.updateFlag != itemInfoVer)
					continue;
				
				if (ii.obj == null)
				{
					//寻找看有没有可重用的
					while (reuseIndex < virtualItemCount)
					{
						ii2 = _virtualItems[reuseIndex];
						if (ii2.obj != null && ii2.updateFlag != itemInfoVer)
						{
							if (ii2.obj is GButton)
								ii2.selected = GButton(ii2.obj).selected;
							ii.obj = ii2.obj;
							ii2.obj = null;
							break;
						}
						reuseIndex++;
					}
					
					if (insertIndex == -1)
						insertIndex = getChildIndex(lastObj) + 1;
					
					if (ii.obj == null)
					{
						if (itemProvider != null)
						{
							url = itemProvider(i % _numItems);
							if (url == null)
								url = _defaultItem;
							url = UIPackage.normalizeURL(url);
						}
						
						ii.obj = _pool.getObject(url);
						this.addChildAt(ii.obj, insertIndex);
					}
					else
					{
						insertIndex = setChildIndexBefore(ii.obj, insertIndex);
					}
					insertIndex++;
					
					if (ii.obj is GButton)
						GButton(ii.obj).selected = ii.selected;
					
					needRender = true;
				}
				else
				{
					needRender = forceUpdate;
					insertIndex = -1;
					lastObj = ii.obj;
				}
				
				if (needRender)
				{
					if (_autoResizeItem)
					{
						if (_curLineItemCount == _columnCount && _curLineItemCount2 == _lineCount)
							ii.obj.setSize(partWidth, partHeight, true);
						else if (_curLineItemCount == _columnCount)
							ii.obj.setSize(partWidth, ii.obj.height, true);
						else if (_curLineItemCount2 == _lineCount)
							ii.obj.setSize(ii.obj.width, partHeight, true);
					}
					
					itemRenderer(i % _numItems, ii.obj);
					ii.width = Math.ceil(ii.obj.width);
					ii.height = Math.ceil(ii.obj.height);
				}
			}
			
			//排列item
			var borderX:int = (startIndex / pageSize) * viewWidth;
			var xx:int = borderX;
			var yy:int = 0;
			var lineHeight:int = 0;
			for (i = startIndex; i < lastIndex; i++)
			{
				if (i >= _realNumItems)
					continue;
				
				ii = _virtualItems[i];
				if (ii.updateFlag == itemInfoVer)
					ii.obj.setXY(xx, yy);
				
				if (ii.height > lineHeight)
					lineHeight = ii.height;
				if (i % _curLineItemCount == _curLineItemCount - 1)
				{
					xx = borderX;
					yy += lineHeight + _lineGap;
					lineHeight = 0;
					
					if (i == startIndex + pageSize - 1)
					{
						borderX += viewWidth;
						xx = borderX;
						yy = 0;
					}
				}
				else
					xx += ii.width + _columnGap;
			}
			
			//释放未使用的
			for (i = reuseIndex; i < virtualItemCount; i++)
			{
				ii = _virtualItems[i];
				if (ii.updateFlag != itemInfoVer && ii.obj != null)
				{
					if (ii.obj is GButton)
						ii.selected = GButton(ii.obj).selected;
					removeChildToPool(ii.obj);
					ii.obj = null;
				}
			}
		}
		
		private function handleArchOrder1():void
		{
			if (this.childrenRenderOrder == ChildrenRenderOrder.Arch)
			{
				var mid:Number = _scrollPane.posY + this.viewHeight / 2;
				var minDist:Number = int.MAX_VALUE, dist:Number;
				var apexIndex:int = 0;
				var cnt:int = this.numChildren;
				for (var i:int = 0; i < cnt; i++)
				{
					var obj:GObject = getChildAt(i);
					if (!foldInvisibleItems || obj.visible)
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
		
		private function handleArchOrder2():void
		{
			if (this.childrenRenderOrder == ChildrenRenderOrder.Arch)
			{
				var mid:Number = _scrollPane.posX + this.viewWidth / 2;
				var minDist:Number = int.MAX_VALUE, dist:Number;
				var apexIndex:int = 0;
				var cnt:int = this.numChildren;
				for (var i:int = 0; i < cnt; i++)
				{
					var obj:GObject = getChildAt(i);
					if (!foldInvisibleItems || obj.visible)
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
		
		private function handleAlign(contentWidth:Number, contentHeight:Number):void
		{
			var newOffsetX:Number = 0;
			var newOffsetY:Number = 0;

			if (contentHeight < viewHeight)
			{
				if (_verticalAlign == VertAlignType.Middle)
					newOffsetY = int((viewHeight - contentHeight) / 2);
				else if (_verticalAlign == VertAlignType.Bottom)
					newOffsetY = viewHeight - contentHeight;
			}

			if (contentWidth < this.viewWidth)
			{
				if (_align == AlignType.Center)
					newOffsetX = int((viewWidth - contentWidth) / 2);
				else if (_align == AlignType.Right)
					newOffsetX = viewWidth - contentWidth;
			}

			if (newOffsetX!=_alignOffset.x || newOffsetY!=_alignOffset.y)
			{
				_alignOffset.setTo(newOffsetX, newOffsetY);
				if (_scrollPane != null)
					_scrollPane.adjustMaskContainer();
				else
				{
					_container.x = _margin.left + _alignOffset.x;
					_container.y = _margin.top + _alignOffset.y;
				}
			}
		}
		
		override protected function updateBounds():void
		{
			if(_virtual)
				return;
			
			var i:int;
			var child:GObject;
			var curX:int;
			var curY:int;
			var maxWidth:int;
			var maxHeight:int;
			var cw:int, ch:int;
			var j:int = 0;
			var page:int = 0;
			var k:int = 0;
			var cnt:int = _children.length;
			var viewWidth:Number = this.viewWidth;
			var viewHeight:Number = this.viewHeight;
			var lineSize:Number = 0;
			var lineStart:int = 0;
			var ratio:Number;
			
			if(_layout==ListLayoutType.SingleColumn)
			{
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					if (foldInvisibleItems && !child.visible)
						continue;
					
					if (curY != 0)
						curY += _lineGap;
					child.y = curY;
					if (_autoResizeItem)
						child.setSize(viewWidth, child.height, true);
					curY += Math.ceil(child.height);
					if(child.width>maxWidth)
						maxWidth = child.width;
				}
				ch = curY;

				if(ch<=viewHeight && _autoResizeItem && _scrollPane && _scrollPane._displayInDemand && _scrollPane.vtScrollBar)
				{
					viewWidth += _scrollPane.vtScrollBar.width;
					for(i=0;i<cnt;i++)
					{
						child = getChildAt(i);
						if (foldInvisibleItems && !child.visible)
							continue;

						child.setSize(viewWidth, child.height, true);
						if(child.width>maxWidth)
							maxWidth = child.width;
					}
				}

				cw = Math.ceil(maxWidth);
			}
			else if(_layout==ListLayoutType.SingleRow)
			{
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					if (foldInvisibleItems && !child.visible)
						continue;

					if(curX!=0)
						curX += _columnGap;
					child.x = curX;
					if (_autoResizeItem)
						child.setSize(child.width, viewHeight, true);
					curX += Math.ceil(child.width);
					if(child.height>maxHeight)
						maxHeight = child.height;
				}
				cw = curX;

				if(cw<=viewWidth && _autoResizeItem && _scrollPane && _scrollPane._displayInDemand && _scrollPane.hzScrollBar)
				{
					viewHeight += _scrollPane.hzScrollBar.height;
					for(i=0;i<cnt;i++)
					{
						child = getChildAt(i);
						if (foldInvisibleItems && !child.visible)
							continue;

						child.setSize(child.width, viewHeight, true);
						if(child.height>maxHeight)
							maxHeight = child.height;
					}
				}

				ch = Math.ceil(maxHeight);
			}
			else if(_layout==ListLayoutType.FlowHorizontal)
			{
				if (_autoResizeItem && _columnCount > 0)
				{
					for (i = 0; i < cnt; i++)
					{
						child = getChildAt(i);
						if (foldInvisibleItems && !child.visible)
							continue;
						
						lineSize += child.sourceWidth;
						j++;
						if (j == _columnCount || i == cnt - 1)
						{
							ratio = (viewWidth - lineSize - (j - 1) * _columnGap) / lineSize;
							curX = 0;
							for (j = lineStart; j <= i; j++)
							{
								child = getChildAt(j);
								if (foldInvisibleItems && !child.visible)
									continue;
								
								child.setXY(curX, curY);
								
								if (j < i)
								{
									child.setSize(child.sourceWidth + Math.round(child.sourceWidth * ratio), child.height, true);
									curX += Math.ceil(child.width) + _columnGap;
								}
								else
								{
									child.setSize(viewWidth - curX, child.height, true);
								}
								if (child.height > maxHeight)
									maxHeight = child.height;
							}
							//new line
							curY += Math.ceil(maxHeight) + _lineGap;
							maxHeight = 0;
							j = 0;
							lineStart = i + 1;
							lineSize = 0;
						}
					}
					ch = curY + Math.ceil(maxHeight);
					cw = viewWidth;
				}
				else
				{
					for(i=0;i<cnt;i++)
					{
						child = getChildAt(i);
						if (foldInvisibleItems && !child.visible)
							continue;
	
						if(curX!=0)
							curX += _columnGap;
						
						if (_columnCount != 0 && j >= _columnCount
							|| _columnCount == 0 && curX + child.width > viewWidth && maxHeight != 0)
						{
							//new line
							curX = 0;
							curY += Math.ceil(maxHeight) + _lineGap;
							maxHeight = 0;
							j = 0;
						}
						child.setXY(curX, curY);
						curX += Math.ceil(child.width);
						if (curX > maxWidth)
							maxWidth = curX;
						if (child.height > maxHeight)
							maxHeight = child.height;
						j++;
					}
					ch = curY + Math.ceil(maxHeight);
					cw = Math.ceil(maxWidth);
				}
			}
			else if (_layout == ListLayoutType.FlowVertical)
			{
				if (_autoResizeItem && _lineCount > 0)
				{
					for (i = 0; i < cnt; i++)
					{
						child = getChildAt(i);
						if (foldInvisibleItems && !child.visible)
							continue;
						
						lineSize += child.sourceHeight;
						j++;
						if (j == _lineCount || i == cnt - 1)
						{
							ratio = (viewHeight - lineSize - (j - 1) * _lineGap) / lineSize;
							curY = 0;
							for (j = lineStart; j <= i; j++)
							{
								child = getChildAt(j);
								if (foldInvisibleItems && !child.visible)
									continue;
								
								child.setXY(curX, curY);
								
								if (j < i)
								{
									child.setSize(child.width, child.sourceHeight + Math.round(child.sourceHeight * ratio), true);
									curY += Math.ceil(child.height) + _lineGap;
								}
								else
								{
									child.setSize(child.width, viewHeight - curY, true);
								}
								if (child.width > maxWidth)
									maxWidth = child.width;
							}
							//new line
							curX += Math.ceil(maxWidth) + _columnGap;
							maxWidth = 0;
							j = 0;
							lineStart = i + 1;
							lineSize = 0;
						}
					}
					cw = curX + Math.ceil(maxWidth);
					ch = viewHeight;
				}
				else
				{
					for(i=0;i<cnt;i++)
					{
						child = getChildAt(i);
						if (foldInvisibleItems && !child.visible)
							continue;
						
						if(curY!=0)
							curY += _lineGap;
						
						if (_lineCount != 0 && j >= _lineCount
							|| _lineCount == 0 && curY + child.height > viewHeight && maxWidth != 0)
						{
							curY = 0;
							curX += Math.ceil(maxWidth) + _columnGap;
							maxWidth = 0;
							j = 0;
						}
						child.setXY(curX, curY);
						curY += Math.ceil(child.height);
						if (curY > maxHeight)
							maxHeight = curY;
						if (child.width > maxWidth)
							maxWidth = child.width;
						j++;
					}
					cw = curX + Math.ceil(maxWidth);
					ch = Math.ceil(maxHeight);
				}
			}
			else //pagination
			{
				var eachHeight:int;
				if(_autoResizeItem && _lineCount>0)
					eachHeight = Math.floor((viewHeight-(_lineCount-1)*_lineGap)/_lineCount);
				
				if (_autoResizeItem && _columnCount > 0)
				{
					for (i = 0; i < cnt; i++)
					{
						child = getChildAt(i);
						if (foldInvisibleItems && !child.visible)
							continue;
						
						if (j==0 && (_lineCount != 0 && k >= _lineCount
							|| _lineCount == 0 && curY + child.height > viewHeight))
						{
							//new page
							page++;
							curY = 0;
							k = 0;
						}
						
						lineSize += child.sourceWidth;
						j++;
						if (j == _columnCount || i == cnt - 1)
						{
							ratio = (viewWidth - lineSize - (j - 1) * _columnGap) / lineSize;
							curX = 0;
							for (j = lineStart; j <= i; j++)
							{
								child = getChildAt(j);
								if (foldInvisibleItems && !child.visible)
									continue;
								
								child.setXY(page * viewWidth + curX, curY);
								
								if (j < i)
								{
									child.setSize(child.sourceWidth + Math.round(child.sourceWidth * ratio), 
										_lineCount>0?eachHeight:child.height, true);
									curX += Math.ceil(child.width) + _columnGap;
								}
								else
								{
									child.setSize(viewWidth - curX, _lineCount>0?eachHeight:child.height, true);
								}
								if (child.height > maxHeight)
									maxHeight = child.height;
							}
							//new line
							curY += Math.ceil(maxHeight) + _lineGap;
							maxHeight = 0;
							j = 0;
							lineStart = i + 1;
							lineSize = 0;
							
							k++;
						}
					}
				}
				else
				{
					for (i = 0; i < cnt; i++)
					{
						child = getChildAt(i);
						if (foldInvisibleItems && !child.visible)
							continue;

						if (curX != 0)
							curX += _columnGap;
						
						if (_autoResizeItem && _lineCount > 0)
							child.setSize(child.width, eachHeight, true);
						
						if (_columnCount != 0 && j >= _columnCount
							|| _columnCount == 0 && curX + child.width > viewWidth && maxHeight != 0)
						{
							//new line
							curX = 0;
							curY += Math.ceil(maxHeight) + _lineGap;
							maxHeight = 0;
							j = 0;
							k++;
							
							if (_lineCount != 0 && k >= _lineCount
								|| _lineCount == 0 && curY + child.height > viewHeight && maxWidth != 0)//new page
							{
								page++;
								curY = 0;
								k = 0;
							}
						}
						child.setXY(page * viewWidth + curX, curY);
						curX += Math.ceil(child.width);
						if (curX > maxWidth)
							maxWidth = curX;
						if (child.height > maxHeight)
							maxHeight = child.height;
						j++;
					}
				}
				ch = page > 0 ? viewHeight : curY + Math.ceil(maxHeight);
				cw = (page + 1) * viewWidth;
			}
			
			handleAlign(cw, ch);
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
			
			str = xml.@align;
			if(str)
				_align = AlignType.parse(str);
			
			str = xml.@vAlign;
			if(str)
				_verticalAlign = VertAlignType.parse(str);
			
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
				
				var headerRes:String;
				var footerRes:String;
				str = xml.@ptrRes;
				if(str)
				{
					arr = str.split(",");
					headerRes = arr[0];
					footerRes = arr[1];
				}
				
				setupScroll(scrollBarMargin, scroll, scrollBarDisplay, scrollBarFlags, 
					vtScrollBarRes, hzScrollBarRes, headerRes, footerRes);
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
			{
				if (_layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination)
					_columnCount = parseInt(str);
				else if (_layout == ListLayoutType.FlowVertical)
					_lineCount = parseInt(str);
			}
			
			str = xml.@lineItemCount2;
			if(str)
				_lineCount = parseInt(str);
			
			str = xml.@selectionMode;
			if(str)
				_selectionMode = ListSelectionMode.parse(str);
			
			str = xml.@defaultItem;
			if(str)
				_defaultItem = str;
			
			str = xml.@autoItemSize;
			if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.SingleColumn)
				_autoResizeItem = str!="false";
			else
				_autoResizeItem = str=="true";
			
			str = xml.@renderOrder;
			if(str)
			{
				_childrenRenderOrder = ChildrenRenderOrder.parse(str);
				if(_childrenRenderOrder==ChildrenRenderOrder.Arch)
				{
					str = xml.@apex;
					if(str)
						_apexIndex = parseInt(str);
				}
			}

			str = xml.@scrollItemToViewOnClick;
			if(str)
				scrollItemToViewOnClick = str=="true";
			str = xml.@foldInvisibleItems;
			if(str)
				foldInvisibleItems = str=="true";

			readItems(xml);
		}

		protected function readItems(xml:XML):void
		{
			var str:String;
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
					setupItem(cxml, obj);
				}
			}
		}

		protected function setupItem(cxml:XML, obj:GObject):void
		{
			var str:String;
			str = cxml.@title;
			if(str)
				obj.text = str;
			str = cxml.@icon;
			if(str)
				obj.icon = str;
			str = cxml.@name;
			if(str)
				obj.name = str;
			str = cxml.@selectedIcon;
			if(str && (obj is GButton))
				GButton(obj).selectedIcon = str;
			str = cxml.@selectedTitle;
			if(str && (obj is GButton))
				GButton(obj).selectedTitle = str;
			if(obj is GComponent)
			{
				str = cxml.@controllers;
				if(str)
				{
					var arr:Array = str.split(",");
					for(var j:int=0;j<arr.length;j+=2)
					{
						var cc:Controller = GComponent(obj).getController(arr[j]);
						if(cc!=null)
							cc.selectedPageId = arr[j+1];
					}
				}

				var col:XMLList = cxml.property;
				for each(var dxml:XML in col)
				{
					var target:String = dxml.@target;
					var propertyId:int = parseInt(dxml.@propertyId);
					var value:String = dxml.@value;
					var obj2:GObject = GComponent(obj).getChildByPath(target);
					if(obj2)
						obj2.setProp(propertyId, value);
				}
			}
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			var str:String;
			str = xml.@selectionController;
			if(str)
				_selectionController = parent.getController(str);
		}
	}
}

import fairygui.GObject;

class ItemInfo
{
	public var width:Number = 0;
	public var height:Number = 0;
	public var obj:GObject;
	public var updateFlag:uint;
	public var selected:Boolean;
	
	public function ItemInfo():void
	{
	}
}
