package fairygui
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Mouse;
	import flash.utils.getTimer;
	
	import fairygui.event.GTouchEvent;
	import fairygui.utils.GTimers;
	import fairygui.utils.ToolSet;

	[Event(name = "scroll", type = "flash.events.Event")]
	[Event(name = "scrollEnd", type = "flash.events.Event")]
	[Event(name = "pullDownRelease", type = "flash.events.Event")]
	[Event(name = "pullUpRelease", type = "flash.events.Event")]
	public class ScrollPane extends EventDispatcher
	{
		private var _owner:GComponent;
		private var _container:Sprite;
		private var _maskContainer:Sprite;
		private var _alignContainer:Sprite;
		
		private var _scrollType:int;
		private var _scrollStep:int;
		private var _mouseWheelStep:int;
		private var _decelerationRate:Number;
		private var _scrollBarMargin:Margin;
		private var _bouncebackEffect:Boolean;
		private var _touchEffect:Boolean;
		private var _scrollBarDisplayAuto:Boolean;
		private var _vScrollNone:Boolean;
		private var _hScrollNone:Boolean;
		private var _needRefresh:Boolean;
		private var _refreshBarAxis:String;
		
		private var _displayOnLeft:Boolean;
		private var _snapToItem:Boolean;
		private var _displayInDemand:Boolean;
		private var _mouseWheelEnabled:Boolean;
		private var _pageMode:Boolean;
		private var _inertiaDisabled:Boolean;
		
		private var _xPos:Number;
		private var _yPos:Number;
		
		private var _viewSize:Point;
		private var _contentSize:Point;
		private var _overlapSize:Point;
		private var _pageSize:Point;
		private var _containerPos:Point;
		private var _beginTouchPos:Point;
		private var _lastTouchPos:Point;
		private var _lastTouchGlobalPos:Point;
		private var _velocity:Point;
		private var _velocityScale:Number;
		private var _lastMoveTime:Number;
		private var _isHoldAreaDone:Boolean;
		private var _aniFlag:int;
		private var _scrollBarVisible:Boolean;
		internal var _loop:int;
		private var _headerLockedSize:int;
		private var _footerLockedSize:int;
		private var _refreshEventDispatching:Boolean;
		
		private var _tweening:int;
		private var _tweenTime:Point;
		private var _tweenDuration:Point;
		private var _tweenStart:Point;
		private var _tweenChange:Point;

		private var _pageController:Controller;
		
		private var _hzScrollBar:GScrollBar;
		private var _vtScrollBar:GScrollBar;
		private var _header:GComponent;
		private var _footer:GComponent;
		
		public var isDragged:Boolean;
		public static var draggingPane:ScrollPane;
		private static var _gestureFlag:int = 0;
		
		private static var sHelperPoint:Point = new Point();
		private static var sHelperRect:Rectangle = new Rectangle();
		private static var sEndPos:Point = new Point();
		private static var sOldChange:Point = new Point();
		
		public static const SCROLL_END:String = "scrollEnd";
		public static const PULL_DOWN_RELEASE:String = "pullDownRelease";
		public static const PULL_UP_RELEASE:String = "pullUpRelease";
		
		public static const TWEEN_TIME_GO:Number = 0.5; //调用SetPos(ani)时使用的缓动时间
		public static const TWEEN_TIME_DEFAULT:Number = 0.3; //惯性滚动的最小缓动时间
		public static const PULL_RATIO:Number = 0.5; //下拉过顶或者上拉过底时允许超过的距离占显示区域的比例
		
		public function ScrollPane(owner:GComponent, 
								   scrollType:int,
								   scrollBarMargin:Margin,
								   scrollBarDisplay:int,
								   flags:int,
								   vtScrollBarRes:String,
								   hzScrollBarRes:String,
								   headerRes:String,
								   footerRes:String):void
		{
			_owner = owner;
			owner.opaque = true;
			
			_maskContainer = new Sprite();
			_maskContainer.mouseEnabled = false;
			_owner._rootContainer.addChild(_maskContainer);
			
			_container = _owner._container;
			_container.x = 0;
			_container.y = 0;
			_container.mouseEnabled = false;			
			_maskContainer.addChild(_container);
			
			_scrollBarMargin = scrollBarMargin;
			_scrollType = scrollType;
			_scrollStep = UIConfig.defaultScrollStep;
			_mouseWheelStep = _scrollStep*2;
			_decelerationRate = UIConfig.defaultScrollDecelerationRate;
			
			_displayOnLeft = (flags & 1)!=0;
			_snapToItem = (flags & 2)!=0;
			_displayInDemand = (flags & 4)!=0;
			_pageMode = (flags & 8)!=0;
			if(flags & 16)
				_touchEffect = true;
			else if(flags & 32)
				_touchEffect = false;
			else
				_touchEffect = UIConfig.defaultScrollTouchEffect;
			if(flags & 64)
				_bouncebackEffect = true;
			else if(flags & 128)
				_bouncebackEffect = false;
			else
				_bouncebackEffect = UIConfig.defaultScrollBounceEffect;
			_inertiaDisabled = (flags & 256)!=0;
			if((flags & 512) == 0)
				_maskContainer.scrollRect = new Rectangle();
			
			_scrollBarVisible = true;
			_mouseWheelEnabled = true;
			_xPos = 0;
			_yPos = 0;
			_aniFlag = 0;
			_footerLockedSize = 0;
			_headerLockedSize = 0;
			
			if(scrollBarDisplay==ScrollBarDisplayType.Default)
				scrollBarDisplay = UIConfig.defaultScrollBarDisplay;
			
			_viewSize = new Point();
			_contentSize = new Point();
			_pageSize = new Point(1,1);
			_overlapSize = new Point();
			_tweenTime = new Point();
			_tweenStart = new Point();
			_tweenDuration = new Point();
			_tweenChange = new Point();
			_velocity = new Point();
			_containerPos = new Point();
			_beginTouchPos = new Point();
			_lastTouchPos = new Point();
			_lastTouchGlobalPos = new Point();
			
			if(scrollBarDisplay!=ScrollBarDisplayType.Hidden)
			{
				if(_scrollType==ScrollType.Both || _scrollType==ScrollType.Vertical)
				{
					var res:String = vtScrollBarRes?vtScrollBarRes:UIConfig.verticalScrollBar;
					if(res)
					{
						_vtScrollBar = UIPackage.createObjectFromURL(res) as GScrollBar;
						if(!_vtScrollBar)
							throw new Error("cannot create scrollbar from " + res);
						_vtScrollBar.setScrollPane(this, true);
						_owner._rootContainer.addChild(_vtScrollBar.displayObject);
					}
				}
				if(_scrollType==ScrollType.Both || _scrollType==ScrollType.Horizontal)
				{
					res = hzScrollBarRes?hzScrollBarRes:UIConfig.horizontalScrollBar;
					if(res)
					{
						_hzScrollBar = UIPackage.createObjectFromURL(res) as GScrollBar;
						if(!_hzScrollBar)
							throw new Error("cannot create scrollbar from " + res);
						_hzScrollBar.setScrollPane(this, false);
						_owner._rootContainer.addChild(_hzScrollBar.displayObject);
					}
				}
				
				_scrollBarDisplayAuto = scrollBarDisplay==ScrollBarDisplayType.Auto;
				if(_scrollBarDisplayAuto)
				{
					_scrollBarVisible = false;
					if(_vtScrollBar)
						_vtScrollBar.displayObject.visible = false;
					if(_hzScrollBar)
						_hzScrollBar.displayObject.visible = false;
					
					if(Mouse.supportsCursor)
					{
						_owner._rootContainer.addEventListener(MouseEvent.ROLL_OVER, __rollOver);
						_owner._rootContainer.addEventListener(MouseEvent.ROLL_OUT, __rollOut);
					}
				}
			}
			else
				_mouseWheelEnabled = false;
			
			if (headerRes)
			{
				_header = UIPackage.createObjectFromURL(headerRes) as GComponent;
				if (_header == null)
					throw new Error("FairyGUI: cannot create scrollPane header from " + headerRes);
			}
			
			if (footerRes)
			{
				_footer = UIPackage.createObjectFromURL(footerRes) as GComponent;
				if (_footer == null)
					throw new Error("FairyGUI: cannot create scrollPane footer from " + footerRes);
			}
			
			if (_header != null || _footer != null)
				_refreshBarAxis = (_scrollType == ScrollType.Both || _scrollType == ScrollType.Vertical) ? "y" : "x";
			
			setSize(owner.width, owner.height);
			
			_owner._rootContainer.addEventListener(MouseEvent.MOUSE_WHEEL, __mouseWheel);
			_owner.addEventListener(GTouchEvent.BEGIN, __mouseDown);
			_owner.addEventListener(GTouchEvent.END, __mouseUp);
		}
		
		public function dispose():void
		{
			if (_tweening != 0)
				GTimers.inst.remove(tweenUpdate);
			
			_pageController = null;
			
			if (_hzScrollBar != null)
				_hzScrollBar.dispose();
			if (_vtScrollBar != null)
				_vtScrollBar.dispose();
			if (_header != null)
				_header.dispose();
			if (_footer != null)
				_footer.dispose();	
		}
		
		public function get owner():GComponent
		{
			return _owner;
		}
		
		public function get hzScrollBar(): GScrollBar {
			return this._hzScrollBar;
		}
		
		public function get vtScrollBar(): GScrollBar {
			return this._vtScrollBar;
		}
		
		public function get header():GComponent
		{
			return _header;
		}
		
		public function get footer():GComponent
		{
			return _footer;
		}
		
		public function get bouncebackEffect():Boolean
		{
			return _bouncebackEffect;
		}
		
		public function set bouncebackEffect(sc:Boolean):void
		{
			_bouncebackEffect = sc;
		}
		
		public function get touchEffect():Boolean
		{
			return _touchEffect;
		}
		
		public function set touchEffect(sc:Boolean):void
		{
			_touchEffect = sc;
		}
		
		[Deprecated(replacement="ScrollPane.scrollStep")]
		public function set scrollSpeed(val:int):void
		{
			this.scrollStep = val;
		}
		
		[Deprecated(replacement="ScrollPane.scrollStep")]
		public function get scrollSpeed():int
		{
			return this.scrollStep;
		}
		
		public function set scrollStep(val:int):void
		{
			_scrollStep = val;
			if(_scrollStep==0)
				_scrollStep = UIConfig.defaultScrollStep;
			_mouseWheelStep = _scrollStep*2;
		}
		
		public function get scrollStep():int
		{
			return _scrollStep;
		}
		
		public function get snapToItem():Boolean
		{
			return _snapToItem;
		}
		
		public function set snapToItem(value:Boolean):void
		{
			_snapToItem = value;
		}
		
		public function get mouseWheelEnabled():Boolean
		{
			return _mouseWheelEnabled;
		}
		
		public function set mouseWheelEnabled(value:Boolean):void
		{
			_mouseWheelEnabled = value;
		}
		
		public function get decelerationRate():Number
		{
			return _decelerationRate;
		}
		
		public function set decelerationRate(value:Number):void
		{
			_decelerationRate = value;
		}
		
		public function get percX():Number
		{
			return _overlapSize.x == 0 ? 0 : _xPos / _overlapSize.x;
		}
		
		public function set percX(value:Number):void
		{
			setPercX(value, false);
		}
		
		public function setPercX(value:Number, ani:Boolean=false):void
		{
			_owner.ensureBoundsCorrect();
			setPosX(_overlapSize.x * ToolSet.clamp01(value), ani);
		}
		
		public function get percY():Number
		{
			return _overlapSize.y == 0 ? 0 : _yPos / _overlapSize.y;
		}
		
		public function set percY(value:Number):void
		{
			setPercY(value, false);
		}
		
		public function setPercY(value:Number, ani:Boolean=false):void
		{
			_owner.ensureBoundsCorrect();
			setPosY(_overlapSize.y * ToolSet.clamp01(value), ani);
		}
		
		public function get posX():Number
		{
			return _xPos;
		}
		
		public function set posX(value:Number):void 
		{
			setPosX(value, false);
		}
		
		public function setPosX(value:Number, ani:Boolean=false):void
		{
			_owner.ensureBoundsCorrect();
			
			if (_loop == 1)
				value = loopCheckingNewPos(value, "x");
			
			value = ToolSet.clamp(value, 0, _overlapSize.x);
			if (value != _xPos)
			{
				_xPos = value;
				posChanged(ani);
			}
		}
		
		public function get posY():Number 
		{
			return _yPos;
		}
		
		public function set posY(value:Number):void
		{
			setPosY(value, false);
		}
		
		public function setPosY(value:Number, ani:Boolean=false):void
		{
			_owner.ensureBoundsCorrect();
			
			if (_loop == 1)
				value = loopCheckingNewPos(value, "y");
			
			value = ToolSet.clamp(value, 0, _overlapSize.y);
			if (value != _yPos)
			{
				_yPos = value;
				posChanged(ani);
			}
		}
		
		public function get contentWidth():Number
		{
			return _contentSize.x;
		}
		
		public function get contentHeight():Number
		{
			return _contentSize.y;
		}
		
		public function get viewWidth():int
		{
			return _viewSize.x;
		}
		
		public function set viewWidth(value:int):void
		{
			value = value + _owner.margin.left + _owner.margin.right;
			if (_vtScrollBar != null)
				value += _vtScrollBar.width;
			_owner.width = value;
		}
		
		public function get viewHeight():int
		{
			return _viewSize.y;
		}
		
		public function set viewHeight(value:int):void
		{
			value = value + _owner.margin.top + _owner.margin.bottom;
			if (_hzScrollBar != null)
				value += _hzScrollBar.height;
			_owner.height = value;
		}
		
		public function get currentPageX():int
		{
			if (!_pageMode)
				return 0;
			
			var page:int = Math.floor(_xPos / _pageSize.x);
			if (_xPos - page * _pageSize.x > _pageSize.x * 0.5)
				page++;
			
			return page;
		}
		
		public function set currentPageX(value:int):void
		{
			setCurrentPageX(value, false);
		}
		
		public function get currentPageY():int
		{
			if (!_pageMode)
				return 0;
			
			var page:int = Math.floor(_yPos / _pageSize.y);
			if (_yPos - page * _pageSize.y > _pageSize.y * 0.5)
				page++;
			
			return page;
		}
		
		public function set currentPageY(value:int):void
		{
			setCurrentPageY(value, false);
		}
		
		public function setCurrentPageX(value:int, ani:Boolean):void
		{
			if (_pageMode && _overlapSize.x>0)
				this.setPosX(value * _pageSize.x, ani);
		}
		
		public function setCurrentPageY(value:int, ani:Boolean):void
		{
			if (_pageMode && _overlapSize.y>0)
				this.setPosY(value * _pageSize.y, ani);
		}
		
		
		public function get isBottomMost():Boolean
		{
			return _yPos == _overlapSize.y || _overlapSize.y == 0;
		}
		
		public function get isRightMost():Boolean
		{
			return _xPos == _overlapSize.x || _overlapSize.x == 0; 
		}
		
		public function get pageController():Controller
		{
			return _pageController;
		}
		
		public function set pageController(value:Controller):void
		{
			_pageController = value;
		}
		
		public function get scrollingPosX():Number
		{
			return ToolSet.clamp(-_container.x, 0, _overlapSize.x);
		}
		
		public function get scrollingPosY():Number
		{
			return ToolSet.clamp(-_container.y, 0, _overlapSize.y);
		}
		
		public function scrollTop(ani:Boolean=false):void 
		{
			this.setPercY(0, ani);
		}
		
		public function scrollBottom(ani:Boolean=false):void 
		{
			this.setPercY(1, ani);
		}
		
		public function scrollUp(ratio:Number=1, ani:Boolean=false):void 
		{
			if (_pageMode)
				setPosY(_yPos - _pageSize.y * ratio, ani);
			else
				setPosY(_yPos - _scrollStep * ratio, ani);;
		}
		
		public function scrollDown(ratio:Number=1, ani:Boolean=false):void
		{
			if (_pageMode)
				setPosY(_yPos + _pageSize.y * ratio, ani);
			else
				setPosY(_yPos + _scrollStep * ratio, ani);
		}
		
		public function scrollLeft(ratio:Number=1, ani:Boolean=false):void
		{
			if (_pageMode)
				setPosX(_xPos - _pageSize.x * ratio, ani);
			else
				setPosX(_xPos - _scrollStep * ratio, ani);
		}
		
		public function scrollRight(ratio:Number=1, ani:Boolean=false):void　
		{
			if (_pageMode)
				setPosX(_xPos + _pageSize.x * ratio, ani);
			else
				setPosX(_xPos + _scrollStep * ratio, ani);
		}
		
		/**
		 * @param target GObject: can be any object on stage, not limited to the direct child of this container.
		 * 				or Rectangle: Rect in local coordinates
		 * @param ani If moving to target position with animation
		 * @param setFirst If true, scroll to make the target on the top/left; If false, scroll to make the target any position in view.
		 */
		public function scrollToView(target:*, ani:Boolean=false, setFirst:Boolean=false):void
		{
			_owner.ensureBoundsCorrect();
			if(_needRefresh)
				refresh();
			
			var rect:Rectangle;
			if(target is GObject)
			{
				if (target.parent != _owner)
				{
					GObject(target).parent.localToGlobalRect(target.x, target.y, 
						target.width, target.height, sHelperRect);
					rect = _owner.globalToLocalRect(sHelperRect.x, sHelperRect.y, 
						sHelperRect.width, sHelperRect.height, sHelperRect);
				}
				else
				{
					rect = sHelperRect;
					rect.setTo(target.x, target.y, target.width, target.height);					
				}
			}
			else
				rect = Rectangle(target);			
			
			
			if(_overlapSize.y>0)
			{
				var bottom:Number = _yPos+_viewSize.y;
				if(setFirst || rect.y<=_yPos || rect.height>=_viewSize.y)
				{
					if(_pageMode)
						this.setPosY(Math.floor(rect.y/_pageSize.y)*_pageSize.y, ani);
					else
						this.setPosY(rect.y, ani);
				}
				else if(rect.y+rect.height>bottom)
				{
					if(_pageMode)
						this.setPosY(Math.floor(rect.y/_pageSize.y)*_pageSize.y, ani);
					else if (rect.height <= _viewSize.y/2)
						this.setPosY(rect.y+rect.height*2-_viewSize.y, ani);
					else
						this.setPosY(rect.y+rect.height-_viewSize.y, ani);
				}
			}
			if(_overlapSize.x>0)
			{
				var right:Number = _xPos+_viewSize.x;
				if(setFirst || rect.x<=_xPos || rect.width>=_viewSize.x)
				{
					if(_pageMode)
						this.setPosX(Math.floor(rect.x/_pageSize.x)*_pageSize.x, ani);
					else
						this.setPosX(rect.x, ani);
				}
				else if(rect.x+rect.width>right)
				{
					if(_pageMode)
						this.setPosX(Math.floor(rect.x/_pageSize.x)*_pageSize.x, ani);
					else if (rect.width <= _viewSize.x/2)
						this.setPosX(rect.x+rect.width*2-_viewSize.x, ani);
					else
						this.setPosX(rect.x+rect.width-_viewSize.x, ani);
				}
			}
			
			if(!ani && _needRefresh)
				refresh();
		}
		
		/**
		 * @param obj obj must be the direct child of this container
		 */
		public function isChildInView(obj:GObject):Boolean
		{
			if(_overlapSize.y>0)
			{
				var dist:Number = obj.y+_container.y;
				if(dist<-obj.height || dist>_viewSize.y)
					return false;
			}
			
			if(_overlapSize.x>0)
			{
				dist = obj.x + _container.x;
				if(dist<-obj.width || dist>_viewSize.x)
					return false;
			}
			
			return true;
		}
		
		public function cancelDragging():void
		{
			_owner.removeEventListener(GTouchEvent.DRAG, __mouseMove);
			
			if (draggingPane == this)
				draggingPane = null;
			
			_gestureFlag = 0;
			isDragged = false;
			_maskContainer.mouseChildren = true;
		}
		
		public function lockHeader(size:int):void
		{
			if (_headerLockedSize == size)
				return;
			
			_headerLockedSize = size;
			
			if (!_refreshEventDispatching && _container[_refreshBarAxis] >= 0)
			{
				_tweenStart.setTo(_container.x, _container.y);
				_tweenChange.setTo(0,0);
				_tweenChange[_refreshBarAxis] = _headerLockedSize - _tweenStart[_refreshBarAxis];
				_tweenDuration.setTo(TWEEN_TIME_DEFAULT, TWEEN_TIME_DEFAULT);
				_tweenTime.setTo(0,0);
				_tweening = 2;
				GTimers.inst.callBy60Fps(tweenUpdate);
			}
		}

		public function lockFooter(size:int):void
		{
			if (_footerLockedSize == size)
				return;
			
			_footerLockedSize = size;
			
			if (!_refreshEventDispatching && _container[_refreshBarAxis] <= -_overlapSize[_refreshBarAxis])
			{
				_tweenStart.setTo(_container.x, _container.y);
				_tweenChange.setTo(0,0);
				var max:Number = _overlapSize[_refreshBarAxis];
				if (max == 0)
					max = Math.max(_contentSize[_refreshBarAxis] + _footerLockedSize - _viewSize[_refreshBarAxis], 0);
				else
					max += _footerLockedSize;
				_tweenChange[_refreshBarAxis] = -max - _tweenStart[_refreshBarAxis];
				_tweenDuration.setTo(TWEEN_TIME_DEFAULT, TWEEN_TIME_DEFAULT);
				_tweenTime.setTo(0,0);
				_tweening = 2;
				GTimers.inst.callBy60Fps(tweenUpdate);
			}
		}
		
		internal function onOwnerSizeChanged():void
		{
			setSize(_owner.width, _owner.height);
			posChanged(false);
		}
		
		internal function handleControllerChanged(c:Controller):void
		{
			if (_pageController == c)
			{
				if (_scrollType == ScrollType.Horizontal)
					this.setCurrentPageX(c.selectedIndex, true);
				else
					this.setCurrentPageY(c.selectedIndex, true);
			}
		}
		
		private function updatePageController():void
		{
			if (_pageController != null && !_pageController.changing)
			{
				var index:int;
				if (_scrollType == ScrollType.Horizontal)
					index = this.currentPageX;
				else
					index = this.currentPageY;
				if (index < _pageController.pageCount)
				{
					var c:Controller = _pageController;
					_pageController = null; //防止HandleControllerChanged的调用
					c.selectedIndex = index;
					_pageController = c;
				}
			}
		}
		
		internal function adjustMaskContainer():void
		{
			var mx:Number, my:Number;
			if (_displayOnLeft && _vtScrollBar != null)
				mx = Math.floor(_owner.margin.left + _vtScrollBar.width);
			else
				mx = Math.floor(_owner.margin.left);
			my = Math.floor(_owner.margin.top);
			
			_maskContainer.x = mx;
			_maskContainer.y = my;
			
			if(_owner._alignOffset.x!=0 || _owner._alignOffset.y!=0)
			{
				if(_alignContainer==null)
				{
					_alignContainer = new Sprite();
					_alignContainer.mouseEnabled = false;
					_maskContainer.addChild(_alignContainer);
					_alignContainer.addChild(_container);
				}
				
				_alignContainer.x = _owner._alignOffset.x;
				_alignContainer.y = _owner._alignOffset.y;
			}
			else if(_alignContainer)
			{
				_alignContainer.x = _alignContainer.y = 0;
			}
		}
		
		private function setSize(aWidth:Number, aHeight:Number):void 
		{
			adjustMaskContainer();
			
			if(_hzScrollBar)
			{
				_hzScrollBar.y = aHeight - _hzScrollBar.height;
				if(_vtScrollBar)
				{
					_hzScrollBar.width = aWidth - _vtScrollBar.width - _scrollBarMargin.left - _scrollBarMargin.right;
					if(_displayOnLeft)
						_hzScrollBar.x = _scrollBarMargin.left + _vtScrollBar.width;
					else
						_hzScrollBar.x = _scrollBarMargin.left;
				}
				else
				{
					_hzScrollBar.width = aWidth - _scrollBarMargin.left - _scrollBarMargin.right;
					_hzScrollBar.x = _scrollBarMargin.left;
				}
			}
			if(_vtScrollBar)
			{
				if(!_displayOnLeft)
					_vtScrollBar.x = aWidth - _vtScrollBar.width;
				if(_hzScrollBar)
					_vtScrollBar.height = aHeight - _hzScrollBar.height - _scrollBarMargin.top - _scrollBarMargin.bottom;
				else
					_vtScrollBar.height = aHeight - _scrollBarMargin.top - _scrollBarMargin.bottom;
				_vtScrollBar.y = _scrollBarMargin.top;
			}
			
			_viewSize.x = aWidth;
			_viewSize.y = aHeight;
			if(_hzScrollBar && !_hScrollNone)
				_viewSize.y -= _hzScrollBar.height;
			if(_vtScrollBar && !_vScrollNone)
				_viewSize.x -= _vtScrollBar.width;
			_viewSize.x -= (_owner.margin.left+_owner.margin.right);
			_viewSize.y -= (_owner.margin.top+_owner.margin.bottom);
			
			_viewSize.x = Math.max(1, _viewSize.x);
			_viewSize.y = Math.max(1, _viewSize.y);
			_pageSize.x = _viewSize.x;
			_pageSize.y = _viewSize.y;
			
			handleSizeChanged();
		}
		
		internal function setContentSize(aWidth:Number, aHeight:Number):void
		{
			if(_contentSize.x==aWidth && _contentSize.y==aHeight)
				return;
			
			_contentSize.x = aWidth;
			_contentSize.y = aHeight;
			handleSizeChanged();
		}
		
		internal function changeContentSizeOnScrolling(deltaWidth:Number, deltaHeight:Number,
													   deltaPosX:Number, deltaPosY:Number):void
		{
			var isRightmost:Boolean = _xPos == _overlapSize.x;
			var isBottom:Boolean = _yPos == _overlapSize.y;
			
			_contentSize.x += deltaWidth;
			_contentSize.y += deltaHeight;
			handleSizeChanged();
			
			if (_tweening == 1)
			{
				//如果原来滚动位置是贴边，加入处理继续贴边。
				if (deltaWidth != 0 && isRightmost && _tweenChange.x < 0)
				{
					_xPos = _overlapSize.x;
					_tweenChange.x = -_xPos - _tweenStart.x;
				}
				
				if (deltaHeight != 0 && isBottom && _tweenChange.y < 0)
				{
					_yPos = _overlapSize.y;
					_tweenChange.y = -_yPos - _tweenStart.y;
				}
			}
			else if (_tweening == 2)
			{
				//重新调整起始位置，确保能够顺滑滚下去
				if (deltaPosX != 0)
				{
					_container.x -= deltaPosX;
					_tweenStart.x -= deltaPosX;
					_xPos = -_container.x;
				}
				if (deltaPosY != 0)
				{
					_container.y -= deltaPosY;
					_tweenStart.y -= deltaPosY;
					_yPos = -_container.y;
				}
			}
			else if (isDragged)
			{
				if (deltaPosX != 0)
				{
					_container.x -= deltaPosX;
					_containerPos.x -= deltaPosX;
					_xPos = -_container.x;
				}
				if (deltaPosY != 0)
				{
					_container.y -= deltaPosY;
					_containerPos.y -= deltaPosY;
					_yPos = -_container.y;
				}
			}
			else
			{
				//如果原来滚动位置是贴边，加入处理继续贴边。
				if (deltaWidth != 0 && isRightmost)
				{
					_xPos = _overlapSize.x;
					_container.x = -_xPos;
				}
				
				if (deltaHeight != 0 && isBottom)
				{
					_yPos = _overlapSize.y;
					_container.y = -_yPos;
				}
			}
			
			if (_pageMode)
				updatePageController();
		}
		
		private function handleSizeChanged(onScrolling:Boolean=false):void
		{
			if(_displayInDemand)
			{
				if(_vtScrollBar)
				{
					if(_contentSize.y<=_viewSize.y)
					{
						if(!_vScrollNone)
						{
							_vScrollNone = true;
							_viewSize.x += _vtScrollBar.width;
						}
					}
					else
					{
						if(_vScrollNone)
						{
							_vScrollNone = false;
							_viewSize.x -= _vtScrollBar.width;
						}
					}
				}
				if(_hzScrollBar)
				{
					if(_contentSize.x<=_viewSize.x)
					{
						if(!_hScrollNone)
						{
							_hScrollNone = true;
							_viewSize.y += _hzScrollBar.height;
						}
					}
					else
					{
						if(_hScrollNone)
						{
							_hScrollNone = false;
							_viewSize.y -= _hzScrollBar.height;
						}
					}
				}
			}
			
			if(_vtScrollBar)
			{
				if(_viewSize.y<_vtScrollBar.minSize)
					//没有使用_vtScrollBar.visible是因为ScrollBar用了一个trick，它并不在owner的DisplayList里，因此_vtScrollBar.visible是无效的
					_vtScrollBar.displayObject.visible = false;
				else
				{
					_vtScrollBar.displayObject.visible = _scrollBarVisible && !_vScrollNone;
					if(_contentSize.y==0)
						_vtScrollBar.displayPerc = 0;
					else
						_vtScrollBar.displayPerc = Math.min(1, _viewSize.y/_contentSize.y);
				}
			}
			if(_hzScrollBar)
			{
				if(_viewSize.x<_hzScrollBar.minSize)
					_hzScrollBar.displayObject.visible = false;
				else
				{
					_hzScrollBar.displayObject.visible = _scrollBarVisible && !_hScrollNone;
					if(_contentSize.x==0)
						_hzScrollBar.displayPerc = 0;
					else
						_hzScrollBar.displayPerc = Math.min(1, _viewSize.x/_contentSize.x);
				}
			}
			
			var rect:Rectangle = _maskContainer.scrollRect;
			if (rect)
			{
				rect.width = _viewSize.x;
				rect.height = _viewSize.y;
				_maskContainer.scrollRect = rect;
			}
			
			if (_scrollType == ScrollType.Horizontal || _scrollType == ScrollType.Both)
				_overlapSize.x = Math.ceil(Math.max(0, _contentSize.x - _viewSize.x));
			else
				_overlapSize.x = 0;
			if (_scrollType == ScrollType.Vertical || _scrollType == ScrollType.Both)
				_overlapSize.y = Math.ceil(Math.max(0, _contentSize.y - _viewSize.y));
			else
				_overlapSize.y = 0;
			
			//边界检查
			_xPos = ToolSet.clamp(_xPos, 0, _overlapSize.x);
			_yPos = ToolSet.clamp(_yPos, 0, _overlapSize.y);
			if(_refreshBarAxis!=null)
			{
				var max:Number = _overlapSize[_refreshBarAxis];
				if (max == 0)
					max = Math.max(_contentSize[_refreshBarAxis] + _footerLockedSize - _viewSize[_refreshBarAxis], 0);
				else
					max += _footerLockedSize;
			
				if (_refreshBarAxis == "x")
				{
					_container.x = ToolSet.clamp(_container.x, -max, _headerLockedSize);
					_container.y = ToolSet.clamp(_container.y, -_overlapSize.y, 0);
				}
				else
				{
					_container.x = ToolSet.clamp(_container.x, -_overlapSize.x, 0);
					_container.y = ToolSet.clamp(_container.y, -max, _headerLockedSize);
				}
				
				if (_header != null)
				{
					if (_refreshBarAxis == "x")
						_header.height = _viewSize.y;
					else
						_header.width = _viewSize.x;
				}
				
				if (_footer != null)
				{
					if (_refreshBarAxis == "y")
						_footer.height = _viewSize.y;
					else
						_footer.width = _viewSize.x;
				}
			}
			else
			{
				_container.x = ToolSet.clamp(_container.x, -_overlapSize.x, 0);
				_container.y = ToolSet.clamp(_container.y, -_overlapSize.y, 0);
			}
			
			syncScrollBar();
			checkRefreshBar();
			if (_pageMode)
				updatePageController();
		}
		
		private function posChanged(ani:Boolean):void
		{
			if (_aniFlag == 0)
				_aniFlag = ani ? 1 : -1;
			else if (_aniFlag == 1 && !ani)
				_aniFlag = -1;
			
			_needRefresh = true;
			GTimers.inst.callLater(refresh);
		}
		
		private function refresh():void
		{
			_needRefresh = false;
			GTimers.inst.remove(refresh);
			
			if (_pageMode || _snapToItem)
			{
				sEndPos.setTo(-_xPos, -_yPos);
				alignPosition(sEndPos, false);
				_xPos = -sEndPos.x;
				_yPos = -sEndPos.y;
			}
			
			refresh2();
			
			dispatchEvent(new Event(Event.SCROLL));
			if (_needRefresh) //在onScroll事件里开发者可能修改位置，这里再刷新一次，避免闪烁
			{
				_needRefresh = false;
				GTimers.inst.remove(refresh);
				
				refresh2();
			}
			
			syncScrollBar();
			_aniFlag = 0;
		}
		
		private function refresh2():void
		{
			if (_aniFlag == 1 && !isDragged)
			{
				var posX:Number;
				var posY:Number;
				
				if (_overlapSize.x > 0)
					posX = -int(_xPos);
				else
				{
					if (_container.x != 0)
						_container.x = 0;
					posX = 0;
				}
				if (_overlapSize.y > 0)
					posY = -int(_yPos);
				else
				{
					if (_container.y != 0)
						_container.y = 0;
					posY = 0;
				}
				
				if (posX != _container.x || posY != _container.y)
				{
					_tweening = 1;
					_tweenTime.setTo(0,0);
					_tweenDuration.setTo(TWEEN_TIME_GO, TWEEN_TIME_GO);
					_tweenStart.setTo(_container.x, _container.y);
					_tweenChange.setTo(posX - _tweenStart.x, posY - _tweenStart.y);
					GTimers.inst.callBy60Fps(tweenUpdate);
				}
				else if (_tweening != 0)
					killTween();
			}
			else
			{
				if (_tweening != 0)
					killTween();
				
				_container.x = int(-_xPos);
				_container.y = int(-_yPos);
				
				loopCheckingCurrent();
			}
			
			if (_pageMode)
				updatePageController();
		}
		
		private function syncScrollBar(end:Boolean=false):void
		{
			if (_vtScrollBar != null)
			{
				_vtScrollBar.scrollPerc = _overlapSize.y == 0 ? 0 : ToolSet.clamp(-_container.y, 0, _overlapSize.y) / _overlapSize.y;
				if (_scrollBarDisplayAuto)
					showScrollBar(!end);
			}
			if (_hzScrollBar != null)
			{
				_hzScrollBar.scrollPerc = _overlapSize.x == 0 ? 0 : ToolSet.clamp(-_container.x, 0, _overlapSize.x) / _overlapSize.x;
				if (_scrollBarDisplayAuto)
					showScrollBar(!end);
			}
			
			if(end)
				_maskContainer.mouseChildren = true;
		}
		
		private function __mouseDown(evt:GTouchEvent):void
		{
			if(!_touchEffect)
				return;
			
			if(_tweening!=0)
			{
				killTween();
				isDragged = true;
			}
			else
				isDragged = false;

			var pt:Point = _owner.globalToLocal(evt.stageX, evt.stageY);
			
			_containerPos.setTo(_container.x, _container.y);
			_beginTouchPos.copyFrom(pt);
			_lastTouchPos.copyFrom(pt);
			_lastTouchGlobalPos.setTo(evt.stageX, evt.stageY);
			_isHoldAreaDone = false;
			_velocity.setTo(0,0);
			_velocityScale = 1;
			_lastMoveTime = getTimer()/1000;
			
			_owner.addEventListener(GTouchEvent.DRAG, __mouseMove);
		}
		
		private function __mouseMove(evt:GTouchEvent):void
		{
			if(!_touchEffect)
				return;
			
			if (draggingPane != null && draggingPane != this || GObject.draggingObject != null) //已经有其他拖动
				return;
			
			var pt:Point = _owner.globalToLocal(evt.stageX, evt.stageY);
			
			var sensitivity:int;
			if (GRoot.touchScreen)
				sensitivity = UIConfig.touchScrollSensitivity;
			else
				sensitivity = 8;
			
			var diff:Number, diff2:Number;
			var sv:Boolean, sh:Boolean, st:Boolean;
			
			if (_scrollType == ScrollType.Vertical) 
			{
				if (!_isHoldAreaDone)
				{
					//表示正在监测垂直方向的手势
					_gestureFlag |= 1;
					
					diff = Math.abs(_beginTouchPos.y - pt.y);
					if (diff < sensitivity)
						return;
					
					if ((_gestureFlag & 2) != 0) //已经有水平方向的手势在监测，那么我们用严格的方式检查是不是按垂直方向移动，避免冲突
					{
						diff2 = Math.abs(_beginTouchPos.x - pt.x);
						if (diff < diff2) //不通过则不允许滚动了
							return;
					}
				}
				
				sv = true;
			}
			else if (_scrollType == ScrollType.Horizontal) 
			{
				if (!_isHoldAreaDone)
				{
					_gestureFlag |= 2;
					
					diff = Math.abs(_beginTouchPos.x - pt.x);
					if (diff < sensitivity)
						return;
					
					if ((_gestureFlag & 1) != 0)
					{
						diff2 = Math.abs(_beginTouchPos.y - pt.y);
						if (diff < diff2)
							return;
					}
				}
				
				sh = true;
			}
			else
			{
				_gestureFlag = 3;
				
				if (!_isHoldAreaDone)
				{
					diff = Math.abs(_beginTouchPos.y - pt.y);
					if (diff < sensitivity)
					{
						diff = Math.abs(_beginTouchPos.x - pt.x);
						if (diff < sensitivity)
							return;
					}
				}
				
				sv = sh = true;
			}
			
			var newPosX:Number = int(_containerPos.x + pt.x - _beginTouchPos.x);
			var newPosY:Number = int(_containerPos.y + pt.y - _beginTouchPos.y);
			
			if (sv)
			{
				if (newPosY > 0)
				{
					if (!_bouncebackEffect)
						_container.y = 0;
					else if (_header != null && _header.maxHeight != 0)
						_container.y = int(Math.min(newPosY * 0.5, _header.maxHeight));
					else
						_container.y = int(Math.min(newPosY * 0.5, _viewSize.y * PULL_RATIO));
				}
				else if (newPosY < -_overlapSize.y)
				{
					if (!_bouncebackEffect)
						_container.y = -_overlapSize.y;
					else if (_footer != null && _footer.maxHeight > 0)
						_container.y = int(Math.max((newPosY + _overlapSize.y) * 0.5, -_footer.maxHeight) - _overlapSize.y);
					else
					_container.y = int(Math.max((newPosY + _overlapSize.y) * 0.5, -_viewSize.y * PULL_RATIO) - _overlapSize.y);
				}
				else
					_container.y = newPosY;
			}
			
			if (sh)
			{
				if (newPosX > 0)
				{
					if (!_bouncebackEffect)
						_container.x = 0;
					else if (_header != null && _header.maxWidth != 0)
						_container.x = int(Math.min(newPosX * 0.5, _header.maxWidth));
					else
						_container.x = int(Math.min(newPosX * 0.5, _viewSize.x * PULL_RATIO));
				}
				else if (newPosX < 0 - _overlapSize.x)
				{
					if (!_bouncebackEffect)
						_container.x = -_overlapSize.x;
					else if (_footer != null && _footer.maxWidth > 0)
						_container.x = int(Math.max((newPosX + _overlapSize.x) * 0.5, -_footer.maxWidth) - _overlapSize.x);
					else
						_container.x = int(Math.max((newPosX + _overlapSize.x) * 0.5, -_viewSize.x * PULL_RATIO) - _overlapSize.x);
				}
				else
					_container.x = newPosX;
			}
			
			
			//更新速度
			var frameRate:Number = _owner.displayObject.stage.frameRate;
			var now:Number = getTimer()/1000;
			var deltaTime:Number = Math.max(now - _lastMoveTime, 1/frameRate);
			var deltaPositionX:Number = pt.x - _lastTouchPos.x;
			var deltaPositionY:Number = pt.y - _lastTouchPos.y;
			if (!sh)
				deltaPositionX = 0;
			if (!sv)
				deltaPositionY = 0;
			if(deltaTime!=0)
			{
				var elapsed:Number = deltaTime * frameRate - 1;
				if (elapsed > 1) //速度衰减
				{
					var factor:Number = Math.pow(0.833, elapsed);
					_velocity.x = _velocity.x * factor;
					_velocity.y = _velocity.y * factor;
				}
				_velocity.x = ToolSet.lerp(_velocity.x, deltaPositionX * 60 / frameRate / deltaTime, deltaTime * 10);
				_velocity.y = ToolSet.lerp(_velocity.y, deltaPositionY * 60 / frameRate / deltaTime, deltaTime * 10);
			}
			
			/*速度计算使用的是本地位移，但在后续的惯性滚动判断中需要用到屏幕位移，所以这里要记录一个位移的比例。
			*/
			var deltaGlobalPositionX:Number = _lastTouchGlobalPos.x - evt.stageX;
			var deltaGlobalPositionY:Number = _lastTouchGlobalPos.y - evt.stageY;
			if (deltaPositionX != 0)
				_velocityScale = Math.abs(deltaGlobalPositionX / deltaPositionX);
			else if (deltaPositionY != 0)
				_velocityScale = Math.abs(deltaGlobalPositionY / deltaPositionY);
			
			_lastTouchPos.setTo(pt.x, pt.y);
			_lastTouchGlobalPos.setTo(evt.stageX, evt.stageY);
			_lastMoveTime = now;
			
			//同步更新pos值
			if (_overlapSize.x > 0)
				_xPos = ToolSet.clamp(-_container.x, 0, _overlapSize.x);
			if (_overlapSize.y > 0)
				_yPos = ToolSet.clamp(-_container.y, 0, _overlapSize.y);
			
			//循环滚动特别检查
			if (_loop != 0)
			{
				newPosX = _container.x;
				newPosY = _container.y;
				if (loopCheckingCurrent())
				{
					_containerPos.x += _container.x - newPosX;
					_containerPos.y += _container.y - newPosY;
				}
			}
			
			draggingPane = this;
			_isHoldAreaDone = true;
			isDragged = true;
			_maskContainer.mouseChildren = false;
			
			syncScrollBar();
			checkRefreshBar();
			if (_pageMode)
				updatePageController();
			
			dispatchEvent(new Event(Event.SCROLL));
		}
		
		private function __mouseUp(e:Event):void
		{
			_owner.removeEventListener(GTouchEvent.DRAG, __mouseMove);
			
			if (draggingPane == this)
				draggingPane = null;
			
			_gestureFlag = 0;
			
			if (!isDragged || !_touchEffect)
			{
				isDragged = false;
				_maskContainer.mouseChildren = true;
				return;
			}
			
			isDragged = false;
			_maskContainer.mouseChildren = true;
			
			_tweenStart.setTo(_container.x, _container.y);
			
			sEndPos.copyFrom(_tweenStart);
			var flag:Boolean = false;
			if (_container.x > 0)
			{
				sEndPos.x = 0;
				flag = true;
			}
			else if (_container.x < -_overlapSize.x)
			{
				sEndPos.x = -_overlapSize.x;
				flag = true;
			}
			if (_container.y > 0)
			{
				sEndPos.y = 0;
				flag = true;
			}
			else if (_container.y < -_overlapSize.y)
			{
				sEndPos.y = -_overlapSize.y;
				flag = true;
			}
			if (flag)
			{
				_tweenChange.setTo(sEndPos.x - _tweenStart.x, sEndPos.y - _tweenStart.y);
				if (_tweenChange.x < -UIConfig.touchDragSensitivity || _tweenChange.y < -UIConfig.touchDragSensitivity)
				{
					_refreshEventDispatching = true;
					dispatchEvent(new Event(ScrollPane.PULL_DOWN_RELEASE));
					_refreshEventDispatching = false;
				}
				else if (_tweenChange.x > UIConfig.touchDragSensitivity || _tweenChange.y > UIConfig.touchDragSensitivity)
				{
					_refreshEventDispatching = true;
					dispatchEvent(new Event(ScrollPane.PULL_UP_RELEASE));
					_refreshEventDispatching = false;
				}
				
				if (_headerLockedSize > 0 && sEndPos[_refreshBarAxis] == 0)
				{
					sEndPos[_refreshBarAxis] = _headerLockedSize;
					_tweenChange.x = sEndPos.x - _tweenStart.x;
					_tweenChange.y = sEndPos.y - _tweenStart.y;
				}
				else if (_footerLockedSize > 0 && sEndPos[_refreshBarAxis] == -_overlapSize[_refreshBarAxis])
				{
					var max:Number = _overlapSize[_refreshBarAxis];
					if (max == 0)
						max = Math.max(_contentSize[_refreshBarAxis] + _footerLockedSize - _viewSize[_refreshBarAxis], 0);
					else
						max += _footerLockedSize;
					sEndPos[_refreshBarAxis] = -max;
					_tweenChange.x = sEndPos.x - _tweenStart.x;
					_tweenChange.y = sEndPos.y - _tweenStart.y;
				}
				
				_tweenDuration.setTo(TWEEN_TIME_DEFAULT, TWEEN_TIME_DEFAULT);
			}
			else
			{
				//更新速度
				if (!_inertiaDisabled)
				{
					var frameRate:Number = _owner.displayObject.stage.frameRate;
					var elapsed:Number = (getTimer()/1000 - _lastMoveTime) * frameRate - 1;
					if (elapsed > 1)
					{
						var factor:Number = Math.pow(0.833, elapsed);
						_velocity.x = _velocity.x * factor;
						_velocity.y = _velocity.y * factor;
					}
					//根据速度计算目标位置和需要时间
					updateTargetAndDuration(_tweenStart, sEndPos);
				}
				else
					_tweenDuration.setTo(TWEEN_TIME_DEFAULT, TWEEN_TIME_DEFAULT);
				sOldChange.setTo(sEndPos.x - _tweenStart.x, sEndPos.y - _tweenStart.y);
				
				//调整目标位置
				loopCheckingTarget(sEndPos);
				if (_pageMode || _snapToItem)
					alignPosition(sEndPos, true);
				
				_tweenChange.x = sEndPos.x - _tweenStart.x;
				_tweenChange.y = sEndPos.y - _tweenStart.y;
				if (_tweenChange.x == 0 && _tweenChange.y == 0)
				{
					if (_scrollBarDisplayAuto)
						showScrollBar(false);
					return;
				}
				
				//如果目标位置已调整，随之调整需要时间
				if (_pageMode || _snapToItem)
				{
					fixDuration("x", sOldChange.x);
					fixDuration("y", sOldChange.y);
				}
			}
			
			_tweening = 2;
			_tweenTime.setTo(0,0);
			GTimers.inst.callBy60Fps(tweenUpdate);
		}
		
		private function __mouseWheel(evt:MouseEvent):void
		{
			if(!_mouseWheelEnabled
				&& (!_vtScrollBar || !_vtScrollBar._rootContainer.hitTestObject(DisplayObject(evt.target)))
				&& (!_hzScrollBar || !_hzScrollBar._rootContainer.hitTestObject(DisplayObject(evt.target)))
			)
				return;
				
			var focus:DisplayObject = _owner.displayObject.stage.focus;
			if((focus is TextField) && TextField(focus).type==TextFieldType.INPUT)
				return;
			
			var delta:Number = evt.delta;
			delta = delta>0?-1:(delta<0?1:0);
			if (_overlapSize.x > 0 && _overlapSize.y == 0)
			{
				if (_pageMode)
					setPosX(_xPos + _pageSize.x * delta, false);
				else
					setPosX(_xPos + _mouseWheelStep * delta, false);
			}
			else
			{
				if (_pageMode)
					setPosY(_yPos + _pageSize.y * delta, false);
				else
					setPosY(_yPos + _mouseWheelStep * delta, false);
			}
		}
		
		private function __rollOver(evt:Event):void
		{
			showScrollBar(true);
		}
		
		private function __rollOut(evt:Event):void
		{
			showScrollBar(false);
		}
		
		private function showScrollBar(val:Boolean):void
		{
			if(val)
			{
				__showScrollBar(true);
				GTimers.inst.remove(__showScrollBar);
			}
			else
				GTimers.inst.add(500, 1, __showScrollBar, val);
		}
		
		private function __showScrollBar(val:Boolean):void
		{
			_scrollBarVisible = val && _viewSize.x>0 && _viewSize.y>0;
			if(_vtScrollBar)
				_vtScrollBar.displayObject.visible = _scrollBarVisible &&　!_vScrollNone;
			if(_hzScrollBar)
				_hzScrollBar.displayObject.visible = _scrollBarVisible &&　!_hScrollNone;
		}
		
		private function getLoopPartSize(division:Number, axis:String):Number
		{
			return (_contentSize[axis] + (axis == "x" ? GList(_owner).columnGap : GList(_owner).lineGap)) / division;
		}
		
		private function loopCheckingCurrent():Boolean
		{
			var changed:Boolean = false;
			if (_loop == 1 && _overlapSize.x > 0)
			{
				if (_xPos < 0.001)
				{
					_xPos += getLoopPartSize(2, "x");
					changed = true;
				}
				else if (_xPos >= _overlapSize.x)
				{
					_xPos -= getLoopPartSize(2, "x");
					changed = true;
				}
			}
			else if (_loop == 2 && _overlapSize.y > 0)
			{
				if (_yPos < 0.001)
				{
					_yPos += getLoopPartSize(2, "y");
					changed = true;
				}
				else if (_yPos >= _overlapSize.y)
				{
					_yPos -= getLoopPartSize(2, "y");
					changed = true;
				}
			}
			
			if (changed)
			{
				_container.x = int(-_xPos);
				_container.y = int(-_yPos);
			}
			
			return changed;
		}
		
		private function loopCheckingTarget(endPos:Point):void
		{
			if (_loop == 1)
				loopCheckingTarget2(endPos, "x");
			
			if (_loop == 2)
				loopCheckingTarget2(endPos, "y");
		}
		
		private function loopCheckingTarget2(endPos:Point, axis:String):void
		{
			var halfSize:Number;
			var tmp:Number;
			if (endPos[axis] > 0)
			{
				halfSize = getLoopPartSize(2, axis);
				tmp = _tweenStart[axis] - halfSize;
				if (tmp <= 0 && tmp >= -_overlapSize[axis])
				{
					endPos[axis] -= halfSize;
					_tweenStart[axis] = tmp;
				}
			}
			else if (endPos[axis] < -_overlapSize[axis])
			{
				halfSize = getLoopPartSize(2, axis);
				tmp = _tweenStart[axis] + halfSize;
				if (tmp <= 0 && tmp >= -_overlapSize[axis])
				{
					endPos[axis] += halfSize;
					_tweenStart[axis] = tmp;
				}
			}
		}
		
		private function loopCheckingNewPos(value:Number, axis:String):Number
		{
			if (_overlapSize[axis] == 0)
				return value;
			
			var pos:Number = axis == "x" ? _xPos : _yPos;
			var changed:Boolean = false;
			var v:Number;
			if (value < 0.001)
			{
				value += getLoopPartSize(2, axis);
				if (value > pos)
				{
					v = getLoopPartSize(6, axis);
					v = Math.ceil((value - pos) / v) * v;
					pos = ToolSet.clamp(pos + v, 0, _overlapSize[axis]);
					changed = true;
				}
			}
			else if (value >= _overlapSize[axis])
			{
				value -= getLoopPartSize(2, axis);
				if (value < pos)
				{
					v = getLoopPartSize(6, axis);
					v = Math.ceil((pos - value) / v) * v;
					pos = ToolSet.clamp(pos - v, 0, _overlapSize[axis]);
					changed = true;
				}
			}
			
			if (changed)
			{
				if (axis == "x")
					_container.x = -int(pos);
				else
					_container.y = -int(pos);
			}
			
			return value;
		}
		
		private function alignPosition(pos:Point, inertialScrolling:Boolean):void
		{
			if (_pageMode)
			{
				pos.x = alignByPage(pos.x, "x", inertialScrolling);
				pos.y = alignByPage(pos.y, "y", inertialScrolling);
			}
			else if (_snapToItem)
			{
				var pt:Point = _owner.getSnappingPosition(-pos.x, -pos.y, sHelperPoint);
				if (pos.x < 0 && pos.x > -_overlapSize.x)
					pos.x = -pt.x;
				if (pos.y < 0 && pos.y > -_overlapSize.y)
					pos.y = -pt.y;
			}
		}
		
		private function alignByPage(pos:Number, axis:String, inertialScrolling:Boolean):Number
		{
			var page:int;
			
			if (pos > 0)
				page = 0;
			else if (pos < -_overlapSize[axis])
				page = Math.ceil(_contentSize[axis] / _pageSize[axis]) - 1;
			else
			{
				page = Math.floor(-pos / _pageSize[axis]);
				var change:Number = inertialScrolling ? (pos - _containerPos[axis]) : (pos - _container[axis]);
				var testPageSize:Number = Math.min(_pageSize[axis], _contentSize[axis] - (page + 1) * _pageSize[axis]);
				var delta:Number = -pos - page * _pageSize[axis];
				
				//页面吸附策略
				if (Math.abs(change) > _pageSize[axis])//如果滚动距离超过1页,则需要超过页面的一半，才能到更下一页
				{
					if (delta > testPageSize * 0.5)
						page++;
				}
				else //否则只需要页面的1/3，当然，需要考虑到左移和右移的情况
				{
					if (delta > testPageSize * (change < 0 ? 0.3 : 0.7))
						page++;
				}
				
				//重新计算终点
				pos = -page * _pageSize[axis];
				if (pos < -_overlapSize[axis]) //最后一页未必有pageSize那么大
					pos = -_overlapSize[axis];
			}
			
			//惯性滚动模式下，会增加判断尽量不要滚动超过一页
			if (inertialScrolling)
			{
				var oldPos:Number = _tweenStart[axis];
				var oldPage:int;
				if (oldPos > 0)
					oldPage = 0;
				else if (oldPos < -_overlapSize[axis])
					oldPage = Math.ceil(_contentSize[axis] / _pageSize[axis]) - 1;
				else
					oldPage = Math.floor(-oldPos / _pageSize[axis]);
				var startPage:int = Math.floor(-_containerPos[axis] / _pageSize[axis]);
				if (Math.abs(page - startPage) > 1 && Math.abs(oldPage - startPage) <= 1)
				{
					if (page > startPage)
						page = startPage + 1;
					else
						page = startPage - 1;
					pos = -page * _pageSize[axis];
				}
			}
			
			return pos;
		}
		
		private function updateTargetAndDuration(orignPos:Point, resultPos:Point):void
		{
			resultPos.x = updateTargetAndDuration2(orignPos.x, "x");
			resultPos.y = updateTargetAndDuration2(orignPos.y, "y");
		}
		
		private function updateTargetAndDuration2(pos:Number, axis:String):Number
		{
			var v:Number = _velocity[axis];
			var duration:Number = 0;
			if (pos > 0)
				pos = 0;
			else if (pos < -_overlapSize[axis])
				pos = -_overlapSize[axis];
			else
			{
				//以屏幕像素为基准
				var v2:Number = Math.abs(v) * _velocityScale;
				//在移动设备上，需要对不同分辨率做一个适配，我们的速度判断以1136分辨率为基准
				if(GRoot.touchPointInput)
					v2 *= 1136 / Math.max(GRoot.inst.nativeStage.stageWidth, GRoot.inst.nativeStage.stageHeight);
				//这里有一些阈值的处理，因为在低速内，不希望产生较大的滚动（甚至不滚动）
				var ratio:Number = 0;
				if (_pageMode || !GRoot.touchPointInput)
				{
					if (v2 > 500)
						ratio = Math.pow((v2 - 500) / 500, 2);
				}
				else
				{
					if (v2 > 1000)
						ratio = Math.pow((v2 - 1000) / 1000, 2);
				}
				if (ratio != 0)
				{
					if (ratio > 1)
						ratio = 1;
					
					v2 *= ratio;
					v *= ratio;
					_velocity[axis] = v;
					
					//算法：v*（_decelerationRate的n次幂）= 60，即在n帧后速度降为60（假设每秒60帧）。
					duration = Math.log(60 / v2)/Math.log(_decelerationRate) / 60;
					
					//计算距离要使用本地速度
					//理论公式貌似滚动的距离不够，改为经验公式
					//var change:int = (v/ 60 - 1) / (1 - _decelerationRate);
					var change:int = int(v * duration * 0.4);
					pos += change;
				}
			}
			
			if (duration < TWEEN_TIME_DEFAULT)
				duration = TWEEN_TIME_DEFAULT;
			_tweenDuration[axis] = duration;
			
			return pos;
		}
		
		private function fixDuration(axis:String, oldChange:Number):void
		{
			if (_tweenChange[axis] == 0 || Math.abs(_tweenChange[axis]) >= Math.abs(oldChange))
				return;
			
			var newDuration:Number = Math.abs(_tweenChange[axis] / oldChange) * _tweenDuration[axis];
			if (newDuration < TWEEN_TIME_DEFAULT)
				newDuration = TWEEN_TIME_DEFAULT;
			
			_tweenDuration[axis] = newDuration;
		}
		
		private function killTween():void
		{
			if (_tweening == 1) //取消类型为1的tween需立刻设置到终点
			{
				_container.x = _tweenStart.x + _tweenChange.x;
				_container.y = _tweenStart.y + _tweenChange.y;
				dispatchEvent(new Event(Event.SCROLL));
			}
			
			_tweening = 0;
			GTimers.inst.remove(tweenUpdate);
			dispatchEvent(new Event(SCROLL_END));
		}
		
		private function checkRefreshBar():void
		{
			if (_header == null && _footer == null)
				return;
			
			var pos:Number = _container[_refreshBarAxis];
			if (_header != null)
			{
				if (pos > 0)
				{
					if (_header.displayObject.parent == null)
						_maskContainer.addChildAt(_header.displayObject, 0);
					var pt:Point = sHelperPoint;
					pt.setTo(_header.width, _header.height);
					pt[_refreshBarAxis] = pos;
					_header.setSize(pt.x, pt.y);
				}
				else
				{
					if (_header.displayObject.parent != null)
						_maskContainer.removeChild(_header.displayObject);
				}
			}
			
			if (_footer != null)
			{
				var max:Number = _overlapSize[_refreshBarAxis];
				if (pos < -max || max == 0 && _footerLockedSize > 0)
				{
					if (_footer.displayObject.parent == null)
						_maskContainer.addChildAt(_footer.displayObject, 0);
					
					pt = sHelperPoint;
					pt.setTo(_footer.x, _footer.y);
					if (max > 0)
						pt[_refreshBarAxis] = pos + _contentSize[_refreshBarAxis];
					else
						pt[_refreshBarAxis] = Math.max(Math.min(pos + _viewSize[_refreshBarAxis], _viewSize[_refreshBarAxis] - _footerLockedSize),
							_viewSize[_refreshBarAxis] - _contentSize[_refreshBarAxis]);
					_footer.setXY(pt.x, pt.y);
					
					pt.setTo(_footer.width, _footer.height);
					if (max > 0)
						pt[_refreshBarAxis] = -max - pos;
					else
						pt[_refreshBarAxis] = _viewSize[_refreshBarAxis] - _footer[_refreshBarAxis];
					_footer.setSize(pt.x, pt.y);
				}
				else
				{
					if (_footer.displayObject.parent != null)
						_maskContainer.removeChild(_footer.displayObject);
				}
			}
		}
		
		private function tweenUpdate():void
		{
			var nx:Number = runTween("x");
			var ny:Number = runTween("y");
			
			_container.x = nx;
			_container.y = ny;
			
			if (_tweening == 2)
			{
				if (_overlapSize.x > 0)
					_xPos = ToolSet.clamp(-nx, 0, _overlapSize.x);
				if (_overlapSize.y > 0)
					_yPos = ToolSet.clamp(-ny, 0, _overlapSize.y);
				
				if (_pageMode)
					updatePageController();
			}
			
			if (_tweenChange.x == 0 && _tweenChange.y == 0)
			{
				_tweening = 0;
				GTimers.inst.remove(tweenUpdate);
				
				loopCheckingCurrent();
				
				syncScrollBar(true);
				checkRefreshBar();
				dispatchEvent(new Event(Event.SCROLL));
				dispatchEvent(new Event(SCROLL_END));
			}
			else
			{
				syncScrollBar(false);
				checkRefreshBar();
				dispatchEvent(new Event(Event.SCROLL));
			}
		}
		
		private function runTween(axis:String):Number
		{
			var newValue:Number;
			if (_tweenChange[axis] != 0)
			{
				_tweenTime[axis] += GTimers.deltaTime/1000;
				if (_tweenTime[axis] >= _tweenDuration[axis])
				{
					newValue = _tweenStart[axis] + _tweenChange[axis];
					_tweenChange[axis] = 0;
				}
				else
				{
					var ratio:Number = easeFunc(_tweenTime[axis], _tweenDuration[axis]);
					newValue = _tweenStart[axis] + int(_tweenChange[axis] * ratio);
				}
				
				var threshold1:Number = 0;
				var threshold2:Number = -_overlapSize[axis];
				if (_headerLockedSize > 0 && _refreshBarAxis == axis)
					threshold1 = _headerLockedSize;
				if (_footerLockedSize > 0 && _refreshBarAxis == axis)
				{
					var max:Number = _overlapSize[_refreshBarAxis];
					if (max == 0)
						max = Math.max(_contentSize[_refreshBarAxis] + _footerLockedSize - _viewSize[_refreshBarAxis], 0);
					else
						max += _footerLockedSize;
					threshold2 = -max;
				}
				
				if (_tweening == 2 && _bouncebackEffect)
				{
					if (newValue > 20 + threshold1 && _tweenChange[axis] > 0
						|| newValue > threshold1 && _tweenChange[axis] == 0)//开始回弹
					{
						_tweenTime[axis] = 0;
						_tweenDuration[axis] = TWEEN_TIME_DEFAULT;
						_tweenChange[axis] = -newValue + threshold1;
						_tweenStart[axis] = newValue;
					}
					else if (newValue < threshold2 - 20 && _tweenChange[axis] < 0
						|| newValue < threshold2 && _tweenChange[axis] == 0)//开始回弹
					{
						_tweenTime[axis] = 0;
						_tweenDuration[axis] = TWEEN_TIME_DEFAULT;
						_tweenChange[axis] = threshold2 - newValue;
						_tweenStart[axis] = newValue;
					}
				}
				else
				{
					if (newValue > threshold1)
					{
						newValue = threshold1;
						_tweenChange[axis] = 0;
					}
					else if (newValue < threshold2)
					{
						newValue = threshold2;
						_tweenChange[axis] = 0;
					}
				}
			}
			else
				newValue = _container[axis];
			
			return newValue;
		}
		
		private static function easeFunc(t:Number, d:Number):Number
		{
			return (t = t / d - 1) * t * t + 1;//cubicOut
		}
	}
}

