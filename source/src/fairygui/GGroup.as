package fairygui
{
	import fairygui.utils.GTimers;

	public class GGroup extends GObject
	{
		private var _layout:int;
		private var _lineGap:int;
		private var _columnGap:int;
		private var _excludeInvisibles:Boolean;
		private var _autoSizeDisabled:Boolean;
		private var _mainGridIndex:int;
		private var _mainGridMinSize:Number;

		private var _boundsChanged:Boolean;
		private var _percentReady:Boolean;
		private var _mainChildIndex:int;
		private var _totalSize:Number;
		private var _numChildren:int;

		internal var _updating:int;

		public function GGroup()
		{
			_mainGridIndex = -1;
			_mainGridMinSize = 50;
			_totalSize = 0;
			_numChildren = 0;
		}

		override public function dispose():void
		{
			_boundsChanged = false;
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
				setBoundsChangedFlag(true);
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
				setBoundsChangedFlag(true);
			}
		}
		
		public function get excludeInvisibles():Boolean
		{
			return _excludeInvisibles;
		}
		
		public function set excludeInvisibles(value:Boolean):void
		{
			if(_excludeInvisibles != value)
			{
				_excludeInvisibles = value;
				setBoundsChangedFlag();
			}
		}

		public function get autoSizeDisabled():Boolean
		{
			return _autoSizeDisabled;
		}
		
		public function set autoSizeDisabled(value:Boolean):void
		{
			_autoSizeDisabled = value;
		}

		public function get mainGridMinSize():Number
		{
			return _mainGridMinSize;
		}
		
		public function set mainGridMinSize(value:Number):void
		{
			if(_mainGridMinSize!=value)
			{
				_mainGridMinSize = value;
				setBoundsChangedFlag();
			}
		}

		public function get mainGridIndex():int
		{
			return _mainGridIndex;
		}
		
		public function set mainGridIndex(value:int):void
		{
			if(_mainGridIndex!=value)
			{
				_mainGridIndex = value;
				setBoundsChangedFlag();
			}
		}
		
		public function setBoundsChangedFlag(positionChangedOnly:Boolean=false):void
		{
			if (_updating == 0 && parent != null)
			{
				if(!positionChangedOnly)
					_percentReady = false;
				
				if(!_boundsChanged)
				{
					_boundsChanged = true;
					if(_layout!=0)
						GTimers.inst.callLater(ensureBoundsCorrect);
				}
			}
		}
		
		override public function ensureSizeCorrect():void
		{
			if (parent == null || !_boundsChanged || _layout==0)
				return;
			
			_boundsChanged = false;
			if(_autoSizeDisabled)
				resizeChildren(0, 0);
			else
			{
				handleLayout();
				updateBounds();
			}
		}
		
		public function ensureBoundsCorrect():void
		{
			if (parent == null || !_boundsChanged)
				return;

			_boundsChanged = false;
			if(_layout==0)
				updateBounds();
			else
			{
				if(_autoSizeDisabled)
					resizeChildren(0, 0);
				else
				{
					handleLayout();
					updateBounds();
				}
			}
		}
		
		private function updateBounds():void
		{
			var cnt:int = _parent.numChildren;
			var i:int;
			var child:GObject;
			var ax:int=int.MAX_VALUE, ay:int=int.MAX_VALUE;
			var ar:int = int.MIN_VALUE, ab:int = int.MIN_VALUE;
			var tmp:int;
			
			var numChildren:int = 0;
			
			for(i=0;i<cnt;i++)
			{
				child = _parent.getChildAt(i);
				if(child.group!=this || _excludeInvisibles && !child.internalVisible3)
					continue;
				
				numChildren++;
				
				tmp = child.xMin;
				if(tmp<ax)
					ax = tmp;
				tmp = child.yMin;
				if(tmp<ay)
					ay = tmp;
				tmp = child.xMin+child.width;
				if(tmp>ar)
					ar = tmp;
				tmp = child.yMin+child.height;
				if(tmp>ab)
					ab = tmp;
			}

			var w:Number = 0, h:Number = 0;
			if (numChildren>0)
			{
				_updating |= 1;
				setXY(ax, ay);
				_updating &= 2;
				
				w = ar-ax;
				h = ab-ay;
			}
			
			if((_updating & 2)==0)
			{
				_updating |= 2;
				setSize(w, h);
				_updating &= 1;
			}
			else
			{
				_updating &= 1;
				this.resizeChildren(_width-w, _height-h);
			}
		}
		
		private function handleLayout():void
		{
			_updating |= 1;
			
			var child:GObject;
			var i:int;
			var cnt:int;
			
			if (_layout == 1)
			{
				var curX:Number = this.x;
				cnt = parent.numChildren;
				for (i = 0; i < cnt; i++)
				{
					child = parent.getChildAt(i);
					if (child.group != this)
						continue;
					if(_excludeInvisibles && !child.internalVisible3)
						continue;
					
					child.xMin = curX;
					if (child.width != 0)
						curX += child.width + _columnGap;
				}
			}
			else if (_layout == 2)
			{
				var curY:Number = this.y;
				cnt = parent.numChildren;
				for (i = 0; i < cnt; i++)
				{
					child = parent.getChildAt(i);
					if (child.group != this)
						continue;
					if(_excludeInvisibles && !child.internalVisible3)
						continue;
					
					child.yMin = curY;
					if (child.height != 0)
						curY += child.height + _lineGap;
				}
			}
			
			_updating &= 2;
		}
		
		internal function moveChildren(dx:Number, dy:Number):void
		{
			if ((_updating & 1) != 0 || parent == null)
				return;
			
			_updating |= 1;
			
			var cnt:int = parent.numChildren;
			var i:int
			var child:GObject;
			for (i = 0; i < cnt; i++)
			{
				child = parent.getChildAt(i);
				if (child.group == this)
				{
					child.setXY(child.x + dx, child.y + dy);
				}
			}
			
			_updating &= 2;
		}
		
		internal function resizeChildren(dw:Number, dh:Number):void
		{
			if (_layout == 0 || (_updating & 2) != 0 || parent == null)
				return;
			
			_updating |= 2;
			
			if(_boundsChanged)
			{
				_boundsChanged = false;
				if(!_autoSizeDisabled)
				{
					updateBounds();
					return;
				}
			}

			var cnt:int = parent.numChildren;
			var i:int;
			var child:GObject;

			if(!_percentReady)
			{
				_percentReady = true;
				_numChildren = 0;
				_totalSize = 0;
				_mainChildIndex = -1;

				var j:int = 0;
				for(i=0;i<cnt;i++)
				{
					child = _parent.getChildAt(i);
					if(child.group!=this)
						continue;

					if(!_excludeInvisibles || child.internalVisible3)
					{
						if(j==_mainGridIndex)
							_mainChildIndex = i;

						_numChildren++;

						if(_layout==1)
							_totalSize += child.width;
						else
							_totalSize += child.height;
					}

					j++;
				}

				if(_mainChildIndex!=-1)
				{
					if (_layout == 1)
					{
						child = parent.getChildAt(_mainChildIndex);
						_totalSize += _mainGridMinSize - child.width;
						child._sizePercentInGroup = _mainGridMinSize / _totalSize;
					}
					else
					{
						child = parent.getChildAt(_mainChildIndex);
						_totalSize += _mainGridMinSize - child.height;
						child._sizePercentInGroup = _mainGridMinSize / _totalSize;
					}
				}
			
				for (i = 0; i < cnt; i++)
				{
					child = parent.getChildAt(i);
					if(child.group!=this)
						continue;
					
					if(i==_mainChildIndex)
						continue;
					
					if (_totalSize > 0)
						child._sizePercentInGroup = (_layout==1?child.width:child.height) / _totalSize;
					else
						child._sizePercentInGroup = 0;
				}
			}

			var remainSize:Number = 0;
			var remainPercent:Number = 1;
			var priorHandled:Boolean = false;
			
			if (_layout == 1)
			{
				remainSize = this.width - (_numChildren - 1) * _columnGap;
				if(_mainChildIndex!=-1 && remainSize>=_totalSize)
				{
					child = parent.getChildAt(_mainChildIndex);
					child.setSize(remainSize - (_totalSize - _mainGridMinSize), child._rawHeight+dh, true);
					remainSize -= child.width;
					remainPercent -= child._sizePercentInGroup;
					priorHandled = true;
				}

				var curX:Number = this.x;
				for (i = 0; i < cnt; i++)
				{
					child = parent.getChildAt(i);
					if(child.group!=this)
						continue;

					if(_excludeInvisibles && !child.internalVisible3)
					{
						child.setSize(child._rawWidth, child._rawHeight+dh, true);
						continue;
					}
					
					if(!priorHandled || i!=_mainChildIndex)
					{
						child.setSize(Math.round(child._sizePercentInGroup/remainPercent*remainSize), child._rawHeight+dh, true);
						remainPercent -= child._sizePercentInGroup;
						remainSize -= child.width;
					}

					child.xMin = curX;
					if(child.width!=0)
						curX += child.width + _columnGap;
				}
			}
			else
			{
				remainSize = this.height - (_numChildren - 1) * _lineGap;
				if(_mainChildIndex!=-1 && remainSize>=_totalSize)
				{
					child = parent.getChildAt(_mainChildIndex);
					child.setSize(child._rawWidth+dw, remainSize - (_totalSize - _mainGridMinSize), true);
					remainSize -= child.height;
					remainPercent -= child._sizePercentInGroup;
					priorHandled = true;
				}
				
				var curY:Number = this.y;
				for (i = 0; i < cnt; i++)
				{
					child = parent.getChildAt(i);
					if(child.group!=this)
						continue;

					if(_excludeInvisibles && !child.internalVisible3)
					{
						child.setSize(child._rawWidth+dw, child._rawHeight, true);
						continue;
					}

					if(!priorHandled || i!=_mainChildIndex)
					{
						child.setSize(child._rawWidth+dw, Math.round(child._sizePercentInGroup/remainPercent*remainSize), true);
						remainPercent -= child._sizePercentInGroup;
						remainSize -= child.height;
					}

					child.yMin = curY;
					if(child.height!=0)
						curY += child.height + _lineGap;
				}
			}
			
			_updating &= 1;
		}
		
		override protected function handleAlphaChanged():void
		{
			if(this._underConstruct)
				return;
			
			var cnt:int = _parent.numChildren;
			for(var i:int =0;i<cnt;i++)
			{
				var child:GObject = _parent.getChildAt(i);
				if(child.group==this)
					child.alpha = this.alpha;
			}
		}
		
		override internal function handleVisibleChanged():void
		{
			if(!this._parent)
				return;
			
			var cnt:int = _parent.numChildren;
			for(var i:int =0;i<cnt;i++)
			{
				var child:GObject = _parent.getChildAt(i);
				if(child.group==this)
					child.handleVisibleChanged();
			}
		}
		
		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String;
			
			str = xml.@layout;
			if (str != null)
			{
				_layout = GroupLayoutType.parse(str);
				str = xml.@lineGap;
				if(str)
					_lineGap = parseInt(str);
				str = xml.@colGap;
				if(str)
					_columnGap = parseInt(str);
				_excludeInvisibles = xml.@excludeInvisibles=="true";
				_autoSizeDisabled = xml.@autoSizeDisabled=="true";
				str = xml.@mainGridIndex;
				if(str)
					_mainGridIndex = parseInt(str);
			}
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			if(!this.visible)
				handleVisibleChanged();
		}
	}
}