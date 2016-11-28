package fairygui.extention.win
{
	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-8-10下午8:12:51 <br/>
	 **/
	import com.greensock.TweenLite;
	
	import flash.geom.Point;
	
	import fairygui.GComponent;
	import fairygui.GLabel;
	import fairygui.GObject;
	import fairygui.RelationType;
	import fairygui.UIPackage;
	import fairygui.Window;
	import fairygui.extention.ns.ns_fairy_winExtention;
	import fairygui.extention.view.ViewWaiteExtention;
	
	import once.GameApp;
	
	public class WinExtentionBase extends Window
	{
		use namespace ns_fairy_winExtention;
		/**是否需要自动排列(若需要自动排列，则与舞台上的其他同样需要自动排列的窗口平铺在舞台中央展示，若不需要自动排列则窗口始终保持在屏幕中央)**/
		ns_fairy_winExtention var _needArrange:Boolean = false;
		/**绑定的窗口(当绑定的窗口被关闭时，自身也随之关闭，当自身被打开时若绑定窗口未打开则先打开绑定窗口)**/
		ns_fairy_winExtention var _bindWinCls:Class = null;
		/**共存的窗口列表**/
		ns_fairy_winExtention var _togetherWinClsList:Vector.<Class> = null;
		/**是否与所有窗口共存**/
		ns_fairy_winExtention var _togetherAll:Boolean = true;
		/**关闭的时候是否dispose**/
		ns_fairy_winExtention var _hideAndDispose:Boolean = false;
		/**接收参数的函数**/
		ns_fairy_winExtention var _updateMethod:Function = null;
		
		internal var _openArgs:Array = null;
		
		private var _contentPane:GComponent;
		private var _frame:GLabel;
		private var _contentArea:GObject;
		private var _modalWaitPane:ViewWaiteExtention;
		
		private var _modalWaiteStr:String = "请稍等。。。";
		public function WinExtentionBase()
		{
			super();
			initPropsAt_ns_fairy_winExtension();
			packageItem = UIPackage.getItemByURL(url);
			constructFromResource();
			contentPane = this;
		}
		//***************
		//internal
		//***************
		/**重新打开窗口**/
		internal function ReOpen():void
		{
			addEvents();
			initializeReopen();
			initializeAways();
			_updateMethod && _updateMethod.apply(null, _openArgs);
			_openArgs = null;
		}
		/**窗口已经打开，再次打开此窗口并且打开参数不为空的时候会选择刷新该窗口**/
		internal function Refresh():void
		{
			_updateMethod && _updateMethod.apply(null, _openArgs);
			_openArgs = null;
		}
			
		internal function get modalWaiteStr():String
		{
			return _modalWaiteStr;
		}
		internal function set modalWaiteStr(value:String):void
		{
			_modalWaiteStr = value;
		}
		//***************
		//noticeHandler
		//***************
		
		//***************
		//protected
		//***************
		protected function get url():String
		{
			return null;
		}
		/**初始化ns_fairy_winExtension命名空间下的属性**/
		protected function initPropsAt_ns_fairy_winExtension():void
		{
			
		}
		/**重新打开**/
		protected function initializeReopen():void
		{
			
		}
		/**第一次打开或者每次重新打开都会调用的**/
		protected function initializeAways():void
		{
			
		}
		/**只有第一次打开会调用，并且最先调用**/
		protected function initlializePrev():void
		{
			
		}
		/**只有第一次打开会调用**/
		protected function initialize():void
		{
			
		}
		/**只有在窗口已经打开,并且又触发了此窗口的打开逻辑,并且打开参数不为空时调用**/
		protected function onRefresh():void
		{
			
		}
		/**被移除的时候调用**/
		protected function removed():void
		{
			
		}
		/**每次打开都调用**/
		protected function addEvents():void
		{
			
		}
		/**每次被移除都调用**/
		protected function delEvents():void
		{
			
		}
		
		final protected function callLater(handler:Function, ...args):void
		{
			GameApp.render.callLater(handler, args);
		}
		
		final protected function callLaterGc(handler:Function):void
		{
			GameApp.render.callLaterGc(handler);
		}
		
		/*override protected function doShowAnimation():void
		{
			this.setPivot(0.5,0.5);
			this.scaleX = 0.7;
			this.scaleY = 0.7;
			TweenLite.to(this,0.15,{
				scaleX:1,
				scaleY:1,
				ease:Quad.easeOut,
				onComplete:this.__tweenComplete1
			});
		}*/
		override final protected function onInit():void
		{
			super.onInit();
			initlializePrev();
			addEvents();
			initialize();
			initializeAways();
			_updateMethod && _updateMethod.apply(null, _openArgs);
			_openArgs = null;
		}
		override final public function hideImmediately():void
		{
			delEvents();
			removed();
			super.hideImmediately();
			_hideAndDispose && dispose();// : closeModalWait();
		}
		override final protected function layoutModalWaitPane():void
		{
			if(_contentArea!=null)
			{
				var pt:Point = _frame.localToGlobal();
				pt = this.globalToLocal(pt.x, pt.y);
				_modalWaitPane.setXY(pt.x+_contentArea.x, pt.y+_contentArea.y);
				_modalWaitPane.setSize(_contentArea.width, _contentArea.height);
			}
			else
				_modalWaitPane.setSize(this.width, this.height);
		}
		//***************
		//private
		//***************
		private function __tweenComplete1() : void
		{
			this.setPivot(0,0);
			this.onShown();
		}
		//***************
		//eventHandler
		//***************
		
		//***************
		//public
		//***************
		override final public function set contentPane(val:GComponent):void
		{
			if(_contentPane!=val)
			{
				if(_contentPane!=null)
					removeChild(_contentPane);
				_contentPane = val;
				if(_contentPane!=null)
				{
					_contentPane!=this && addChild(_contentPane);
					this.setSize(_contentPane.width, _contentPane.height);
					_contentPane.addRelation(this, RelationType.Size);
					_frame = _contentPane.getChild("frame") as GLabel;
					if (_frame != null)
					{
						this.closeButton = _frame.getChild("closeButton");
						this.dragArea = _frame.getChild("dragArea");
						this.contentArea = _frame.getChild("contentArea");
					}
				}
			}
		}
		override public function get contentArea():GObject
		{
			return _contentArea;
		}
		
		override public function set contentArea(value:GObject):void
		{
			_contentArea = value;
		}
		override public function get contentPane():GComponent
		{
			return _contentPane;
		}
		override public function get frame():GComponent
		{
			return _frame;
		}
		/*override public function showModalWait(requestingCmd:int=0):void
		{
			if (requestingCmd != 0)
				_requestingCmd=requestingCmd;
			
			if(UIConfig.windowModalWaiting)
			{
				if(!_modalWaitPane)
					_modalWaitPane = UIPackage.createObjectFromURL(UIConfig.windowModalWaiting) as ViewWaiteExtention;
				
				layoutModalWaitPane();
				
				addChild(_modalWaitPane);
			}
		}
		override public function closeModalWait(requestingCmd:int=0):Boolean
		{
			if (requestingCmd != 0)
			{
				if (_requestingCmd != requestingCmd)
					return false;
			}
			_requestingCmd=0;
			
			if (_modalWaitPane && _modalWaitPane.parent!=null)
				removeChild(_modalWaitPane);
			
			return true;
		}*/
		
		override public function get modalWaiting():Boolean
		{
			return _modalWaitPane && _modalWaitPane.parent!=null;
		}
		override public function dispose():void
		{
			_bindWinCls = null;
			_togetherWinClsList = null;
			_updateMethod = null;
			
			TweenLite.killTweensOf(this);
			contentPane = null;
			_modalWaitPane && _modalWaitPane.dispose();
			_modalWaitPane = null;
			super.dispose();
		}
	}
}