package
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import fairygui.GRoot;
	import fairygui.UIConfig;
	import fairygui.UIPackage;

	[SWF (width="640", height="960")]
	public class Main extends Sprite
	{
		private var _loader:URLLoader;
		private var _mainPanel:MainPanel;
		
		public function Main()
		{
			stage.color = 0;
			stage.frameRate = 24;
			
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			var path:String = "../assets/demo.zip";
			
			_loader = new URLLoader();
			_loader.dataFormat = URLLoaderDataFormat.BINARY;
			_loader.load(new URLRequest(path));
			_loader.addEventListener(Event.COMPLETE, onLoadComplete);
		}
		
		private function onLoadComplete(evt:Event):void
		{
			UIPackage.addPackage(ByteArray(_loader.data), null);
			
			UIConfig.defaultFont = "宋体";
			UIConfig.verticalScrollBar = UIPackage.getItemURL("Demo", "ScrollBar_VT");
			UIConfig.horizontalScrollBar = UIPackage.getItemURL("Demo", "ScrollBar_HZ");
			UIConfig.popupMenu = UIPackage.getItemURL("Demo", "PopupMenu");
			UIConfig.defaultScrollBounceEffect = false;
			UIConfig.defaultScrollTouchEffect = false;
			
			//等待图片资源全部解码，也可以选择不等待，这样图片会在用到的时候才解码
			UIPackage.waitToLoadCompleted(continueInit);
		}
		
		private function continueInit():void {
			stage.addChild(new GRoot().displayObject);
			
			GRoot.inst.setFlashContextMenuDisabled(true);
			
			_mainPanel = new MainPanel();
		}
	}
}