package ktv.managers
{
	import flash.net.LocalConnection;
	
	import fairygui.GComponent;
	import fairygui.GObject;
	import fairygui.GRoot;

	/**
	 * 在  App  这个类里面 实例化了
	 * ...图层视图 深度管理
	 * @author Adobe
	 */
	public class ManagerLayer
	{
		private static var instance:ManagerLayer;
		/**
		 * 背景层	0
		 */
		public static const LAYER_BG:String="layer_bg";
		private var layer_bg:GComponent=new GComponent();

		/**
		 * 面板层	1
		 */
		public static const LAYER_PANEL:String="layer_panel";
		private var layer_panel:GComponent=new GComponent();
		/**
		 *  错误(提示)弹出框 层	2
		 */
		public static const LAYER_DIALOG:String="layer_dialog";
		private var layer_dialog:GComponent=new GComponent();

		/**
		 * 提示层(大帮助图片层) 形象页	3
		 */
		public static const LAYER_COVRE:String="layer_cover";
		private var layer_cover:GComponent=new GComponent();

		public function ManagerLayer()
		{
			init();
		}
		
		public  function init():void
		{
			GRoot.inst.addChild(layer_bg);
			GRoot.inst.addChild(layer_panel);
			GRoot.inst.addChild(layer_dialog);
			GRoot.inst.addChild(layer_cover);
		}

		/**
		 * 获取层级
		 * @param	layer
		 * @return
		 */
		public function getLayer(layer:String=ManagerLayer.LAYER_PANEL):GComponent
		{
			return this[""+layer] as GComponent;
		}

		/**
		 * 添加到ui层级  默认 是添加在 LayerTool.PANEL_LAYER
		 * @param	display
		 * @param	layer
		 */
		public function addUI(display:GObject, layer:String=ManagerLayer.LAYER_PANEL):GObject
		{
			return getLayer(layer).addChild(display);
		}

		/**
		 * 添加到指定位置的ui
		 * @param	display 当前显示对象
		 * @param	index 添加的索引值
		 * @param	layer 添加到的层级
		 * @return 返回当前display的实例
		 */
		public function addUIAt(display:GObject, layer:String=ManagerLayer.LAYER_PANEL, index:int=0):GObject
		{
			return getLayer(layer).addChildAt(display, index);
		}
		/**
		 * 移除指定层级上的UI  默认 是移除在 LayerTool.PANEL_LAYER
		 * @param	display
		 * @param	layer
		 */
		public function removeUI(display:GObject,dispose:Boolean=false):GObject
		{
			if(display &&display.parent)
			{
				return display.parent.removeChild(display,dispose);
			}
			trace("ManagerLayer"+"移除Gobject的parent不存在");
			return null;
		}

		/**
		 *移除指定层级上指定索引的UI  默认 是移除在 LayerTool.PANEL_LAYER
		 * @param	display 当前显示对象
		 * @param	index 添加的索引值
		 * @param	layer 添加到的层级
		 * @return 返回当前display的实例
		 */
		public function removeUIAt(index:int=0,layer:String=ManagerLayer.LAYER_PANEL):GObject
		{
			return getLayer(layer).removeChildAt(index);
		}
		
		public function setChildIndex(display:GObject,index:int=0):void
		{
			if(display && display.parent)
			{
				display.parent.setChildIndex(display,index);
			}
		}

		public function dispose():void
		{
			layer_bg.removeChildren(0,-1,true);
			layer_bg.removeFromParent();
			layer_panel.removeChildren(0,-1,true);
			layer_panel.removeFromParent();
			layer_dialog.removeChildren(0,-1,true);
			layer_dialog.removeFromParent();
			layer_cover.removeChildren(0,-1,true);
			layer_cover.removeFromParent();
			trace("dispose():LayerTool");
		}

		public static function getInstance():ManagerLayer
		{
			if (!instance)
			{
				instance=new ManagerLayer();
			}
			return instance;
		}
		
		public function GC():void
		{
			trace("GC");
			try
			{
				new LocalConnection().connect("foo");
				new LocalConnection().connect("foo");
			}
			catch(error : Error)
			{
				
			}
		}

	}

}