package fairygui
{
	import fairygui.event.StateChangeEvent;

	import flash.events.Event;
	import fairygui.event.ItemEvent;
	import fairygui.event.GTouchEvent;

	public class GTree extends GList
	{
		public var treeNodeRender:Function;
		public var treeNodeWillExpand:Function;

		private var _indent:int;
		private var _clickToExpand:int;
		private var _rootNode:GTreeNode;
		private var _expandedStatusInEvt:Boolean;

		private static var helperIntList:Vector.<int> = new Vector.<int>();
		
		public function GTree()
		{
			_indent = 15;

			_rootNode = new GTreeNode(true);
			_rootNode.setTree(this);
			_rootNode.expanded = true;
		}

		public function get rootNode():GTreeNode
		{
			return _rootNode;
		}
		
		final public function get indent():int
		{
			return _indent;
		}
		
		final public function set indent(value:int):void
		{
			_indent = value;
		}
		
		final public function get clickToExpand():int
		{
			return _clickToExpand;
		}
		
		final public function set clickToExpand(value:int):void
		{
			_clickToExpand = value;
		}

		public function getSelectedNode():GTreeNode
		{
			if(this.selectedIndex!=-1)
				return this.getChildAt(this.selectedIndex)._treeNode;
			else
				return null;
		}
		
		public function getSelectedNodes(result:Vector.<GTreeNode>=null):Vector.<GTreeNode>
		{
			if(result==null)
				result = new Vector.<GTreeNode>();

			helperIntList.length = 0;
			super.getSelection(helperIntList);
			var cnt:int = helperIntList.length;
			var ret:Vector.<GTreeNode> = new Vector.<GTreeNode>();
			for(var i:int=0;i<cnt;i++)
			{
				var node:GTreeNode = this.getChildAt(helperIntList[i])._treeNode;
				ret.push(node);
			}
			return ret;
		}
		
		public function selectNode(node:GTreeNode, scrollItToView:Boolean=false):void
		{
			var parentNode:GTreeNode = node.parent;
			while(parentNode!=null && parentNode!=_rootNode)
			{
				parentNode.expanded = true;
				parentNode = parentNode.parent;
			}
			
			if(!node._cell)
				return;
			
			this.addSelection(this.getChildIndex(node._cell), scrollItToView);
		}
		
		public function unselectNode(node:GTreeNode):void
		{
			if(!node._cell)
				return;
			
			this.removeSelection(this.getChildIndex(node._cell));
		}
		
		public function expandAll(folderNode:GTreeNode=null):void
		{
			if(folderNode==null)
				folderNode = _rootNode;

			folderNode.expanded = true;
			var cnt:int = folderNode.numChildren;
			for(var i:int=0;i<cnt;i++)
			{
				var node:GTreeNode = folderNode.getChildAt(i);
				if(node.isFolder)
					expandAll(node);
			}
		}
		
		public function collapseAll(folderNode:GTreeNode=null):void
		{
			if(folderNode==null)
				folderNode = _rootNode;

			if(folderNode!=_rootNode)
				folderNode.expanded = false;
			var cnt:int = folderNode.numChildren;
			for(var i:int=0;i<cnt;i++)
			{
				var node:GTreeNode = folderNode.getChildAt(i);
				if(node.isFolder)
					collapseAll(node);
			}
		}
		
		private function createCell(node:GTreeNode):void
		{
			var child:GComponent = getFromPool(node._resURL) as GComponent;
			if(!child)
				throw new Error("cannot create tree node object.");
			
			child._treeNode = node;
			node._cell = child;
			
			var indentObj:GObject = child.getChild("indent");
			if(indentObj!=null)
				indentObj.width = (node.level-1)*_indent;

			var cc:Controller;
			
			cc = child.getController("expanded");
			if(cc)
			{
				cc.addEventListener(StateChangeEvent.CHANGED, __expandedStateChanged);
				cc.selectedIndex = node.expanded?1:0;
			}

			if(node.isFolder)
				child.addEventListener(GTouchEvent.BEGIN, __cellMouseDown);

			cc = child.getController("leaf");
			if(cc)
				cc.selectedIndex = node.isFolder?0:1;
			
			if(treeNodeRender!=null)
				treeNodeRender(node, child);
		}
		
		internal function afterInserted(node:GTreeNode):void
		{
			if(!node._cell)
				createCell(node);
			
			var index:int = getInsertIndexForNode(node);
			this.addChildAt(node._cell, index);
			if(treeNodeRender!=null)
				treeNodeRender(node, node._cell);
			
			if(node.isFolder && node.expanded)
				checkChildren(node, index);
		}
		
		private function getInsertIndexForNode(node:GTreeNode):int
		{
			var prevNode:GTreeNode = node.getPrevSibling();
			if(prevNode==null)
				prevNode = node.parent;
			var insertIndex:int = this.getChildIndex(prevNode._cell)+1;
			var myLevel:int = node.level;
			var cnt:int = this.numChildren;
			for(var i:int=insertIndex;i<cnt;i++)
			{
				var testNode:GTreeNode = this.getChildAt(i)._treeNode;
				if(testNode.level<=myLevel)
					break;
				
				insertIndex++;
			}
			
			return insertIndex;
		}
		
		internal function afterRemoved(node:GTreeNode):void
		{
			removeNode(node);
		}
		
		internal function afterExpanded(node:GTreeNode):void
		{
			if(node==_rootNode)
			{
				checkChildren(_rootNode, 0);
				return;
			}
			
			if(treeNodeWillExpand!=null)
				treeNodeWillExpand(node, true);
			
			if(node._cell==null)
				return;
			
			if(treeNodeRender!=null)
				treeNodeRender(node, node._cell);
			
			var cc:Controller = node._cell.getController("expanded");
			if(cc)
				cc.selectedIndex = 1;

			if(node._cell.parent!=null)
				checkChildren(node, this.getChildIndex(node._cell));
		}
		
		internal function afterCollapsed(node:GTreeNode):void
		{
			if(node==_rootNode)
			{
				checkChildren(_rootNode, 0);
				return;
			}

			if(treeNodeWillExpand!=null)
				treeNodeWillExpand(node, false);
			
			if(node._cell==null)
				return;
			
			if(treeNodeRender!=null)
				treeNodeRender(node, node._cell);
			
			var cc:Controller = node._cell.getController("expanded");
			if(cc)
				cc.selectedIndex = 0;
			
			if(node._cell.parent!=null)
				hideFolderNode(node);
		}
		
		internal function afterMoved(node:GTreeNode):void
		{
			var startIndex:int = this.getChildIndex(node._cell);
			var endIndex:int;
			if(node.isFolder)
				endIndex = getFolderEndIndex(startIndex, node.level);
			else
				endIndex = startIndex+1;
			var insertIndex:int = getInsertIndexForNode(node);
			var i:int;
			var cnt:int = endIndex-startIndex;
			var obj:GObject;
			if(insertIndex<startIndex)
			{
				for(i=0;i<cnt;i++)
				{
					obj = this.getChildAt(startIndex+i);
					this.setChildIndex(obj, insertIndex+i);
				}
			}
			else
			{
				for(i=0;i<cnt;i++)
				{
					obj = this.getChildAt(startIndex);
					this.setChildIndex(obj, insertIndex);
				}
			}
		}

		private function getFolderEndIndex(startIndex:int, level:int):int
		{
			var cnt:int = this.numChildren;
			for(var i:int=startIndex+1;i<cnt;i++)
			{
				var node:GTreeNode = this.getChildAt(i)._treeNode;
				if(node.level<=level)
					return i;
			}

			return cnt;
		}
		
		private function checkChildren(folderNode:GTreeNode, index:int):int
		{
			var cnt:int = folderNode.numChildren;
			for(var i:int=0;i<cnt;i++)
			{
				index++;
				var node:GTreeNode = folderNode.getChildAt(i);
				if(node._cell==null)
					createCell(node);

				if(!node._cell.parent)
					this.addChildAt(node._cell, index);

				if(node.isFolder && node.expanded)
					index = checkChildren(node, index);
			}
			
			return index;
		}
		
		private function hideFolderNode(folderNode:GTreeNode):void
		{
			var cnt:int = folderNode.numChildren;
			for(var i:int=0;i<cnt;i++)
			{
				var node:GTreeNode = folderNode.getChildAt(i);
				if(node._cell && node._cell.parent!=null)
					this.removeChild(node._cell);
				if(node.isFolder && node.expanded)
					hideFolderNode(node);
			}
		}
		
		private function removeNode(node:GTreeNode):void
		{
			if(node._cell!=null)
			{
				if(node._cell.parent!=null)
					this.removeChild(node._cell);
				this.returnToPool(node._cell);
				node._cell._treeNode = null;
				node._cell = null;
			}
			
			if(node.isFolder)
			{
				var cnt:int = node.numChildren;
				for(var i:int=0;i<cnt;i++)
				{
					var node2:GTreeNode = node.getChildAt(i);
					removeNode(node2);
				}
			}
		}
		
		private function __cellMouseDown(evt:Event):void
		{
			var node:GTreeNode = evt.currentTarget._treeNode;
			_expandedStatusInEvt = node.expanded;
		}

		private function __expandedStateChanged(evt:Event):void
		{
			var cc:Controller = Controller(evt.currentTarget);
			var node:GTreeNode = cc.parent._treeNode;
			node.expanded = cc.selectedIndex==1;
		}

		override protected function dispatchItemEvent(evt:ItemEvent):void
		{
			if(_clickToExpand!=0 && !evt.rightButton)
			{
				var node:GTreeNode = evt.itemObject._treeNode;
				if(node && _expandedStatusInEvt==node.expanded)
				{
					if(_clickToExpand==2)
					{
						if(evt.clickCount==2)
							node.expanded = !node.expanded;
					}
					else
						node.expanded = !node.expanded;
				}
			}

			super.dispatchItemEvent(evt);
		}

		override protected function readItems(xml:XML):void
		{
			var str:String = xml.@indent;
			if(str)
				_indent = parseInt(str);
			
			str = xml.@clickToExpand;
			if(str)
				_clickToExpand = parseInt(str);

			var col:XMLList = xml.item;
			var cnt:int = col.length();
			var lastNode:GTreeNode;
			var level:int;
			var nextLevel:int;
			var prevLevel:int;
			for(var i:int=0;i<cnt;i++)
			{
				var cxml:XML = col[i];
				var url:String = cxml.@url;
				if(i==0)
					level = parseInt(cxml.@level);
				else
					level = nextLevel;
				if(i<cnt-1)
					nextLevel = parseInt(col[i+1].@level);
				else
					nextLevel = 0;
				var node:GTreeNode = new GTreeNode(nextLevel>level, url);
				node.expanded = true;
				if(i==0)
					_rootNode.addChild(node);
				else
				{
					if(level>prevLevel)
						lastNode.addChild(node);
					else if(level<prevLevel)
					{
						for(var j:int=level;j<=prevLevel;j++)
							lastNode = lastNode.parent;
						lastNode.addChild(node);
					}
					else
						lastNode.parent.addChild(node);
				}
				lastNode = node;
				prevLevel = level;
				setupItem(cxml, node.cell);
			}
		}
	}
}