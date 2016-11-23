package fairygui.extention
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import base.InstanceBase;
	
	import fairygui.GObject;
	import fairygui.GRoot;
	import fairygui.event.DropEvent;
	
	import once.methods.Method;
	
	import tools.manager.bmpMcManager.Animate;
	import tools.manager.poolManager.PoolManager;

	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-11-22下午2:31:09 <br/>
	 **/
	public final class AnimateDragManager extends InstanceBase
	{
		private var _animate:Animate;
		private var _dragEndCallBack:Method;
		private var _dragData:Object;
		public static const Instance:AnimateDragManager = new AnimateDragManager();
		public function AnimateDragManager()
		{
			super(Instance);
		}
		//***************
		//internal
		//***************
		
		//***************
		//noticeHandler
		//***************
		
		//***************
		//protected
		//***************
		
		//***************
		//private
		//***************
		
		//***************
		//eventHandler
		//***************
		private function OnStageMouseUp(e:MouseEvent):void
		{
			GRoot.inst.nativeStage.removeEventListener(MouseEvent.MOUSE_UP, OnStageMouseUp);
			if(_animate!=null)
			{
				_animate.stopDrag();
				_animate.Release();
				_animate = null;
			}
			
			var sourceData:Object = _dragData;
			_dragData = null;
			
			
			var obj:GObject = GRoot.inst.getObjectUnderPoint(e.stageX, e.stageY);
			while(obj!=null)
			{
				if(obj.hasEventListener(DropEvent.DROP))
				{
					var dropEvt:DropEvent = new DropEvent(DropEvent.DROP, sourceData);
					obj.requestFocus();
					obj.dispatchEvent(dropEvt);
					break;
				}
				
				obj = obj.parent;
			}
			if(_dragEndCallBack!=null)
			{
				_dragEndCallBack.execute();
				_dragEndCallBack.gc();
				_dragEndCallBack = null;
			}
		}
		//***************
		//public
		//***************
		/*public function startDragOffset(source:GObject, icon:String, sourceData:Object, offset:Point, touchPointId:int = -1):void
		{
			if(_agent.parent!=null)
				return;
			
			_sourceData = sourceData;
			_agent.url = icon;
			GRoot.inst.addChild(_agent);
			var pt:Point = GRoot.inst.globalToLocal(source.displayObject.stage.mouseX, source.displayObject.stage.mouseY);
			_agent.setXY(pt.x + offset.x, pt.y + offset);
			_agent.startDrag(touchPointId);
		}*/
		public function StartDrag(source:GObject, swfUrl:String, dragData:Object=null, offset:Point=null, dragEndCallBack:Method=null):void
		{
			_dragData = dragData;
			_dragEndCallBack = dragEndCallBack;
			if(_animate==null)
			{
				_animate = PoolManager.GetPool(Animate).BorrowObj() as Animate;
				GRoot.inst.displayListContainer.addChild(_animate);
			}
			_animate.swfUrl = swfUrl;
			var pt:Point = GRoot.inst.globalToLocal(source.displayObject.stage.mouseX, source.displayObject.stage.mouseY);
			_animate.x = pt.x + (offset!=null ? offset.x : 0);
			_animate.y = pt.y + (offset!=null ? offset.y : 0);
			_animate.startDrag();
			GRoot.inst.nativeStage.addEventListener(MouseEvent.MOUSE_UP, OnStageMouseUp);
		}
	}
}