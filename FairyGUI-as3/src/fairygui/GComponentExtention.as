package fairygui
{
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	
	import once.GameApp;
	import once.methods.Method;
	import once.utils.LogUtils;

	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-8-18上午11:56:45 <br/>
	 **/
	
	public class GComponentExtention extends GComponent
	{
		private var _state:uint = STATE_DISPLAY_REMOVED;
		public static const STATE_DISPLAY_ADDED:uint = 1;
		public static const STATE_DISPLAY_REMOVED:uint = 2;
		protected var _showMethod:Method;
		private var _inited:Boolean = false;
		public function GComponentExtention()
		{
			super();
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
		protected function get url():String
		{
			return "";
		}
		protected function callLater(handler:Function):void
		{
			GameApp.render.callLater(handler);
		}
		protected function callLaterGc(handler:Function):void
		{
			GameApp.render.callLaterGc(handler);
		}
		override protected function constructFromXML(xml:XML):void
		{
			super.constructFromXML(xml);
			opaque = false;
			if(this.parent==null) displayObject.addEventListener(Event.ADDED, FirstAdded);
			else callLater(Init);
		}
		protected function addEvents():void
		{
			
		}
		protected function delEvents():void
		{
			
		}
		protected function prevInitialize():void
		{
			
		}
		protected function initialize():void
		{
			
		}
		protected function initializeReAdd():void
		{
			
		}
		protected function initAways():void
		{
			
		}
		protected function removed():void
		{
			
		}
		protected function doHideAnimate():void
		{
			HideImmediately();
		}
		
		protected function get underConstruct():Boolean
		{
			return _underConstruct;
		}
		//***************
		//private
		//***************
		private function Init():void
		{
			displayObject.addEventListener(Event.ADDED, ReAdd);
			displayObject.addEventListener(Event.ADDED_TO_STAGE, ReAdd);
			displayObject.addEventListener(Event.REMOVED, OnRemoved);
			displayObject.addEventListener(Event.REMOVED_FROM_STAGE, OnRemoved);
			prevInitialize();
			addEvents();
			initialize();
			initAways();
			
		}
		private function HideImmediately():void
		{
			if(parent!=null) parent.removeChild(this);
			else if(displayObject.parent!=null) displayObject.parent.removeChild(displayObject);
		}
		//***************
		//eventHandler
		//***************
		private function FirstAdded(e:Event):void
		{
			if(e.target==displayObject)
			{
				displayObject.removeEventListener(Event.ADDED, FirstAdded);
				_state = STATE_DISPLAY_ADDED;
				Init();
			}
		}
		private function ReAdd(e:Event):void
		{
			if(e.target==displayObject && _state==STATE_DISPLAY_REMOVED)
			{
				_state = STATE_DISPLAY_ADDED;
				addEvents();
				initAways();
				initializeReAdd();
			}
		}
		private function OnRemoved(e:Event):void
		{
			if(e.target==displayObject && _state==STATE_DISPLAY_ADDED)
			{
				_state = STATE_DISPLAY_REMOVED;
				delEvents();
				removed();
			}
		}
		//***************
		//public
		//***************
		final public function remove():void
		{
			parent && parent.removeChild(this);
		}
		final public function show(parent:*, ...args):void
		{
			if(parent is GComponent) (parent as GComponent).addChild(this);
			else if(parent is DisplayObjectContainer) (parent as DisplayObjectContainer).addChild(displayObject);
			else
			{
				LogUtils.error("提供的父容器不是容器");
				return;
			}
			_showMethod && _showMethod.executeExtra.apply(null, args);
		}
		final public function hide():void
		{
			doHideAnimate();
		}
		final public function get hasParent():Boolean
		{
			return parent!=null || displayObject.parent!=null;
		}
		override public function dispose():void
		{
			_showMethod && Method.Return(_showMethod);
			_showMethod = null;
			delEvents();
			removed();
			if(displayObject!=null)
			{
				displayObject.removeEventListener(Event.ADDED, ReAdd);
				displayObject.removeEventListener(Event.ADDED_TO_STAGE, ReAdd);
				displayObject.removeEventListener(Event.REMOVED, OnRemoved);
				displayObject.removeEventListener(Event.REMOVED_FROM_STAGE, OnRemoved);
			}
			super.dispose();
		}
	}
}