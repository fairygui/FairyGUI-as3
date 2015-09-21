package
{
	import com.greensock.TweenLite;
	
	import fairygui.UIPackage;
	import fairygui.Window;

	public class WindowB extends Window
	{
		public function WindowB()
		{	
		}
		
		override protected function onInit():void
		{
			this.contentPane = UIPackage.createObject("Demo", "WindowB").asCom;
			this.center();
			
			//弹出窗口的动效已中心为轴心
			this.setPivot(this.width/2, this.height/2);
		}
		
		override protected function doShowAnimation():void
		{
			this.setScale(0.1, 0.1);
			TweenLite.to(this, 0.3, { scaleX:1, scaleY:1, ease:"Quad.easeOut", 
				onComplete:this.onShown});
		}
		
		override protected function doHideAnimation():void
		{
			TweenLite.to(this, 0.3, { scaleX:0.1, scaleY:0.1, ease:"Quad.easeOut", 
				onComplete:this.hideImmediately});
		}
		
		override protected function onShown():void
		{
			contentPane.getTransition("t1").play();	
		}
		
		override protected function onHide():void
		{
			contentPane.getTransition("t1").stop();
		}
	}
}