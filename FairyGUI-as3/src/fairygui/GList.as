package fairygui
{
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import fairygui.display.UIDisplayObject;
	import fairygui.event.GTouchEvent;
	import fairygui.event.ItemEvent;

	[Event(name = "itemClick", type = "fairygui.event.ItemEvent")]
	public class GList extends GComponent
	{
		private var _layout:int;
		private var _lineGap:int;
		private var _columnGap:int;
		private var _defaultItem:String;
		private var _autoResizeItem:Boolean;
		private var _selectionMode:int;
		private var _lastSelectedIndex:int;
		private var _pool:GObjectPool;
		private var _selectionHandled:Boolean;

		public function GList()
		{
			super();
			
			_trackBounds = true;
			_pool = new GObjectPool();
			_layout = ListLayoutType.SingleColumn;
			_autoResizeItem = true;
			_lastSelectedIndex = -1;
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

			return _pool.getObject(url);
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
			}
			child.addEventListener(GTouchEvent.BEGIN, __mouseDownItem);
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
			child.removeEventListener(GTouchEvent.BEGIN, __mouseDownItem);
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
			if (endIndex < 0 || endIndex >= numChildren) 
				endIndex = numChildren - 1;
			
			for (var i:int=beginIndex; i<=endIndex; ++i)
				removeChildToPoolAt(beginIndex);
		}

		public function get selectedIndex():int
		{
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GButton = _children[i].asButton;
				if(obj!=null && obj.selected)
					return i;
			}
			return -1;
		}
		
		public function set selectedIndex(value:int):void
		{
			clearSelection();
			if(value>=0 && value<_children.length)
				addSelection(value);
		}
		
		public function getSelection():Vector.<int>
		{
			var ret:Vector.<int> = new Vector.<int>();
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GButton = _children[i].asButton;
				if(obj!=null && obj.selected)
					ret.push(i);
			}
			return ret;
		}
		
		public function addSelection(index:int, scrollItToView:Boolean=false):void
		{
			if(_selectionMode==ListSelectionMode.None)
				return;
			
			if(_selectionMode==ListSelectionMode.Single)
				clearSelection();

			var obj:GButton = getChildAt(index).asButton;
			if(obj!=null)
			{
				if(!obj.selected)
					obj.selected = true;
				if(scrollItToView && _scrollPane!=null)
					_scrollPane.scrollToView(obj);
			}
		}
		
		public function removeSelection(index:int):void
		{
			if(_selectionMode==ListSelectionMode.None)
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
		
		private function __mouseDownItem(evt:Event):void
		{
			var item:GButton = evt.currentTarget as GButton;
			if(item==null || _selectionMode==ListSelectionMode.None)
				return;
			
			_selectionHandled = false;
			
			if(UIConfig.defaultScrollTouchEffect && this.scrollPane!=null)
				return;
			
			if(_selectionMode==ListSelectionMode.Single)
			{
				setSelectionOnEvent(item);
			}
			else
			{
				if(!item.selected)
					setSelectionOnEvent(item);
				//如果item.selected，这里不处理selection，因为可能用户在拖动
			}
		}
		
		private function __clickItem(evt:GTouchEvent):void
		{
			var item:GObject = GObject(evt.currentTarget);
			if(!_selectionHandled)
				setSelectionOnEvent(item);
			_selectionHandled = false;
			
			if (scrollPane != null)
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
			
			if (scrollPane != null)
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
			
			_selectionHandled = true;
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
							max = Math.min(max, this.numChildren-1);
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
			
			var curCount:int = this.numChildren;
			if(itemCount>curCount)
				itemCount = curCount;
			
			if (itemCount == 0)
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
			var cnt:int = numChildren;				
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
				setBoundsChangedFlag();
		}
		
		public function adjustItemsSize():void
		{
			if(_layout==ListLayoutType.SingleColumn)
			{
				var cnt:int = numChildren;				
				var cw:int = this.viewWidth;
				for(var i:int=0;i<cnt;i++)
				{
					var child:GObject = getChildAt(i);
					child.width = cw;
				}
			}
			else if(_layout==ListLayoutType.SingleRow)
			{
				cnt = numChildren;
				var ch:int = this.viewHeight;
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					child.height = ch;
				}
			}
		}
		
		override public function findObjectNear(xValue:Number, yValue:Number, resultPoint:Point=null):Point
		{
			if(!resultPoint)
				resultPoint = new Point();
			
			var cnt:int = _children.length;
			if(cnt==0)
			{
				resultPoint.x = xValue;
				resultPoint.y = yValue;
				return resultPoint;
			}
			
			ensureBoundsCorrect();
			var obj:GObject = null;
			
			var i:int = 0;
			if (yValue != 0)
			{
				for (; i < cnt; i++)
				{
					obj = _children[i];
					if (yValue < obj.y)
					{
						if (i == 0)
						{
							yValue = 0;
							break;
						}
						else
						{
							var prev:GObject = _children[i - 1];
							if (yValue < prev.y + prev.actualHeight / 2) //inside item, top half part
								yValue = prev.y;
							else if (yValue < prev.y + prev.actualHeight)//inside item, bottom half part
								yValue = obj.y;
							else //between two items
								yValue = obj.y + _lineGap / 2;
							break;
						}
					}
				}
				
				if (i == cnt)
					yValue = obj.y;
			}
			
			if (xValue != 0)
			{
				if (i > 0)
					i--;
				for (; i < cnt; i++)
				{
					obj = _children[i];
					if (xValue < obj.x)
					{
						if (i == 0)
						{
							xValue = 0;
							break;
						}
						else
						{
							prev = _children[i - 1];
							if (xValue < prev.x + prev.actualWidth / 2) //inside item, top half part
								xValue = prev.x;
							else if (xValue < prev.x + prev.actualWidth)//inside item, bottom half part
								xValue = obj.x;
							else //between two items
								xValue = obj.x + _columnGap / 2;
							break;
						}
					}
				}
				
				if (i == cnt)
					xValue = obj.x;
			}
			
			resultPoint.x = xValue;
			resultPoint.y = yValue;
			return resultPoint;
		}
		
		override protected function updateBounds():void
		{
			var cnt:int = numChildren;
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
					child.setXY(curX, curY);
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
					child.setXY(curX, curY);
					curX += child.width;
					if(child.height>maxHeight)
						maxHeight = child.height;
				}
				cw = curX;
				ch = curY+maxHeight;
			}
			else if(_layout==ListLayoutType.FlowHorizontal)
			{
				cw = this.viewWidth;
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					if (!child.visible)
						continue;
					
					if(curX!=0)
						curX += _columnGap;
					
					if(curX+child.width>cw && maxHeight!=0)
					{
						//new line
						curX = 0;
						curY += maxHeight + _lineGap;
						maxHeight = 0;
					}
					child.setXY(curX, curY);
					curX += child.width;
					if(child.height>maxHeight)
						maxHeight = child.height;
				}
				ch = curY+maxHeight;
			}
			else
			{
				ch = this.viewHeight;
				for(i=0;i<cnt;i++)
				{
					child = getChildAt(i);
					if (!child.visible)
						continue;
					
					if(curY!=0)
						curY += _lineGap;
					
					if(curY+child.height>ch && maxWidth!=0)
					{
						curY = 0;
						curX += maxWidth + _columnGap;
						maxWidth = 0;
					}
					child.setXY(curX, curY);
					curY += child.height;
					if(child.width>maxWidth)
						maxWidth = child.width;
				}
				cw = curX+maxWidth;
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
			else
				_lineGap = 0;
			
			str = xml.@colGap;
			if(str)
				_columnGap = parseInt(str);
			else
				_columnGap = 0;
			
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
