package fairygui
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import fairygui.display.UIImage;
	import fairygui.utils.ToolSet;

	public class GImage extends GObject implements IColorGear
	{
		private var _gearColor:GearColor;
		
		private var _content:Bitmap;
		private var _bmdAfterFlip:BitmapData;
		private var _color:uint;
		private var _flip:int;
			
		public function GImage()
		{
			_gearColor = new GearColor(this);
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
				if (_gearColor.controller != null)
					_gearColor.updateState();
				
				applyColor();
			}
		}
		
		private function applyColor():void
		{
			var ct:ColorTransform = _content.transform.colorTransform;
			ct.redMultiplier = ((_color>>16)&0xFF)/255;
			ct.greenMultiplier =  ((_color>>8)&0xFF)/255;
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
				applyFlip();
			}
		}
		
		private function applyFlip():void
		{
			var source:BitmapData = _packageItem.image;
			if(source==null)
				return;
			
			if(_flip!=FlipType.None)
			{
				var mat:Matrix = new Matrix();
				var a:int=1,b:int=1;
				if(_flip==FlipType.Both)
				{
					mat.scale(-1,-1);
					mat.translate(source.width, source.height);
				}
				else if(_flip==FlipType.Horizontal)
				{
					mat.scale(-1, 1);
					mat.translate(source.width, 0);
				}
				else
				{
					mat.scale(1,-1);
					mat.translate(0, source.height);
				}
				var tmp:BitmapData = new BitmapData(source.width,source.height,source.transparent,0);
				tmp.draw(source, mat);
				if(_content.bitmapData!=null && _content.bitmapData!=source)
					_content.bitmapData.dispose();
				_bmdAfterFlip = tmp;
			}
			else
			{
				if(_content.bitmapData!=null && _content.bitmapData!=source)
					_content.bitmapData.dispose();
				_bmdAfterFlip = source;
			}
			
			updateBitmap();
		}
		
		override protected function createDisplayObject():void
		{ 
			_content = new UIImage(this);
			setDisplayObject(_content);
		}
		
		final public function get gearColor():GearColor
		{
			return _gearColor;
		}
		
		override public function handleControllerChanged(c:Controller):void
		{
			super.handleControllerChanged(c);
			if(_gearColor.controller==c)
				_gearColor.apply();
		}
		
		override public function dispose():void
		{
			if(!_packageItem.loaded)
				_packageItem.owner.removeItemCallback(_packageItem, __imageLoaded);
			
			if(_content.bitmapData!=null && _content.bitmapData!=_bmdAfterFlip && _content.bitmapData!=_packageItem.image)
			{
				_content.bitmapData.dispose();
				_content.bitmapData = null;
			}
			if(_bmdAfterFlip!=null && _bmdAfterFlip!=_packageItem.image)
			{
				_bmdAfterFlip.dispose();
				_bmdAfterFlip = null;
			}
			
			super.dispose();
		}
		
		override public function constructFromResource(pkgItem:PackageItem):void
		{
			_packageItem = pkgItem;
			
			_sourceWidth = _packageItem.width;
			_sourceHeight = _packageItem.height;
			_initWidth = _sourceWidth;
			_initHeight = _sourceHeight;
			
			setSize(_sourceWidth, _sourceHeight);
			
			if(_packageItem.loaded)
				__imageLoaded(_packageItem);
			else
				_packageItem.owner.addItemCallback(_packageItem, __imageLoaded);
		}

		private function __imageLoaded(pi:PackageItem):void
		{
			_content.bitmapData = pi.image;
			_content.smoothing = _packageItem.smoothing;
			applyFlip();
		}
		
		override protected function handleSizeChanged():void
		{
			super.handleSizeChanged();
			
			if(_packageItem.scale9Grid==null && !_packageItem.scaleByTile)
			{
				_content.scaleX = this.width/_sourceWidth*this.scaleX;
				_content.scaleY = this.height/_sourceHeight*this.scaleY;
			}
			else
			{
				_content.scaleX = this.scaleX;
				_content.scaleY = this.scaleY;
			}
			updateBitmap();
		}
		
		private function updateBitmap():void
		{
			if(_bmdAfterFlip==null)
				return;
			
			var oldBmd:BitmapData = _content.bitmapData;
			var newBmd:BitmapData;
			
			if(_packageItem.scale9Grid!=null)
			{
				var w:Number = this.width;
				var h:Number = this.height;
				
				if(_bmdAfterFlip.width==w && _bmdAfterFlip.height==h)
					newBmd = _bmdAfterFlip;
				else if(w<=0 || h<=0)
					newBmd = null;
				else
				{
					var rect:Rectangle;
					if(_flip!=FlipType.None)
					{
						rect = _packageItem.scale9Grid.clone();
						if(_flip==FlipType.Horizontal || _flip==FlipType.Both)
						{
							rect.x = _bmdAfterFlip.width - rect.right;
							rect.right = rect.x + rect.width;
						}
						
						if(_flip==FlipType.Vertical || _flip==FlipType.Both)
						{
							rect.y = _bmdAfterFlip.height - rect.bottom;
							rect.bottom = rect.y + rect.height;
						}
					}
					else
						rect = _packageItem.scale9Grid;
					
					newBmd = ToolSet.scaleBitmapWith9Grid(_bmdAfterFlip, 
						rect, w, h, _packageItem.smoothing);
				}
			}
			else if(_packageItem.scaleByTile)
			{
				w = this.width;
				h = this.height;
				oldBmd = _content.bitmapData;
				
				if(_bmdAfterFlip.width==w && _bmdAfterFlip.height==h)
					newBmd = _bmdAfterFlip;
				else if(w==0 || h==0)
					newBmd = null;
				else
				{
					newBmd = new BitmapData(w, h, _bmdAfterFlip.transparent, 0);
					var hc:int = Math.ceil(w/_bmdAfterFlip.width);
					var vc:int = Math.ceil(h/_bmdAfterFlip.height);
					var pt:Point = new Point();
					for(var i:int=0;i<hc;i++)
					{
						for(var j:int=0;j<vc;j++)
						{
							pt.x = i*_bmdAfterFlip.width;
							pt.y = j*_bmdAfterFlip.height;
							newBmd.copyPixels(_bmdAfterFlip, _bmdAfterFlip.rect, pt);
						}
					}
				}
			}
			else
			{
				newBmd = _bmdAfterFlip;
			}
			
			if(oldBmd!=newBmd)
			{
				if(oldBmd && oldBmd!=_bmdAfterFlip && oldBmd!=_packageItem.image)
					oldBmd.dispose();
				_content.bitmapData = newBmd;
			}
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
				_flip = FlipType.parse(str);			
		}
		
		override public function setup_afterAdd(xml:XML):void
		{
			super.setup_afterAdd(xml);
			
			var cxml:XML = xml.gearAni[0];
			cxml = xml.gearColor[0];
			if(cxml)
				_gearColor.setup(cxml);
		}
	}
}