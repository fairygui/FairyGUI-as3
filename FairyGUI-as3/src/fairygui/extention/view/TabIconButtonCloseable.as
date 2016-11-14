package fairygui.extention.view
{
	import fairygui.GButton;
	import fairygui.GGraph;
	import fairygui.event.GTouchEvent;

	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-10-31下午5:30:21 <br/>
	 **/
	public final class TabIconButtonCloseable extends GButton
	{
		private var _btnClose:GButton;
		private var _belongTo:TabViewCloseableIconButton;
		private var _id:String;
		private var _tip:GGraph;
		public function TabIconButtonCloseable()
		{
			super();
		}
		//***************
		//internal
		//***************
		internal function Update(id:String, iconUrl:String, textContent:String, belongTo:TabViewCloseableIconButton, toolTip:String=null):void
		{
			_id = id;
			icon = iconUrl;
			text = textContent;
			_belongTo = belongTo;
			toolTip && (_tip.tooltips = toolTip); 
		}
		//***************
		//noticeHandler
		//***************
		
		//***************
		//protected
		//***************
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			_btnClose = getChild("closeButton").asButton;
			_tip = getChild("tip").asGraph;
			_btnClose.addClickListener(OnBtnClose);
		}
		/*override protected function prevInitialize():void
		{
			
		}
		override protected function addEvents():void
		{
			
		}
		override protected function delEvents():void
		{
			
		}*/
		//***************
		//private
		//***************
		
		//***************
		//eventHandler
		//***************
		private function OnBtnClose(e:GTouchEvent):void
		{
			e.stopPropagation();
			_belongTo.DelTab(_id);
		}
		//***************
		//public
		//***************
		override public function dispose():void
		{
			_btnClose.removeClickListener(OnBtnClose);
			super.dispose();
			_btnClose = null;
			_belongTo = null;
		}
	}
}