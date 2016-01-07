package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	
	import fairygui.Controller;
	import fairygui.DragDropManager;
	import fairygui.GButton;
	import fairygui.GComponent;
	import fairygui.GObject;
	import fairygui.GRichTextField;
	import fairygui.GRoot;
	import fairygui.PopupMenu;
	import fairygui.UIPackage;
	import fairygui.Window;
	import fairygui.event.DragEvent;
	import fairygui.event.DropEvent;

	public class MainPanel
	{
		private var _view:GComponent;
		private var _backBtn:GObject;
		private var _demoContainer:GComponent;
		private var _cc:Controller;
		
		private var _demoObjects:Object;

		public function MainPanel()
		{
			_view = UIPackage.createObject("Demo", "Demo").asCom;
			GRoot.inst.addChild(_view);
			
			_backBtn = _view.getChild("btn_Back");
			_backBtn.visible = false;
			_backBtn.addClickListener(onClickBack);
			
			_demoContainer = _view.getChild("container").asCom;
			_cc = _view.getController("c1");
			
			var cnt:int = _view.numChildren;
			for(var i:int=0;i<cnt;i++)
			{
				var obj:GObject = _view.getChildAt(i);
				if(obj.group!=null && obj.group.name=="btns")
					obj.addClickListener(runDemo);
			}
			
			_demoObjects = {};
		}
		
		private function runDemo(evt:Event):void
		{
			var type:String = GObject(evt.currentTarget).name.substr(4);
			var obj:GComponent = _demoObjects[type];
			if(obj==null)
			{
				obj = UIPackage.createObject("Demo", "Demo_"+type).asCom;
				_demoObjects[type] = obj;
			}
			
			_demoContainer.removeChildren();
			_demoContainer.addChild(obj);
			_cc.selectedIndex = 1;
			_backBtn.visible = true;
			
			switch(type)
			{
				case "Button":
					playButton();
					break;
				
				case "Text":
					playText();
					break;
				
				case "Transition":
					playTransition();
					break;
				
				case "Window":
					playWindow();
					break;
				
				case "PopupMenu":
					playPopupMenu();
					break;
				
				case "Drag&Drop":
					playDragDrop();
					break;
			}				
		}
		
		private function onClickBack(evt:Event):void
		{
			_cc.selectedIndex = 0;
			_backBtn.visible = false;
		}
		
		//------------------------------
		private function playButton():void
		{
			var obj:GComponent = _demoObjects["Button"];
			obj.getChild("n34").addClickListener(__clickButton);
		}
		
		private function __clickButton(evt:Event):void
		{
			trace("click button");
		}
		
		//------------------------------
		private function playText():void
		{
			var obj:GComponent = _demoObjects["Text"];
			obj.getChild("n12").asRichTextField.addEventListener(TextEvent.LINK, __clickLink);
		}
		
		private function __clickLink(evt:TextEvent):void
		{
			var obj:GRichTextField = evt.currentTarget as GRichTextField;
			obj.text = "[img]ui://9leh0eyft9fj5f[/img][color=#FF0000]你点击了链接[/color]：" + evt.text;
		}
		
		//------------------------------
		private function playTransition():void
		{
			var obj:GComponent = _demoObjects["Transition"];
			obj.getChild("n2").asCom.getTransition("t0").play(null, null, int.MAX_VALUE);
			obj.getChild("n3").asCom.getTransition("peng").play(null, null, int.MAX_VALUE);
			
			obj.addEventListener(Event.REMOVED_FROM_STAGE, __removeFromStage);
		}
		
		private function __removeFromStage(evt:Event):void
		{
			var obj:GComponent = _demoObjects["Transition"];
			obj.getChild("n2").asCom.getTransition("t0").stop();
			obj.getChild("n3").asCom.getTransition("peng").stop();
		}
		
		//------------------------------
		private var _winA:Window;
		private var _winB:Window;
		private function playWindow():void
		{
			var obj:GComponent = _demoObjects["Window"];
			obj.getChild("n0").addClickListener(__showWinA);			
			obj.getChild("n1").addClickListener(__showWinB);
		}
		
		private function __showWinA(evt:Event):void
		{
			if(_winA==null)
				_winA = new WindowA();
			_winA.show();
		}
		
		private function __showWinB(evt:Event):void
		{
			if(_winB==null)
				_winB = new WindowB();
			_winB.show();
		}
		
		//------------------------------
		private var _pm:PopupMenu;
		private function playPopupMenu():void
		{
			if(_pm==null)
			{
				_pm = new PopupMenu();
				_pm.addItem("Item 1");
				_pm.addItem("Item 2");
				_pm.addItem("Item 3");
				_pm.addItem("Item 4");
			}
			
			var obj:GComponent = _demoObjects["PopupMenu"];
			var btn:GObject = obj.getChild("n0");
			btn.addClickListener(__clickMenuBtn);
			obj.addEventListener(MouseEvent.RIGHT_CLICK, __rightClick);
		}
		
		private function __clickMenuBtn(evt:Event):void
		{
			_pm.show(GObject(evt.currentTarget), true);
		}
		
		private function __rightClick(evt:MouseEvent):void
		{
			_pm.show();
		}
		
		//------------------------------
		private function playDragDrop():void
		{
			var obj:GComponent = _demoObjects["Drag&Drop"];
			obj.getChild("n0").draggable = true;
			
			var btn1:GButton = obj.getChild("n1").asButton;
			btn1.draggable = true;
			btn1.addEventListener(DragEvent.DRAG_START,__dragStart);
			
			var btn2:GButton = obj.getChild("n2").asButton;
			btn2.icon = null;
			btn2.addEventListener(DropEvent.DROP,__drop);
		}
		
		private function __dragStart(evt:DragEvent):void
		{
			//取消对原目标的拖动，换成一个替代品
			evt.preventDefault();
			
			var btn:GButton = GButton(evt.currentTarget);
			DragDropManager.inst.startDrag(btn, btn.icon, btn.icon, evt.touchPointID);
		}
		
		private function __drop(evt:DropEvent):void
		{
			GButton(evt.currentTarget).icon = String(evt.source);
		}
		
	}
}