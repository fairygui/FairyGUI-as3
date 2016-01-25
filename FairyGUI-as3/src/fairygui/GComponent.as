package fairygui 
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import fairygui.display.UISprite;
	import fairygui.utils.GTimers;

	[Event(name = "scrollEvent", type = "flash.events.Event")]
	[Event(name = "dropEvent", type = "fairygui.event.DropEvent")]
	public class GComponent extends GObject
	{
		private var _boundsChanged:Boolean;
		private var _bounds:Rectangle;
		private var _sortingChildCount:int;
		private var _opaque:Boolean;
		
		protected var _margin:Margin;
		protected var _trackBounds:Boolean;
		protected var _mask:Shape;
		
		internal var _buildingDisplayList:Boolean;
		internal var _children:Vector.<GObject>;
		internal var _controllers:Vector.<Controller>;
		internal var _transitions:Vector.<Transition>;
		internal var _rootContainer:Sprite;
		internal var _container:Sprite;
		internal var _scrollPane:ScrollPane;
		
		public function GComponent():void
		{
			_bounds = new Rectangle();
			_children = new Vector.<GObject>();
			_controllers = new Vector.<Controller>();
			_transitions = new Vector.<Transition>();
			_margin = new Margin();
		}
		
		override protected function createDisplayObject():void
		{
			_rootContainer = new UISprite(this);
			setDisplayObject(_rootContainer);			
			_container = _rootContainer;
		}
		
		public override function dispose():void
		{
			var numChildren:int = _children.length; 
			for (var i:int=numChildren-1; i>=0; --i)
				_children[i].dispose();
			
			if (_scrollPane != null)
				_scrollPane.dispose();
			
			super.dispose();
		}
		
		final public function get displayListContainer():DisplayObjectContainer
		{
			return _container;
		}
		
		public function addChild(child:GObject):GObject
		{
			addChildAt(child, _children.length);
			return child;
		}
		
		public function addChildAt(child:GObject, index:int):GObject
		{
			if(!child)
				throw new Error("child is null");

			var numChildren:int = _children.length; 
			
			if (index >= 0 && index <= numChildren)
			{
				if (child.parent == this)
				{
					setChildIndex(child, index); 
				}
				else
				{
					child.removeFromParent();
					child.parent = this;
					
					var cnt:int = _children.length;
					if(child.sortingOrder!=0)
					{
						_sortingChildCount++;
						index = getInsertPosForSortingChild(child);
					}
					else if(_sortingChildCount>0)
					{
						if(index > (cnt-_sortingChildCount))
							index = cnt - _sortingChildCount;
					}
					
					if (index == cnt) 
						_children.push(child);
					else
						_children.splice(index, 0, child);
					
					childStateChanged(child);
					setBoundsChangedFlag();
				}

				return child;
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}

		private function getInsertPosForSortingChild(target:GObject):int
		{
			var cnt:int = _children.length;
			var i:int;
			for (i = 0; i < cnt; i++)
			{
				var child:GObject = _children[i];
				if (child == target)
					continue;
				
				if (target.sortingOrder < child.sortingOrder)
					break;
			}
			return i;
		}
		
		public function removeChild(child:GObject, dispose:Boolean=false):GObject
		{
			var childIndex:int = _children.indexOf(child);
			if (childIndex != -1)
			{
				removeChildAt(childIndex, dispose);
			}
			return child;
		}

		public function removeChildAt(index:int, dispose:Boolean=false):GObject
		{
			if (index >= 0 && index < numChildren)
			{
				var child:GObject = _children[index];				
				child.parent = null;
				
				if(child.sortingOrder!=0)
					_sortingChildCount--;
				
				_children.splice(index, 1);
				if(child.inContainer)
					_container.removeChild(child.displayObject);
				
				if(dispose)
					child.dispose();
				
				setBoundsChangedFlag();
				
				return child;
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}

		public function removeChildren(beginIndex:int=0, endIndex:int=-1, dispose:Boolean=false):void
		{
			if (endIndex < 0 || endIndex >= numChildren) 
				endIndex = numChildren - 1;
			
			for (var i:int=beginIndex; i<=endIndex; ++i)
				removeChildAt(beginIndex, dispose);
		}
		
		public function getChildAt(index:int):GObject
		{
			if (index >= 0 && index < numChildren)
				return _children[index];
			else
				throw new RangeError("Invalid child index");
		}
		
		public function getChild(name:String):GObject
		{
			var cnt:int = _children.length;
			for (var i:int=0; i<cnt; ++i)
			{
				if (_children[i].name == name) 
					return _children[i];
			}
			
			return null;
		}
		
		public function getVisibleChild(name:String):GObject
		{
			var cnt:int = _children.length;
			for (var i:int=0; i<cnt; ++i)
			{
				var child:GObject = _children[i];
				if (child.finalVisible && child.name==name) 
					return child;
			}
			
			return null;
		}
		
		public function getChildInGroup(name:String, group:GGroup):GObject
		{
			var cnt:int = _children.length;
			for (var i:int=0; i<cnt; ++i)
			{
				var child:GObject = _children[i];
				if (child.group==group && child.name == name) 
					return child;
			}
			
			return null;
		}
		
		internal function getChildById(id:String):GObject
		{
			var cnt:int = _children.length;
			for (var i:int=0; i<cnt; ++i)
			{
				if (_children[i]._id == id) 
					return _children[i];
			}
			
			return null;
		}
		
		public function getChildIndex(child:GObject):int
		{
			return _children.indexOf(child);
		}
		
		public function setChildIndex(child:GObject, index:int):void
		{
			var oldIndex:int = _children.indexOf(child);
			if (oldIndex == -1) 
				throw new ArgumentError("Not a child of this container");
			
			if(child.sortingOrder!=0) //no effect
				return;
			
			var cnt:int = _children.length;
			if(_sortingChildCount>0)
			{
				if (index > (cnt - _sortingChildCount - 1))
					index = cnt - _sortingChildCount - 1;
			}
			
			_setChildIndex(child, oldIndex, index);
		}
		
		private function _setChildIndex(child:GObject, oldIndex:int, index:int):void
		{
			var cnt:int = _children.length;
			if(index>cnt)
				index = cnt;
			
			if(oldIndex==index)
				return;
			
			_children.splice(oldIndex, 1);
			_children.splice(index, 0, child);
			
			if(child.inContainer)
			{			
				var displayIndex:int;
				for(var i:int=0;i<index;i++)
				{
					var g:GObject = _children[i];
					if(g.inContainer)
						displayIndex++;
				}
				if(displayIndex==_container.numChildren)
					displayIndex--;
				_container.setChildIndex(child.displayObject, displayIndex);
				
				setBoundsChangedFlag();
			}
		}
		
		public function swapChildren(child1:GObject, child2:GObject):void
		{
			var index1:int = _children.indexOf(child1);
			var index2:int = _children.indexOf(child2);
			if (index1 == -1 || index2 == -1)
				throw new ArgumentError("Not a child of this container");
			swapChildrenAt(index1, index2);
		}
		
		public function swapChildrenAt(index1:int, index2:int):void
		{
			var child1:GObject = _children[index1];
			var child2:GObject = _children[index2];

			setChildIndex(child1, index2);
			setChildIndex(child2, index1);
		}

		final public function get numChildren():int 
		{ 
			return _children.length; 
		}

		public function addController(controller:Controller):void
		{
			_controllers.push(controller);
			controller._parent = this;
			applyController(controller);
		}
		
		public function getControllerAt(index:int):Controller
		{
			return _controllers[index];
		}
		
		public function getController(name:String):Controller
		{
			var cnt:int = _controllers.length;
			for (var i:int=0; i<cnt; ++i)
			{
				var c:Controller = _controllers[i];
				if (c.name == name) 
					return c;
			}
			
			return null;
		}
		
		public function removeController(c:Controller):void
		{
			var index:int = _controllers.indexOf(c);
			if(index==-1)
				throw new Error("controller not exists");
			
			c._parent = null;
			_controllers.splice(index,1);
			
			for each(var child:GObject in _children)
				child.handleControllerChanged(c);
		}
		
		final public function get controllers():Vector.<Controller>
		{
			return _controllers;
		}
		
		internal function childStateChanged(child:GObject):void
		{
			if(_buildingDisplayList)
				return;
			
			if(child is GGroup)
			{
				for each(var g:GObject in _children)
				{
					if(g.group==child)
						childStateChanged(g);
				}
				return;
			}
			
			if(!child.displayObject)
				return;
			
			if(child.finalVisible)
			{
				if(!child.displayObject.parent)
				{
					var index:int;
					for each(g in _children)
					{
						if(g==child)
							break;
						
						if(g.displayObject && g.displayObject.parent)
							index++;
					}
					_container.addChildAt(child.displayObject, index);
				}
			}
			else
			{
				if(child.displayObject.parent)
					_container.removeChild(child.displayObject);
			}
		}
		
		internal function applyController(c:Controller):void
		{
			var child:GObject;
			for each(child in _children)
				child.handleControllerChanged(c);
		}
		
		internal function applyAllControllers():void
		{
			var cnt:int = _controllers.length;
			for (var i:int=0; i<cnt; ++i)
			{
				applyController(_controllers[i]);
			}
		}
		
		internal function adjustRadioGroupDepth(obj:GObject, c:Controller):void
		{
			var cnt:int = _children.length;
			var i:int;
			var child:GObject;
			var myIndex:int = -1, maxIndex:int = -1;
			for(i=0;i<cnt;i++)
			{
				child = _children[i];
				if(child==obj)
				{
					myIndex = i;
				}
				else if((child is GButton) 
					&& GButton(child).relatedController==c)
				{
					if(i>maxIndex)
						maxIndex = i;
				}
			}
			if(myIndex<maxIndex)
				this.swapChildrenAt(myIndex, maxIndex);
		}
		
		public function getTransitionAt(index:int):Transition
		{
			return _transitions[index];
		}
		
		public function getTransition(transName:String):Transition
		{
			var cnt:int = _transitions.length;
			for (var i:int = 0; i < cnt; ++i)
			{
				var trans:Transition = _transitions[i];
				if (trans.name == transName)
					return trans;
			}
			
			return null;
		}
		
		final public function get scrollPane():ScrollPane
		{
			return _scrollPane;
		}
		
		final public function get opaque():Boolean
		{
			return _opaque;
		}
		
		public function set opaque(value:Boolean):void
		{
			if(_opaque!=value)
			{
				_opaque = value;
				if(_opaque)
					updateOpaque();
				else
					_rootContainer.graphics.clear();
			}
		}
		
		protected function updateOpaque():void
		{
			var w:Number = this.width;
			var h:Number = this.height;
			if(w==0)
				w = 1;
			if(h==0)
				h = 1;

			var g:Graphics = _rootContainer.graphics;
			g.clear();
			g.lineStyle(0,0,0);
			g.beginFill(0,0);
			g.drawRect(0,0,w,h);
			g.endFill();
		}
		
		protected function updateMask():void
		{
			var left:Number = _margin.left;
			var top:Number = _margin.top;
			var w:Number = this.width - (_margin.left + _margin.right);
			var h:Number = this.height - (_margin.top + _margin.bottom);
			if(w<=0)
				w = 1;
			if(h<=0)
				h = 1;
			
			var g:Graphics = _mask.graphics;
			g.clear();
			g.lineStyle(0,0,0);
			g.beginFill(0,0);
			g.drawRect(left,top,w,h);
			g.endFill();
		}
		
		protected function setupOverflowAndScroll(overflow:int,
											   scrollBarMargin:Margin,
											   scroll:int,
											   scrollBarDisplay:int,
											   flags:int):void
		{
			if(overflow==OverflowType.Hidden)
			{
				_container = new Sprite();
				_rootContainer.addChild(_container);
				
				_mask = new Shape();
				_rootContainer.addChild(_mask);
				updateMask();
				
				_container.mask = _mask;
				_container.x = _margin.left;
				_container.y = _margin.top;
			}
			else if(overflow==OverflowType.Scroll)
			{
				_container = new Sprite();
				_rootContainer.addChild(_container);
				_scrollPane = new ScrollPane(this, scroll, _margin, scrollBarMargin, scrollBarDisplay, flags);
			}
			else if(_margin.left!=0 || _margin.top!=0)
			{
				_container = new Sprite();
				_rootContainer.addChild(_container);
				_container.x = _margin.left;
				_container.y = _margin.top;
			}
			
			setBoundsChangedFlag();
		}
		
		override protected function handleSizeChanged():void
		{
			if(_scrollPane)
				_scrollPane.setSize(this.width, this.height);
			else if(_mask)
				updateMask();
			
			if(_opaque)
				updateOpaque();
			
			_rootContainer.scaleX = this.scaleX;
			_rootContainer.scaleY = this.scaleY;
		}
		
		override protected function handleGrayChanged():void
		{
			var c:Controller = getController("grayed");
			if(c!=null)
			{
				c.selectedIndex = this.grayed?1:0;
				return;
			}
			
			var v:Boolean = this.grayed;
			var cnt:int = _children.length;
			for (var i:int=0; i<cnt; ++i)
			{
				_children[i].grayed = v;
			}
		}
		
		public function setBoundsChangedFlag():void
		{
			if(!_scrollPane && !_trackBounds)
				return;
			
			if(!_boundsChanged)
			{
				_boundsChanged = true;
				GTimers.inst.add(0, 1, __render);
			}
		}

		private function __render():void
		{
			if(_boundsChanged)
				updateBounds();
		}

		public function ensureBoundsCorrect():void
		{
			if(_boundsChanged)
				updateBounds();
		}
		
		protected function updateBounds():void
		{
			var ax:int, ay:int, aw:int, ah:int;
			if(_children.length>0)
			{
				ax = int.MAX_VALUE, ay = int.MAX_VALUE;
				var ar:int = int.MIN_VALUE, ab:int = int.MIN_VALUE;
				var tmp:int;
	
				for each(child in _children)
				{
					child.ensureSizeCorrect();
				}
				
				for each(var child:GObject in _children)
				{
					tmp = child.x;
					if(tmp<ax)
						ax = tmp;
					tmp = child.y;
					if(tmp<ay)
						ay = tmp;
					tmp = child.x + child.actualWidth;
					if(tmp>ar)
						ar = tmp;
					tmp = child.y + child.actualHeight;
					if(tmp>ab)
						ab = tmp;
				}
				aw = ar-ax;
				ah = ab-ay;
			}
			else
			{
				ax = 0;
				ay = 0;
				aw = 0;
				ah = 0;
			}
			if(ax!=_bounds.x || ay!=_bounds.y || aw!=_bounds.width || ah!=_bounds.height)
				setBounds(ax, ay, aw, ah);
			else
				_boundsChanged = false;
		}
		
		protected function setBounds(ax:int, ay:int, aw:int, ah:int):void
		{
			_boundsChanged = false;
			_bounds.x = ax;
			_bounds.y = ay;
			_bounds.width = aw;
			_bounds.height = ah;
			
			if(_scrollPane)
				_scrollPane.setContentSize(_bounds.x+_bounds.width,  _bounds.y+_bounds.height);
		}
		
		public function get bounds():Rectangle
		{
			if(_boundsChanged)
				updateBounds();
			return _bounds;
		}
		
		public function get viewWidth():int
		{
			if (_scrollPane != null)
				return _scrollPane.viewWidth;
			else
				return this.width - _margin.left - _margin.right;
		}
		
		public function set viewWidth(value:int):void
		{
			if (_scrollPane != null)
				_scrollPane.viewWidth = value;
			else
				this.width = value + _margin.left + _margin.right;
		}
		
		public function get viewHeight():int
		{
			if (_scrollPane != null)
				return _scrollPane.viewHeight;
			else
				return this.height - _margin.top - _margin.bottom;
		}
		
		public function set viewHeight(value:int):void
		{
			if (_scrollPane != null)
				_scrollPane.viewHeight = value;
			else
				this.height = value + _margin.top + _margin.bottom;
		}
		
		public function findObjectNear(xValue:Number, yValue:Number, resultPoint:Point=null):Point
		{
			if(!resultPoint)
				resultPoint = new Point();
			
			resultPoint.x = xValue;
			resultPoint.y = yValue;
			return resultPoint;
		}
		
		internal function childSortingOrderChanged(child:GObject, oldValue:int, newValue:int):void
		{
			if (newValue == 0)
			{
				_sortingChildCount--;
				setChildIndex(child, _children.length);
			}
			else
			{
				if (oldValue == 0)
					_sortingChildCount++;
				
				var oldIndex:int = _children.indexOf(child);
				var index:int = getInsertPosForSortingChild(child);
				if (oldIndex < index)
					_setChildIndex(child, oldIndex, index - 1);
				else
					_setChildIndex(child, oldIndex, index);
			}
		}
		
		override public function constructFromResource(pkgItem:PackageItem):void
		{
			_packageItem = pkgItem;
			constructFromXML(_packageItem.owner.getComponentData(_packageItem));
		}
		
		protected function constructFromXML(xml:XML):void
		{
			var str:String;
			var arr:Array;
			
			_underConstruct = true;
			
			str = xml.@size;
			arr = str.split(",");
			_sourceWidth = int(arr[0]);
			_sourceHeight = int(arr[1]);
			_initWidth = _sourceWidth;
			_initHeight = _sourceHeight;
			
			var overflow:int;
			str = xml.@overflow;
			if(str)
				overflow = OverflowType.parse(str);
			else
				overflow = OverflowType.Visible;
			
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
			
			var scrollBarMargin:Margin;
			if(overflow==OverflowType.Scroll)
			{
				scrollBarMargin = new Margin();
				str = xml.@scrollBarMargin;
				if(str)
					scrollBarMargin.parse(str);
			}
			
			str = xml.@margin;
			if(str)
				_margin.parse(str);

			setSize(_sourceWidth, _sourceHeight);
			setupOverflowAndScroll(overflow, scrollBarMargin, scroll, scrollBarDisplay, scrollBarFlags);
			
			_buildingDisplayList = true;
			
			var col:XMLList = xml.controller;
			var controller:Controller;
			for each(var cxml:XML in col)
			{
				controller = new Controller();
				_controllers.push(controller);
				controller._parent = this;
				controller.setup(cxml);
			}

			col = xml.displayList.elements();
			var ename:String;
			var u:GObject;
			for each(cxml in col)
			{
				u = constructChild(cxml);
				if(!u)
					continue;

				u._underConstruct = true;
				u._constructingData = cxml;
				u.setup_beforeAdd(cxml);
				addChild(u);
			}
			
			this.relations.setup(xml);
			var cnt:int = _children.length;
			for(var i:int=0;i<cnt;i++)
			{
				u = _children[i];
				u.relations.setup(u._constructingData);
			}
			
			for(i=0;i<cnt;i++)
			{
				u = _children[i];
				u.setup_afterAdd(u._constructingData);
				u._underConstruct = false;
				u._constructingData = null;
			}
			
			col = xml.transition;
			var trans:Transition;
			for each(cxml in col)
			{
				trans = new Transition(this);
				_transitions.push(trans);
				trans.setup(cxml);
			}
			
			applyAllControllers();
			
			_buildingDisplayList = false;
			_underConstruct = false;
			
			for each(var child:GObject in _children)
			{
				if (child.displayObject != null && child.finalVisible)
					_container.addChild(child.displayObject);
			}
		}
		
		private function constructChild(xml:XML):GObject
		{
			var pkgId:String = xml.@pkg;
			var thisPkg:UIPackage = _packageItem.owner;
			var pkg:UIPackage;
			if(pkgId && pkgId!=thisPkg.id)
			{
				pkg = UIPackage.getById(pkgId);
				if(!pkg)
					return null;
			}
			else
				pkg = thisPkg;
			
			var src:String = xml.@src;
			if(src)
			{
				var pi:PackageItem = pkg.getItemById(src);
				if(!pi)
					return null;
				
				var g:GObject = pkg.createObject2(pi);
				return g;
			}
			else
			{
				var str:String = xml.name().localName;
				if(str=="text" && xml.@input=="true")
					g = new GTextInput();
				else
					g = UIObjectFactory.newObject2(str);
				return g;
			}
		}
	}	
}
