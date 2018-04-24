package ktv.morn.core.managers
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Keyboard;

	/**日志管理器*/
	public class LogManager extends Sprite
	{
		private var logFontName:String="Microsoft YaHei";
		private var _msgs:Array=[];
		private var _box:Sprite;
		private var _textField:TextField;
		private var _filter:TextField;
		private var _filters:Array=[];
		private var _canScroll:Boolean=true;
		private var _scroll:TextField;
		private var _maxMsg:int=1000;
		private var _move:Bitmap;
		private var _close:TextField;
		private var colorArray:Array=[0xff0011, 0x77ff99, 0x99ffee, 0xff22dd, 0xff2211, 0x9bd948, 0x96ff73, 0x80ff00, 0x99ffff, 0xb9ff73, 0xff794c, 0xff4c4d, 0xffbfbf, 0xffdc73, 0xbfff00, 0x99ffe5, 0xbfffff, 0xff0000, 0x00ff00, 0xff26ff];

		private var clear2:TextField;

		private var copy:TextField;

		private var bitmapBg:Bitmap;

		private var txtSize:int=12;

		private var titleTextFormat:TextFormat;

		private var title:TextField;
		public static const BG_WIDTH:int=700;
		public static const BG_HEIGHT:int=500;
		private var _titleName:String="Debug";
		public var stageWindow:Stage;

		public static const log:LogManager=new LogManager();
		public static const TYPE_WINDOW:String="TYPE_WINDOW";
		public static const TYPE_MC:String="TYPE_MC";
		private var _type:String=TYPE_MC;

		private var _moveBox:Sprite;

		public function LogManager()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}

		private function init():void
		{
			//容器
			_box=new Sprite();
			bitmapBg=createBitmap(BG_WIDTH, BG_HEIGHT, 0x272f3b, 0.9) as Bitmap;
			_box.addChild(bitmapBg);
			_box.visible=false;
			addChild(_box);
			//筛选栏
			_filter=new TextField();
			_filter.width=270;
			_filter.height=20;
			_filter.type="input";
			_filter.textColor=0xffffff;
			_filter.border=true;
			_filter.borderColor=0xBFBFBF;
			_filter.defaultTextFormat=new TextFormat(logFontName, txtSize);
			_filter.addEventListener(KeyboardEvent.KEY_DOWN, onFilterKeyDown);
			_filter.addEventListener(FocusEvent.FOCUS_OUT, onFilterFocusOut);
			_box.addChild(_filter);
			//控制按钮			
			clear2=createLinkButton("Clear");
			clear2.addEventListener(MouseEvent.CLICK, onClearClick);
			clear2.x=280;
			_box.addChild(clear2);
			_scroll=createLinkButton("Pause");
			_scroll.addEventListener(MouseEvent.CLICK, onScrollClick);
			_scroll.x=315;
			_box.addChild(_scroll);
			copy=createLinkButton("Copy");
			copy.addEventListener(MouseEvent.CLICK, onCopyClick);
			copy.x=350;
			_box.addChild(copy);
			//信息栏
			_textField=new TextField();
			_textField.width=BG_WIDTH;
			_textField.height=480;
			_textField.y=20;
			_textField.multiline=true;
			_textField.wordWrap=true;
			_textField.defaultTextFormat=new TextFormat(logFontName);
			_textField.textColor=0xFF9900;
			_box.addChild(_textField);

			_move=createBitmap(BG_WIDTH - _filter.width, 22, 0xe86200, 1) as Bitmap;
			moveBox=new Sprite();
			if(type==TYPE_MC)
			{
				moveBox.addEventListener(MouseEvent.MOUSE_DOWN, onMoveDown);
			}
			moveBox.x=_filter.width;
			moveBox.addChild(_move);
			_box.addChildAt(moveBox, 1);
			_close=createMoveButton("关闭");
			_close.addEventListener(MouseEvent.CLICK, onCloseClick);
			_close.x=moveBox.x + moveBox.width - _close.width;
			_box.addChildAt(_close, 3);
			title=new TextField();
			title.mouseEnabled=false;
			title.x=copy.x + copy.width;
			title.y=copy.y;
			title.selectable=false;
			title.textColor=0xffffff;
			title.width=_close.x - (copy.x + copy.width);
			title.height=22;
			titleTextFormat=new TextFormat(logFontName);
			titleTextFormat.size=txtSize;
			titleTextFormat.letterSpacing=1;
			titleTextFormat.align=TextFormatAlign.CENTER;
			title.defaultTextFormat=titleTextFormat;
			title.text=titleName;
			_box.addChild(title);
			stageWindow.addEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			addEventListener(Event.REMOVED_FROM_STAGE, removeStage);
			addEventListener(MouseEvent.MOUSE_WHEEL, box_MOUSE_WHEEL);
		}

		private function createBitmap(width:int, height:int, color:uint=0, alpha:Number=1):Bitmap
		{
			var bitmap:Bitmap=new Bitmap(new BitmapData(1, 1, false, color));
			bitmap.alpha=alpha;
			bitmap.width=width;
			bitmap.height=height;
			return bitmap;
		}

		protected function box_MOUSE_WHEEL(event:MouseEvent):void
		{
			if (_box.visible)
			{
				if (event.ctrlKey)
				{
					changeTextSize(event.delta);
				}
			}
		}

		protected function removeStage(event:Event):void
		{
			removeEventListener(Event.REMOVED_FROM_STAGE, removeStage);
			dispose();
		}

		public function dispose():void
		{
			clear();
			_textField.text="";
			_msgs.length=0;
			_filters.length=0;
			_filter.removeEventListener(KeyboardEvent.KEY_DOWN, onFilterKeyDown);
			_filter.removeEventListener(FocusEvent.FOCUS_OUT, onFilterFocusOut);
			clear2.removeEventListener(MouseEvent.CLICK, onClearClick);
			_scroll.removeEventListener(MouseEvent.CLICK, onScrollClick);
			copy.removeEventListener(MouseEvent.CLICK, onCopyClick);
			_move.removeEventListener(MouseEvent.MOUSE_DOWN, onMoveDown);
			_close.removeEventListener(MouseEvent.CLICK, onCloseClick);
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMoveDown);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMoveDown);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			removeEventListener(MouseEvent.MOUSE_WHEEL, box_MOUSE_WHEEL);
			hideToggle();
			clear2.filters=null;
			_scroll.filters=null;
			copy.filters=null;
			_move.filters=null;
			_close.filters=null;
			bitmapBg.bitmapData.dispose();
			bitmapBg=null;
			_box=null;
			_textField=null;
			_filter=null;
			_scroll=null;
			_move=null;
			_close=null;
			trace("清理LogManager");
		}

		private function onMoveDown(e:MouseEvent):void
		{
			if (e.type == MouseEvent.MOUSE_DOWN)
			{
				this.startDrag();
				stageWindow.addEventListener(MouseEvent.MOUSE_UP, onMoveDown);
				stageWindow.addEventListener(MouseEvent.MOUSE_MOVE, onMoveDown);
			}
			else if (e.type == MouseEvent.MOUSE_MOVE)
			{
				e.updateAfterEvent();
			}
			else if (e.type == MouseEvent.MOUSE_UP)
			{
				this.stopDrag();
				stageWindow.removeEventListener(MouseEvent.MOUSE_UP, onMoveDown);
				stageWindow.removeEventListener(MouseEvent.MOUSE_MOVE, onMoveDown);
			}
		}

		private function onCloseClick(e:MouseEvent):void
		{
			hideToggle();
		}

		public function get debugIsShow():Boolean
		{
			return this._box.visible;
		}

		private function createMoveButton(text:String):TextField
		{
			var tf:TextField=new TextField();
			tf.selectable=false;
			tf.autoSize="center";
			tf.textColor=0xffffff;
			tf.backgroundColor=0xe86210;
			tf.border=true;
			tf.background=true;
			tf.width=80;
			tf.height=22;
			tf.filters=[new GlowFilter(0xffffff, 0.8, 2, 2, 10)];
			tf.text=text;
			return tf;
		}

		private function onAddedToStage(e:Event):void
		{
			if(!stageWindow)
			{
				stageWindow=stage;
			}
			stageWindow.addEventListener(KeyboardEvent.KEY_DOWN, onStageKeyDown);
			init();
		}

		private function createLinkButton(text:String):TextField
		{
			var tf:TextField=new TextField();
			tf.selectable=false;
			tf.autoSize="left";
			tf.textColor=0x0080C0;
			tf.backgroundColor=0xff0000;
			tf.border=true;
			tf.text=text;
			tf.filters=[new GlowFilter(0xffffff, 0.8, 2, 2, 10)];
			return tf;
		}

		private function onCopyClick(e:MouseEvent):void
		{
			System.setClipboard(_textField.text);
		}

		private function onScrollClick(e:MouseEvent):void
		{
			_canScroll=!_canScroll;
			_scroll.text=_canScroll ? "Pause" : "Start";
			if (_canScroll)
			{
				refresh(null);
			}
		}

		private function onClearClick(e:MouseEvent):void
		{
			clear();
			txtSize=12;
			changeTextSize();
		}

		private function onFilterKeyDown(e:KeyboardEvent):void
		{
			if (e.keyCode == Keyboard.ENTER)
			{
				stageWindow.focus=_box;
			}
		}

		private function onFilterFocusOut(e:FocusEvent):void
		{
			_filters=Boolean(_filter.text) ? _filter.text.split(",") : [];
			refresh(null);
		}

		private function onStageKeyDown(e:KeyboardEvent):void
		{
			if (e.ctrlKey && e.keyCode == Keyboard.L)
			{
				toggle();
			}
		}

		/**清理所有日志*/
		public function clear():void
		{
			_msgs.length=0;
			_textField.htmlText="";
		}

		/**信息*/
		public function info(... args):void
		{
			print("[info]", args, 0x3EBDF4);
		}

		/**消息*/
		public function send(... args):void
		{
			print("[send]", args, 0x00C400);
		}
		/**消息*/
		public function receive(... args):void
		{
			print("[receive]", args, 0x99ffee);
		}

		/**调试*/
		public function debug(... args):void
		{
			print("[debug]", args, 0xdddd00);
		}

		/**错误*/
		public function error(... args):void
		{
			print("[error]", args, 0xFF4646);
		}

		/**警告*/
		public function warn(... args):void
		{
			print("[warn]", args, 0xFFFF80);
		}

		public function print(type:String, args:Array, color:uint):void
		{
			trace(type, args.join(" "));
			if (!_box || !_box.visible)
				return;
			var msg:String="<font size='20' color='#" + color.toString(16) + "'><b>" + type + "</b></font><font color='#" + color.toString(16) + "'>" + args.join(" ") + "</font>";
			if (_msgs.length > _maxMsg)
			{
				_msgs.length=0;
			}
			_msgs.push(msg);
			if (_box.visible)
			{
				refresh(msg);
			}
		}

		/**打印XML信息*/
		public function debugXML(str:String):void
		{
			if (_box.visible)
			{
				var startIndex:int=_textField.text.length;
				_textField.appendText(str);
				var textFor:TextFormat=new TextFormat(logFontName, null, colorArray[int(colorArray.length * Math.random())]);
				_textField.setTextFormat(textFor, startIndex, _textField.text.length);
				if (_canScroll)
				{
					_textField.scrollV=_textField.maxScrollV;
				}
			}
			if (_textField.text.length > 1000)
			{
//				clear();
			}
		}


		/**隐藏面板*/
		public function hideToggle():void
		{
			_box.visible=false;
			_textField.text="";
			_textField.htmlText="";
		}

		public function changeTextSize(size:int=0):void
		{
			txtSize+=size;
			var textFor:TextFormat=new TextFormat(logFontName, txtSize);
			_textField.setTextFormat(textFor);
		}

		/**打开或隐藏面板*/
		public function toggle():void
		{
			_box.visible=!_box.visible;
			if (_box.visible)
			{
				refresh(null);
			}
			else
			{
				hideToggle();
			}
		}

		public function showToggle():void
		{
			_box.visible=true;
			refresh(null);
		}

		/**根据过滤刷新显示*/
		private function refresh(newMsg:String):void
		{
			var msg:String="";
			if (newMsg != null)
			{
				if (isFilter(newMsg))
				{
					msg=(_textField.htmlText || "") + newMsg;
					_textField.htmlText=msg;
				}
			}
			else
			{
				_textField.htmlText=getMsgFromCache();
			}
			if (_canScroll)
			{
				_textField.scrollV=_textField.maxScrollV;
			}
		}

		private function getMsgFromCache():String
		{
			var msg:String="";
			for each (var item:String in _msgs)
			{
				if (isFilter(item))
				{
					msg+=item;
				}
			}
			return msg;
		}

		/**是否是筛选属性*/
		private function isFilter(msg:String):Boolean
		{
			if (_filters.length < 1)
			{
				return true;
			}
			for each (var item:String in _filters)
			{
				if (msg.indexOf(item) > -1)
				{
					return true;
				}
			}
			return false;
		}

		public function get titleName():String
		{
			return _titleName;
		}

		public function set titleName(value:String):void
		{
			_titleName=value;
			title.defaultTextFormat=titleTextFormat;
			title.text=titleName;
		}

		public function get type():String
		{
			return _type;
		}

		public function set type(value:String):void
		{
			_type=value;
		}

		public function get moveBox():Sprite
		{
			return _moveBox;
		}

		public function set moveBox(value:Sprite):void
		{
			_moveBox = value;
		}

		public function get close():TextField
		{
			return _close;
		}

		public function set close(value:TextField):void
		{
			_close = value;
		}


	}
}