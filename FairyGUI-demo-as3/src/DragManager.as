package
{
	import flash.geom.Point;
	
	import fairygui.GLoader;
	import fairygui.GObject;
	import fairygui.GRoot;
	import fairygui.event.DragEvent;
	
	public class DragManager
	{
		private var _agent:GLoader;
		private var _sourceData:Object;
		
		private static var _inst:DragManager;
		public static function get inst():DragManager
		{
			if(_inst==null)
				_inst = new DragManager();
			return _inst;
		}
		
		public function DragManager()
		{
			_agent = new GLoader();
			_agent.draggable = true;
			_agent.touchable = false;//important
			_agent.setSize(88,88);
			_agent.alwaysOnTop = int.MAX_VALUE;
			_agent.addEventListener(DragEvent.DRAG_END, __dragEnd);
		}
		
		public function get dragAgent():GObject
		{
			return _agent;
		}
		
		public function get dragging():Boolean
		{
			return _agent.parent!=null;
		}
		
		public function startDrag(source:GObject, icon:String, sourceData:Object):void
		{
			if(_agent.parent!=null)
				return;
			
			_sourceData = sourceData;
			_agent.url = icon;
			GRoot.inst.addChild(_agent);
			var pt:Point = source.localToGlobal();
			_agent.setXY(pt.x, pt.y);
			_agent.startDrag();
		}
		
		public function cancel():void
		{
			if(_agent.parent!=null)
			{
				_agent.stopDrag();
				GRoot.inst.removeChild(_agent);
				_sourceData = null;
			}
		}
		
		private function __dragEnd(evt:DragEvent):void
		{
			if(_agent.parent==null) //cancelled
				return;
			
			GRoot.inst.removeChild(_agent);

			var sourceData:Object = _sourceData;
			_sourceData = null;
			
			var obj:GObject = GRoot.inst.getObjectUnderPoint(evt.stageX, evt.stageY);
			while(obj!=null)
			{
				if(obj.hasEventListener(DropEvent.DROP))
				{
					var dropEvt:DropEvent = new DropEvent(DropEvent.DROP, sourceData);
					obj.requestFocus();
					obj.dispatchEvent(dropEvt);
					return;		
				}
				
				obj = obj.parent;
			}
		}
	}
}