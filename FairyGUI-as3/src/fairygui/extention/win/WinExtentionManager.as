package fairygui.extention.win
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import fairygui.GRoot;
	import fairygui.UIConfig;
	import fairygui.UIPackage;
	import fairygui.extention.ns.ns_fairy_winExtention;
	import fairygui.extention.view.ViewWaiteExtention;
	
	import once.GameApp;
	
	import tools.storage.DictionaryBase;

	/**
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-8-10下午8:56:49 <br/>
	 **/
	public final class WinExtentionManager
	{
		public static const Instance:WinExtentionManager = new WinExtentionManager();
		private var _showingMap:DictionaryBase = new DictionaryBase();
		private var _winDragRect:Rectangle = new Rectangle();
		private var _viewWaite:ViewWaiteExtention;
		public function WinExtentionManager()
		{
			if(Instance!=null) throw new Error("单例类不要直接实例化");
			if(GRoot.inst.nativeStage!=null)
			{ Init(); }
			else GameApp.timer.doFrameLoop(1, OnEnterFrame);
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
		private function OnEnterFrame():void
		{
			if(GRoot.inst.nativeStage!=null)
			{
				GameApp.timer.clearTimer(OnEnterFrame);
				Init();
			}
		}
				
		private function Init():void
		{
			GRoot.inst.nativeStage.addEventListener(Event.RESIZE, OnStageResize);
			_winDragRect.width = GRoot.inst.width;
			_winDragRect.height = GRoot.inst.height;
		}
		private function ArrangeAll():void
		{
			_winDragRect.width = GRoot.inst.width;
			_winDragRect.height = GRoot.inst.height;
			for each(var win:WinExtentionBase in _showingMap)
			{
				win.center();
			}
		}
		//***************
		//eventHandler
		//***************
		private function OnStageResize(e:Event):void
		{
			ArrangeAll();
		}
		//***************
		//public
		//***************
		/**打开窗口**/
		public function Open(winExtensionCls:Class, ...args):WinExtentionBase
		{
			var winOpen:WinExtentionBase = _showingMap[winExtensionCls];
			if(winOpen==null)
			{
				winOpen = new winExtensionCls() as WinExtentionBase;
				if(winOpen==null) throw new Error(winExtensionCls + "不是WinExtensionBase的子类");
				//拖拽范围
				winOpen.dragBounds = _winDragRect;
				_showingMap.Add(winExtensionCls, winOpen);
				//关闭掉不共存的窗口
				if(!winOpen.ns_fairy_winExtention::_togetherAll)
				{
					loopShowing:for(var winShowingCls:Class in _showingMap)
					{
						//是绑定窗口，不关闭
						if(winShowingCls==winOpen.ns_fairy_winExtention::_bindWinCls) continue loopShowing;
						for each(var togetherWinCls:Class in winOpen.ns_fairy_winExtention::_togetherWinClsList)
						{
							//是共存窗口，不关闭
							if(winShowingCls==togetherWinCls) continue loopShowing;
						}
						Close(winShowingCls);
					}
				}
				//若绑定窗口未打开，先打开绑定窗口
				if(winOpen.ns_fairy_winExtention::_bindWinCls!=null) Open(winOpen.ns_fairy_winExtention::_bindWinCls);
				winOpen._openArgs = args;
			}
			else if(winOpen.parent!=null)
			{
				if(args.length==0)
				{
					Close(winExtensionCls);
					return null;
				}
				else
				{
					winOpen._openArgs = args;
					winOpen.ReOpen();
					winOpen.bringToFront();
					return winOpen;
				}
			}
			else
			{
				winOpen._openArgs = args;
				winOpen.ReOpen();
			}
			
			GRoot.inst.showWindow(winOpen);
			winOpen.center(true);
			return winOpen;
		}
		/**关闭窗口**/
		public function Close(winExtensionCls:Class, dispose:Boolean=false):void
		{
			var win:WinExtentionBase = _showingMap[winExtensionCls];
			if(win!=null)
			{
				CloseWaiteModal(winExtensionCls);
				if(dispose != win.ns_fairy_winExtention::_hideAndDispose) win.ns_fairy_winExtention::_hideAndDispose = dispose;
				//关闭掉绑定了本窗口的窗口
				var winShowing:WinExtentionBase;
				for(var winShowingCls:Class in _showingMap)
				{
					winShowing = _showingMap[winShowingCls];
					if(winShowing.ns_fairy_winExtention::_bindWinCls==winExtensionCls)
					{
						Close(winShowingCls);
					}
				}
				win.ns_fairy_winExtention::_hideAndDispose && _showingMap.Del(winExtensionCls);
				win.hide();
			}
		}
		/**关闭所有窗口，除了排除列表里的**/
		public function ClsoeAllExcept(...exceptList):void
		{
			for(var winExtensionCls:Class in _showingMap)
			{
				if(exceptList.indexOf(winExtensionCls)==-1)
				{
					Close(winExtensionCls);
				}
			}
		}
		/**获取窗口实例**/
		public function GetWin(winExtentionCls:Class):WinExtentionBase
		{
			return _showingMap[winExtentionCls];
		}
		/**显示等待提示**/
		public function ShowWaiteModal(winExtentionClass:Class, waiteStr:String=null):void
		{
			var win:WinExtentionBase = _showingMap[winExtentionClass];
			if(win!=null && win.contentArea!=null)
			{
				if(UIConfig.windowModalWaiting)
				{
					if(!_viewWaite)
					{ _viewWaite = UIPackage.createObjectFromURL(UIConfig.windowModalWaiting) as ViewWaiteExtention; }
					_viewWaite.ShowOn(win.contentArea, win);
				}
			}
		}
		/**关闭等待提示**/
		public function CloseWaiteModal(winExtentionClass:Class):void
		{
			var win:WinExtentionBase = _showingMap[winExtentionClass];
			if(win!=null && win.contentArea!=null)
			{
				_viewWaite && _viewWaite.HideFrome(win.contentArea);
			}
		}
	}
}