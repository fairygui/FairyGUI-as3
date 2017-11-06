package ktv.morn.core.managers
{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;

	/**日志管理器*/
	public class LogManagerWindow extends Sprite
	{
		public var logWindow:NativeWindow;
		private var _logWindowRect:Rectangle=new Rectangle(0,0,LogManager.BG_WIDTH,LogManager.BG_HEIGHT);
		public var mainStage:Stage;
		public function LogManagerWindow(mian:Stage)
		{
			this.mainStage=mian;
			init();
		}

		private function init():void
		{
			if(!logWindow)
			{
				logWindow=creatWindow(logWindowRect);
				LogManager.log.type=LogManager.TYPE_WINDOW;
				LogManager.log.stageWindow=logWindow.stage;
				LogManager.log.addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
				logWindow.stage.addChild(LogManager.log);
				logWindow.activate();
			}
			if(logWindow.visible)
			{
				logWindow.orderToFront();
				logWindow.alwaysInFront=logWindow.owner.alwaysInFront=true;
			}
		}

		public function dispose():void
		{
			LogManager.log.removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			mainStage.nativeWindow.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			logWindow.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			LogManager.log.stageWindow.removeEventListener(MouseEvent.MOUSE_UP, onMoveDown);
			LogManager.log.stageWindow.removeEventListener(MouseEvent.MOUSE_MOVE, onMoveDown);
			LogManager.log.close.removeEventListener(MouseEvent.CLICK, onCloseClick);
			if(logWindow)
			{
				logWindow.close();	
			}
			trace("清理LogManagerWindow");
		}
 
		private function onAddedToStage(e:Event):void
		{
			mainStage.nativeWindow.stage.addEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			logWindow.stage.addEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			LogManager.log.moveBox.addEventListener(MouseEvent.MOUSE_DOWN, onMoveDown);
			LogManager.log.close.addEventListener(MouseEvent.CLICK, onCloseClick);
		}
		
		private function onCloseClick(e:MouseEvent):void
		{
			toggle(false);
		}

		private function onMoveDown(e:MouseEvent):void
		{
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				LogManager.log.stageWindow.nativeWindow.startMove();
				LogManager.log.stageWindow.addEventListener(MouseEvent.MOUSE_UP, onMoveDown);
				LogManager.log.stageWindow.addEventListener(MouseEvent.MOUSE_MOVE, onMoveDown);
			}
			else if (e.type == MouseEvent.MOUSE_MOVE)
			{
				e.updateAfterEvent();
			}
			else if (e.type == MouseEvent.MOUSE_UP)
			{
				LogManager.log.stageWindow.removeEventListener(MouseEvent.MOUSE_UP, onMoveDown);
				LogManager.log.stageWindow.removeEventListener(MouseEvent.MOUSE_MOVE, onMoveDown);
			}
		}
		
		private function onStageKeyDown(e:KeyboardEvent):void
		{
			if (e.ctrlKey && e.keyCode == Keyboard.L)
			{
				var isShow:Boolean=!logWindow.visible;
				toggle(logWindow.visible);
			}
		}

		/**打开或隐藏面板*/
		public function toggle(isShow:Boolean):void
		{
			logWindow.visible=isShow;
			if(logWindow.visible)
			{
				logWindow.orderToFront();
				logWindow.alwaysInFront=logWindow.owner.alwaysInFront=true;
				LogManager.log.showToggle();
			}else
			{
				logWindow.alwaysInFront=false;
				LogManager.log.hideToggle();
			}
		}

		/**
		 *创建新窗口(窗口默认最小宽度144)
		 * xx:X坐标, yy:Y坐标, wid:宽度, hei:高度
		 */
		private function creatWindow(rect:Rectangle, transparent:Boolean=true, nativeWindowType:String=NativeWindowType.NORMAL):NativeWindow
		{
			var option:NativeWindowInitOptions=new NativeWindowInitOptions;
			option.renderMode=mainStage.nativeWindow.renderMode;
			option.systemChrome=NativeWindowSystemChrome.NONE;
			option.transparent=transparent;
			option.type=nativeWindowType;
			option.owner=mainStage.nativeWindow;
			var win:NativeWindow=new NativeWindow(option);
			win.stage.align=StageAlign.TOP_LEFT;
			win.stage.scaleMode=StageScaleMode.NO_SCALE;
			win.bounds=rect;
			return win;
		}

		public function get logWindowRect():Rectangle
		{
			return _logWindowRect;
		}

		public function set logWindowRect(value:Rectangle):void
		{
			_logWindowRect = value;
			if(logWindow)
			{
				logWindow.bounds=_logWindowRect;
			}
		}

	}
}