package
{
	import fairygui.GButton;
	import fairygui.GList;
	import fairygui.UIPackage;
	import fairygui.Window;

	public class WindowA extends Window
	{
		public function WindowA()
		{
		}
		
		override protected function onInit():void
		{
			this.contentPane = UIPackage.createObject("Demo", "WindowA").asCom;
			this.center();
		}
		
		override protected function onShown():void
		{
			var list:GList = this.contentPane.getChild("n6").asList;
			list.removeChildrenToPool();
			
			for(var i:int=0;i<6;i++)
			{
				var item:GButton = list.addItemFromPool().asButton;
				item.title = ""+i;
				item.icon = UIPackage.getItemURL("Demo", "r4");
			}
		}
	}
}