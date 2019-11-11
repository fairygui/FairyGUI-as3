package fairygui
{
	public class GTreeNode
	{
		private var _data:Object;
		
		private var _parent:GTreeNode;
		private var _children:Vector.<GTreeNode>;
		private var _expanded:Boolean;
		private var _level:int;
		private var _tree:GTree;

		internal var _cell:GComponent;
		internal var _resURL:String;
		
		public function GTreeNode(hasChild:Boolean, resURL:String=null)
		{
			_resURL = resURL;
			if(hasChild)
				_children = new Vector.<GTreeNode>();
		}
		
		final public function set expanded(value:Boolean):void
		{
			if(_children==null)
				return;
			
			if(_expanded!=value)
			{
				_expanded = value;
				if(_tree!=null)
				{
					if(_expanded)
						_tree.afterExpanded(this);
					else
						_tree.afterCollapsed(this);
				}
			}
		}
		
		final public function get expanded():Boolean
		{
			return _expanded;
		}
		
		final public function get isFolder():Boolean
		{
			return _children!=null;
		}
		
		final public function get parent():GTreeNode
		{
			return _parent;
		}
		
		final public function set data(value:Object):void
		{
			_data = value;
		}
		
		final public function get data():Object
		{
			return _data;
		}
		
		final public function get text():String
		{
			if(_cell!=null)
				return _cell.text;
			else
				return null;
		}
		
		final public function set text(value:String):void
		{
			if(_cell!=null)
				_cell.text = value;
		}

		final public function get icon():String
		{
			if(_cell!=null)
				return _cell.icon;
			else
				return null;
		}
		
		final public function set icon(value:String):void
		{
			if(_cell!=null)
				_cell.icon = value;
		}

		final public function get cell():GComponent
		{
			return _cell;
		}
		
		final public function get level():int
		{
			return _level;
		}
		
		internal function setLevel(value:int):void
		{
			_level = value;
		}
		
		public function addChild(child:GTreeNode):GTreeNode
		{
			addChildAt(child, _children.length);
			return child;
		}
		
		public function addChildAt(child:GTreeNode, index:int):GTreeNode
		{
			if(!child)
				throw new Error("child is null");

			var numChildren:int = _children.length; 
			
			if (index >= 0 && index <= numChildren)
			{
				if (child._parent == this)
				{
					setChildIndex(child, index); 
				}
				else
				{
					if(child._parent)
						child._parent.removeChild(child);
					
					var cnt:int = _children.length;
					if (index == cnt) 
						_children.push(child);
					else
						_children.splice(index, 0, child);
					
					child._parent = this;
					child._level = this._level+1;
					child.setTree(_tree);
					if(_tree!=null && this==_tree.rootNode || this._cell!=null && this._cell.parent!=null && _expanded)
						_tree.afterInserted(child);
				}
				
				return child;
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}

		public function removeChild(child:GTreeNode):GTreeNode
		{
			var childIndex:int = _children.indexOf(child);
			if (childIndex != -1)
			{
				removeChildAt(childIndex);
			}
			return child;
		}
		
		public function removeChildAt(index:int):GTreeNode
		{
			if (index >= 0 && index < numChildren)
			{
				var child:GTreeNode = _children[index];
				_children.splice(index, 1);
				
				child._parent = null;
				if(_tree!=null)
				{
					child.setTree(null);
					_tree.afterRemoved(child);
				}
				
				return child;
			}
			else
			{
				throw new RangeError("Invalid child index");
			}
		}
		
		public function removeChildren(beginIndex:int=0, endIndex:int=-1):void
		{
			if (endIndex < 0 || endIndex >= numChildren) 
				endIndex = numChildren - 1;
			
			for (var i:int=beginIndex; i<=endIndex; ++i)
				removeChildAt(beginIndex);
		}
		
		public function getChildAt(index:int):GTreeNode
		{
			if (index >= 0 && index < numChildren)
				return _children[index];
			else
				throw new RangeError("Invalid child index");
		}
	
		public function getChildIndex(child:GTreeNode):int
		{
			return _children.indexOf(child);
		}
		
		public function getPrevSibling():GTreeNode
		{
			if(_parent==null)
				return null;
			
			var i:int = _parent._children.indexOf(this);
			if(i<=0)
				return null;
			
			return _parent._children[i-1];
		}
		
		public function getNextSibling():GTreeNode
		{
			if(_parent==null)
				return null;
			
			var i:int = _parent._children.indexOf(this);
			if(i<0 || i>=_parent._children.length-1)
				return null;
			
			return _parent._children[i+1];
		}
		
		public function setChildIndex(child:GTreeNode, index:int):void
		{
			var oldIndex:int = _children.indexOf(child);
			if (oldIndex == -1) 
				throw new ArgumentError("Not a child of this container");
			
			var cnt:int = _children.length;
			if(index<0)
				index = 0;
			else if(index>cnt)
				index = cnt;
			
			if(oldIndex==index)
				return;
			
			_children.splice(oldIndex, 1);
			_children.splice(index, 0, child);
			if(_tree!=null && this==_tree.rootNode || this._cell!=null && this._cell.parent!=null && _expanded)
				_tree.afterMoved(child);
		}
		
		public function swapChildren(child1:GTreeNode, child2:GTreeNode):void
		{
			var index1:int = _children.indexOf(child1);
			var index2:int = _children.indexOf(child2);
			if (index1 == -1 || index2 == -1)
				throw new ArgumentError("Not a child of this container");
			swapChildrenAt(index1, index2);
		}
		
		public function swapChildrenAt(index1:int, index2:int):void
		{
			var child1:GTreeNode = _children[index1];
			var child2:GTreeNode = _children[index2];
			
			setChildIndex(child1, index2);
			setChildIndex(child2, index1);
		}
		
		final public function get numChildren():int 
		{ 
			return _children.length; 
		}

		public function expandToRoot():void
		{
			var p:GTreeNode = this;
			while(p)
			{
				p.expanded = true;
				p = p.parent;
			}
		}
		
		final public function get tree():GTree
		{
			return _tree;
		}

		internal function setTree(value:GTree):void
		{
			_tree = value;
			if(_tree!=null && _tree.treeNodeWillExpand!=null && _expanded)
				_tree.treeNodeWillExpand(this, true);
			
			if(_children!=null)
			{
				var cnt:int = _children.length;
				for(var i:int=0;i<cnt;i++)
				{
					var node:GTreeNode = _children[i];
					node._level = _level+1;
					node.setTree(value);
				}
			}
		}
	}
}