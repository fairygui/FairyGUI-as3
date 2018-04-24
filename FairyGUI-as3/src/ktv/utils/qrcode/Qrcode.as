package ktv.utils.qrcode
{
	import com.google.zxing.BarcodeFormat;
	import com.google.zxing.common.BitMatrix;
	import com.google.zxing.qrcode.QRCodeWriter;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Qrcode
	{
		private static var writer:QRCodeWriter;

		private static var borderSize:int;

		private static var size:int;
		
		public function Qrcode()
		{
			
		}
		/**
		 *这个边框的宽度 是在二维码里面的      二维码的宽度+边框的宽度*2  =生成的宽度
		 * @param str
		 * @param size
		 * @param borderSize
		 * @return 
		 * 
		 */		
		public static function creatQrcode(str:String,size:int,borderSize:int=10):BitmapData
		{
			Qrcode.size = size;
			Qrcode.borderSize = borderSize;
			writer = new QRCodeWriter();
			var matrix:BitMatrix;
			try
			{
				matrix = (writer.encode(str,BarcodeFormat.QR_CODE,size,size)) as BitMatrix;
			}catch (e:Error)
			{
				trace("生成二维码失败!");
				return new BitmapData(size,size);
			}
			
			if(!matrix) return new BitmapData(size,size);
			return draw(matrix);
		}
		private static function draw(bytes:BitMatrix):BitmapData 
		{
			var w:int = bytes.width;
			var h:int = bytes.height;
			var bmp:BitmapData = new BitmapData(w,h);
			bmp.lock();
			for (var i:int = 0; i < w; i++) 
			{
				for (var j:int =0; j < h;j++)
				{
					bmp.setPixel(i, j, bytes._get(i,j)?0:0xffffff);
				}
			}
			bmp.unlock();
			var rect:Rectangle=bmp.getColorBoundsRect(0xffffff,0);//获取二维码的区域(不带背景)
			//生成二维码(不带背景)
			var qrCodeBitmapData:BitmapData=new BitmapData(rect.width,rect.height);
			var targetWid:Number=Qrcode.size-Qrcode.borderSize*2;
			var sx:Number=targetWid/rect.width;
			var sy:Number=targetWid/rect.height;
			qrCodeBitmapData.lock();
			qrCodeBitmapData.copyPixels(bmp,rect,new Point());
			qrCodeBitmapData.unlock();
			//生成二维码(带背景)
			var qrCodeAndBgBitmapData:BitmapData=new BitmapData(Qrcode.size,Qrcode.size);
			qrCodeAndBgBitmapData.lock();
			qrCodeAndBgBitmapData.draw(qrCodeBitmapData,new Matrix(sx,0,0,sy,Qrcode.borderSize,Qrcode.borderSize),null,null,null,true);
			qrCodeAndBgBitmapData.unlock();
			bmp.dispose();
			qrCodeBitmapData.dispose();
			return qrCodeAndBgBitmapData;
		}
	}
}