package fairygui.text
{
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class BitmapFont
	{
		public var id:String;
		public var lineHeight:int;
		public var ttf:Boolean;
		public var atlas:BitmapData;
		
		private var _dict:Object;
		
		public function BitmapFont()
		{
			_dict = {};
		}
		
		public function addChar(ch:String, glyph:BMGlyph):void
		{
			_dict[ch] = glyph;
		}
		
		public function getGlyph(ch:String):BMGlyph
		{
			return _dict[ch];
		}
		
		public function dispose():void
		{
			if(atlas!=null)
				atlas.dispose();
		}
		
		private static var sHelperPoint:Point = new Point();
		private static var sHelperRect:Rectangle = new Rectangle();
		private static var sTransform:ColorTransform = new ColorTransform(0,0,0,1);
		private static var sHelperMat:Matrix = new Matrix();
		private static var sHelperBmd:BitmapData = new BitmapData(200,200,true,0);
		
		public function draw(target:BitmapData, glyph:BMGlyph, charPos:Point, color:uint):void
		{
			charPos.x += glyph.offsetX;
			
			if(ttf)
			{
				if(atlas!=null)
				{
					if(glyph.channel==15)
					{
						sHelperBmd.fillRect(sHelperBmd.rect, 0);
						
						sHelperRect.x = glyph.x;
						sHelperRect.y = glyph.y;
						sHelperRect.width = glyph.width;
						sHelperRect.height = glyph.height;
						sHelperBmd.copyPixels(atlas, sHelperRect, sHelperPoint);
						
						sTransform.blueOffset = color & 0x0000FF;
						sTransform.greenOffset = color & 0x00FF00;
						sTransform.redOffset = color & 0xFF0000;
						sHelperRect.x = 0;
						sHelperRect.y = 0;
						sHelperBmd.colorTransform(sHelperRect, sTransform);
						
						sHelperMat.identity();
						sHelperMat.translate(charPos.x, charPos.y);
						sHelperRect.x = charPos.x;
						sHelperRect.y = charPos.y;
						sHelperRect.width = glyph.width;
						sHelperRect.height = glyph.height;
						target.draw(sHelperBmd, sHelperMat, null, null, sHelperRect, true);
					}
					else
					{
						sHelperBmd.fillRect(sHelperBmd.rect, 0);
						
						sHelperRect.x = 0;
						sHelperRect.y = 0;
						sHelperRect.width = glyph.width;
						sHelperRect.height = glyph.height;
						sHelperBmd.fillRect(sHelperRect, 0xFF000000 + color);
						
						sHelperRect.x = glyph.x;
						sHelperRect.y = glyph.y;
						sHelperBmd.copyChannel(atlas, sHelperRect, sHelperPoint, glyph.channel, BitmapDataChannel.ALPHA);
						
						sHelperMat.identity();
						sHelperMat.translate(charPos.x, charPos.y);
						sHelperRect.x = charPos.x;
						sHelperRect.y = charPos.y;
						sHelperRect.width = glyph.width;
						sHelperRect.height = glyph.height;
						target.draw(sHelperBmd, sHelperMat, null, null, sHelperRect, true);
					}
				}
			}
			else if(glyph.imageItem!=null)
			{
				var bmd:BitmapData = glyph.imageItem.image;
				if(bmd!=null)
				{
					sHelperMat.identity();
					sHelperMat.translate(charPos.x, charPos.y);
					target.draw(bmd, sHelperMat, null, null, null, true);
				}
			}
		}
	}
}


