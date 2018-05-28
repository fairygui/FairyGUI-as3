package ktv.ui
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	
	import fairygui.GLoader;
	import fairygui.utils.ToolSet;
	
	import ktv.gifv.GIFBoy;
	import ktv.gifv.GIFEvent;
	import ktv.managers.ManagerSkin;
	import ktv.message.local.UIEvent;
	import ktv.message.local.UIEventDispatcher;
	import ktv.morn.core.handlers.Handler;
	import ktv.morn.core.managers.LogManager;
	import ktv.morn.core.managers.MassLoaderManager;
	import ktv.morn.core.managers.ResLoader;
	
	public class KLoader extends GLoader
	{
		private var massLoader:MassLoaderManager=MassLoaderManager.getInstance();
		private var _assetsURL:String;
		private var gif:GIFBoy;
		private var _moreSkin:Boolean;
		public function KLoader()
		{
			
		}
		
		override protected function createDisplayObject():void
		{
			super.createDisplayObject();
			moreSkin=true;
		}
		
		public function changeSkin(event:UIEvent):void
		{
			url=ManagerSkin.getSkin(url);
		}
		
		public override function dispose():void
		{
			super.dispose();
			moreSkin=false;
			if(gif)
			{
				gif.removeEventListener(GIFEvent.OK, gifOk);
				gif.dispose();
			}
			clearBitmap();
		}
		
		//修改父类的   清理方法  只有在加载完毕后 才 清理之前的内容
		protected override function loadContent():void
		{
			if(!url)
				return;
			
			if(ToolSet.startsWith(url, "ui://"))
				loadFromPackage(url);
			else
				loadExternal();
		}
		
		override protected function loadExternal():void
		{
			_assetsURL=url;
			loadBMD(assetsURL);
		}
		
		private function loadBMD(tempURL:String):void
		{
			var typeStr:String=tempURL.substr(tempURL.lastIndexOf("."));
			var loadType:int=ResLoader.BMD;
			if (typeStr.toLowerCase() == ".gif")
			{
				loadType=ResLoader.GIF;
			}
			massLoader.load(tempURL, loadType, 1, new Handler(giftImgComplete), null, new Handler(errorHandler), false);
		}
		
		private function errorHandler(errorURL:String):void
		{
			if(moreSkin)
			{
				var ary:Array=url.split("/");
				if(ary.indexOf("skin0") != -1)//默认皮肤加载错误
				{
					this.dispatchEvent(new Event(UIEvent.IMAGE_ERROR));
					LogManager.log.error("默认皮肤skin0不存在"+url);
				}
				else
				{
					url=ManagerSkin.getSkin(url,0);//使用默认的皮肤
				}
			}
			else
			{
				this.dispatchEvent(new Event(UIEvent.IMAGE_ERROR));
			}
		}
		
		private function giftImgComplete(tempContent:*):void
		{
			if (tempContent)
			{
				clearContent();
				if (tempContent is BitmapData)
				{
					texture=tempContent as BitmapData;
					Bitmap(content).smoothing=true;
				}
				else if (tempContent is GIFBoy)
				{
					gif=tempContent as GIFBoy;
					gif.addEventListener(GIFEvent.OK, gifOk);
				}
				this.dispatchEvent(new Event(UIEvent.IMAGE_COMPLETE));
			}
		}
		
		private function gifOk(e:GIFEvent):void
		{
			gif.removeEventListener(GIFEvent.OK, gifOk);
			onExternalLoadSuccess(gif);
		}
		
		public function get moreSkin():Boolean
		{
			return _moreSkin;
		}

		/**
		 *是否 含有更多皮肤 
		 * @param value
		 */
		public function set moreSkin(value:Boolean):void
		{
			_moreSkin = value;
			if(_moreSkin)
			{
				UIEventDispatcher.getInstance().addEventListener(UIEvent.CHANGE_SKIN, changeSkin);
			}else
			{
				UIEventDispatcher.getInstance().removeEventListener(UIEvent.CHANGE_SKIN, changeSkin);
			}
		}
		
		public function clearBitmap():void
		{
			if(content is Bitmap)
			{
				Bitmap(content).bitmapData.dispose();
			}
			if(content!=null && content.parent!=null) 
			{
				content.parent.removeChild(content);
			}
		}

		public function get assetsURL():String
		{
			return _assetsURL;
		}

		
	}
}