package fairygui.action
{
	import fairygui.Controller;
	import fairygui.GComponent;

	public class ChangePageAction extends ControllerAction
	{
		public var objectId:String;
		public var controllerName:String;
		public var targetPage:String;
		
		public function ChangePageAction()
		{
		}
		
		override protected function enter(controller:Controller):void
		{	
			if(!controllerName)
				return;
			
			var gcom:GComponent;
			if(objectId)
				gcom = controller.parent.getChildById(objectId) as GComponent;
			else
				gcom = controller.parent;
			if(gcom)
			{
				var cc:Controller = gcom.getController(controllerName);
				if(cc && cc!=controller && !cc.changing)
				{
					if(targetPage=="~1")
					{
						if(controller.selectedIndex<cc.pageCount)
							cc.selectedIndex = controller.selectedIndex;
					}
					else if(targetPage=="~2")
						cc.selectedPage = controller.selectedPage;
					else
						cc.selectedPageId = targetPage;
				}
			}
		}

		override public function setup(xml:XML):void
		{
			super.setup(xml);
			
			objectId = xml.@objectId;
			controllerName = xml.@controller;
			targetPage = xml.@targetPage;
		}
	}
}