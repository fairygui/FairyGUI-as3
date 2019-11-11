package fairygui
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	
	import fairygui.display.UIImage;
	import fairygui.utils.ToolSet;

	public class GImage extends GObject
	{
		private var _bmdSource:BitmapData;
		private var _content:Bitmap;
		private var _color:uint;
		private var _flip:int;
		private var _contentItem:PackageItem;
			
		public function GImage()
		{
			_color = 0xFFFFFF;
		}
		
		public function get color():uint
		{
			return _color;
		}
		
		public function set color(value:uint):void 
		{
			if(_color != value)
			{
				_color = value;
				updateGear(4);
				applyColor();
			}
		}
		
		private function applyColor():void
		{
			var ct:ColorTransform = _content.transform.colorTransform;
			ct.redMultiplier = ((_color>>16)&0xFF)/255;
			ct.greenMultiplier = ((_color>>8)&0xFF)/255;
			ct.blueMultiplier = (_color&0xFF)/255;
			_content.transform.colorTransform = ct;
		}
		
		public function get flip():int
		{
			return _flip;
		}
		
		public function set flip(value:int):void
		{
			if(_flip!=value)
			{
				_flip = value;
				updateBitmap();
			}
		}
		
		public function get texture():BitmapData
		{
			return _bmdSource;
		}
		
		public function set texture(value:BitmapData):void
		{
			_bmdSource = value;
			handleSizeChanged();
		}
		
		override protected function createDisplayObject():void
		{ 
			_content = new UIImage(this);
			setDisplayObject(_content);
		}
		
		override public function dispose():void
		{
			if(_contentItem && !_contentItem.loaded)
				_contentItem.owner.removeItemCallback(_contentItem, __imageLoaded);
			
			if(_content.bitmapData!=null && _content.bitmapData!=_bmdSource)
			{
				_content.bitmapData.dispose();
				_content.bitmapData = null;
			}
			
			super.dispose();
		}
		
		override public function constructFromResource():void
		{
			_contentItem = packageItem.getBranch();

			sourceWidth = _contentItem.width;
			sourceHeight = _contentItem.height;
			initWidth = sourceWidth;
			initHeight = sourceHeight;
			
			setSize(sourceWidth, sourceHeight);

			_contentItem = _contentItem.getHighResolution();
			if(_contentItem.loaded)
				__imageLoaded(_contentItem);
			else
				_contentItem.owner.addItemCallback(_contentItem, __imageLoaded);
		}

		private function __imageLoaded(pi:PackageItem):void
		{
			if(_bmdSource!=null)
				return;
			
			_bmdSource = pi.image;
			_content.bitmapData = _bmdSource;
			_content.smoothing = _contentItem.smoothing;
			handleSizeChanged();
		}
		
		override protected function handleSizeChanged():void
		{
			handleScaleChanged();
			updateBitmap();
		}
		
		override protected function handleScaleChanged():void
		{
			if(_contentItem && _contentItem.scale9Grid==null && !_contentItem.scaleByTile && _bmdSource)
			{
				_displayObject.scaleX = _width/_bmdSource.width*_scaleX;
				_displayObject.scaleY = _height/_bmdSource.height*_scaleY;
			}
			else
			{
				_displayObject.scaleX = _scaleX;
				_displayObject.scaleY = _scaleY;
			}
		}
		
		private function updateBitmap():void
		{
			if(_bmdSource==null)
				return;
			
			var newBmd:BitmapData = _bmdSource;
			var sx:Number = _contentItem.width/sourceWidth;
			var sy:Number = _contentItem.height/sourceHeight;
			var w:int = _width * sx;
			var h:int = _height * sy;
			
			if(w<=0 || h<=0)
				newBmd = null;
			else if(_bmdSource==_contentItem.image
				&& (_bmdSource.width!=w || _bmdSource.height!=h))
			{
				if(_contentItem.scale9Grid!=null)
					newBmd = ToolSet.scaleBitmapWith9Grid(_bmdSource,
						_contentItem.scale9Grid, w, h, _contentItem.smoothing, _contentItem.tileGridIndice);
				else if(_contentItem.scaleByTile)
					newBmd = ToolSet.tileBitmap(_bmdSource, _bmdSource.rect, w, h);
			}
			
			if(newBmd!=null &&　_flip!=FlipType.None)
			{
				var mat:Matrix = new Matrix();
				var a:int=1,b:int=1;
				if(_flip==FlipType.Both)
				{
					mat.scale(-1,-1);
					mat.translate(newBmd.width, newBmd.height);
				}
				else if(_flip==FlipType.Horizontal)
				{
					mat.scale(-1, 1);
					mat.translate(newBmd.width, 0);
				}
				else
				{
					mat.scale(1,-1);
					mat.translate(0, newBmd.height);
				}
				
				var bmdAfterFlip:BitmapData = new BitmapData(newBmd.width,newBmd.height,newBmd.transparent,0);
				bmdAfterFlip.draw(newBmd, mat, null, null, null, _contentItem.smoothing);
				
				if(newBmd!=_bmdSource)
					newBmd.dispose();
				
				newBmd = bmdAfterFlip;
			}
			
			var oldBmd:BitmapData = _content.bitmapData;
			if(oldBmd!=newBmd)
			{
				if(oldBmd && oldBmd!=_bmdSource)
					oldBmd.dispose();
				_content.bitmapData = newBmd;
				_content.smoothing = _contentItem.smoothing;
			}

			_content.width = _width;
			_content.height = _height;
		}
		
		override public function getProp(index:int):*
		{
			if(index==ObjectPropID.Color)
				return this.color;
			else
				return super.getProp(index);
		}

		override public function setProp(index:int, value:*):void
		{
			if(index==ObjectPropID.Color)
				this.color = value;
			else
				super.setProp(index, value);
		}

		override public function setup_beforeAdd(xml:XML):void
		{
			super.setup_beforeAdd(xml);
			
			var str:String;
			str = xml.@color;
			if(str)
				this.color = ToolSet.convertFromHtmlColor(str);
			
			str = xml.@flip;
			if(str)
				this.flip = FlipType.parse(str);
		}
	}
}