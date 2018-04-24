/**
 * This class lets you decode animated GIF files, and show animated GIF's in the Flash player
 * Base Class : http://www.java2s.com/Code/Java/2D-Graphics-GUI/GiffileEncoder.htm
 * @author Kevin Weiner (original Java version - kweiner@fmsware.com)
 * @author Thibault Imbert (AS3 version - bytearray.org)
 * @version 0.1 AS3 implementation
 */

package ktv.gifv
{
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;


	public class GIFDecoder extends EventDispatcher
	{
		/**
		 * File read status: No errors.
		 */
		public static const STATUS_OK:int=0;

		/**
		 * File read status: Error decoding file (may be partially decoded)
		 */
		private static const STATUS_FORMAT_ERROR:int=1;

		/**
		 * File read status: Unable to open source.
		 */
		private static const STATUS_OPEN_ERROR:int=2;

		private var inStream:ByteArray=null;
		private var status:int=0;

		// full image width
		private var width:int=0;
		// full image height
		private var height:int=0;
		// global color table used
		private var gctFlag:Boolean=false;
		// size of global color table
		private var gctSize:int=0;
		// iterations; 0 = repeat forever
		private var loopCount:int=1;

		// global color table
		private var gct:Array=null;
		// local color table
		private var lct:Array=null;
		// active color table
		private var act:Array=null;

		// background color index
		private var bgIndex:int=0;
		// background color
		private var bgColor:uint=0;
		// previous bg color
		private var lastBgColor:uint=0;
		// pixel aspect ratio
		private var pixelAspect:int=0;

		private var lctFlag:Boolean=false // local color table flag
		// interlace flag
		private var interlace:Boolean=false;
		// local color table size
		private var lctSize:int;

		private var ix:int=0;
		private var iy:int=0;
		private var iw:int=0;
		// current image rectangle
		private var ih:int=0;
		// last image rect
		private const lastRect:Rectangle=new Rectangle();
		// current frame
		private var image:BitmapData=null;
		private var bitmap:BitmapData=null;
		// previous frame
		private var lastImage:BitmapData=null;
		// current data block
		private var block:ByteArray=null;
		// block size
		private var blockSize:int=0;

		// last graphic control extension info
		private var dispose:int=0;
		// 0=no action; 1=leave in place; 2=restore to bg; 3=restore to prev
		private var lastDispose:int=0;
		// use transparent color
		private var transparency:Boolean=false;
		// delay in milliseconds
		private var delay:int=0;
		// transparent color index
		private var transIndex:int=0;

		// max decoder pixel stack size
		private static const MaxStackSize:int=4096;

		// LZW decoder working arrays
		private var prefix:Vector.<int>=null
		private var suffix:ByteArray=null;
		private var pixelStack:ByteArray=null;
		private var pixels:ByteArray=null;

		// frames read from current file
		private var delays:Array=null
		private var frames:Array=null
		private var frameCount:int=0;

		public var firstFunc:Function=null;

		public function GIFDecoder()
		{
			block=new ByteArray;
		}

		public function get disposeValue():int
		{
			return dispose;
		}

		/**
		 * Gets display duration for specified frame.
		 *
		 * @param n int index of frame
		 * @return delay in milliseconds
		 */
		public function getDelay(n:int):int
		{
			delay=-1;
			if ((n >= 0) && (n < frameCount))
			{
				delay=delays[n];
			}
			return delay;
		}

		/**
		 * Gets the number of frames read from file.
		 * @return frame count
		 */
		public function getFrameCount():int
		{
			return frameCount;
		}

		/**
		 * Gets the first (or only) image read.
		 *
		 * @return BitmapData containing first frame, or null if none.
		 */
		public function getImage():BitmapData
		{
			return getFrame(0);
		}

		/**
		 * Gets the "Netscape" iteration count, if any.
		 * A count of 0 means repeat indefinitiely.
		 *
		 * @return iteration count if one was specified, else 1.
		 */
		public function getLoopCount():int
		{
			return loopCount;
		}

		public function getW():int
		{
			return width;
		}

		public function getH():int
		{
			return height;
		}

		public function disposeObject():void
		{
			if (prefix)
			{
				prefix.fixed=false;
				prefix.length=0;
				prefix=null;
			}
			if (suffix)
			{
				suffix.length=0;
				suffix=null;
			}
			if (pixelStack)
			{
				pixelStack.length=0;
				pixelStack=null;
			}
			if (pixels)
			{
				pixels.length=0;
				pixels=null;
			}
			if (lastPixs)
			{
				lastPixs.fixed=false;
				lastPixs.length=0;
				lastPixs=null;
			}
			if (inStream)
			{
				inStream.length=0;
				inStream=null;
			}
			if (block)
			{
				block.length=0;
				block=null;
			}
			if (delays)
			{
				delays.length=0;
				delays=null;
			}
			if (gct)
			{
				gct.length=0;
				gct=null;
			}
			if (lct)
			{
				lct.length=0;
				lct=null;
			}
			if (act)
			{
				act.length=0;
				act=null;
			}

			firstFunc=null;
		}


		public function disposeFrames():void
		{
			if (frames)
			{
				for each (var b:BitmapData in frames)
				{
					b.dispose();
				}
				frames.length=0;
				frames=null;
			}
		}

		/**
		 * Creates new frame image from current data (and previous
		 * frames as specified by their disposition codes).
		 */

		private var lastPixs:Vector.<uint>=new Vector.<uint>();
		private var lastPlen:uint=0;

		private function transferPixels():void
		{
			image.lock();
			var dest:Vector.<uint>=null;
			// fill in starting image contents based on last image's dispose code
			if (lastDispose > 0)
			{
				if (lastDispose == 3)
				{
					// use image before last
					var n:int=frameCount - 2;
					lastImage=n > 0 ? getFrame(n - 1) : null;

				}

				if (lastImage != null)
				{
					if (lastDispose == 2)
					{
						// fill last image rect area with background color
						var c:uint=transparency ? 0x00000000 : lastBgColor;

						dest=lastImage.getVector(lastImage.rect);
						dest.fixed=true;
						lastPixs.fixed=true;

						// use given background color
						for (var j:uint=0; j < lastPlen; j++)
						{
							var p:uint=lastPixs[j];
							dest[p]=c;
						}

						lastPixs.fixed=false;

					}
					else
					{
						dest=lastImage.getVector(lastImage.rect);
					}
				}
			}

			if (!dest)
			{
				dest=image.getVector(image.rect);
			}

			dest.fixed=true;
			lastPlen=0;
			// copy each source line to the appropriate place in the destination
			var pass:int=1;
			var inc:int=8;
			var iline:int=0;
			for (var i:int=0; i < ih; i++)
			{
				var line:int=i;
				if (interlace)
				{
					if (iline >= ih)
					{
						pass++;
						switch (pass)
						{
							case 2:
								iline=4;
								break;
							case 3:
								iline=2;
								inc=4;
								break;
							case 4:
								iline=1;
								inc=2;
								break;
						}
					}
					line=iline;
					iline+=inc;
				}
				line+=iy;
				if (line < height)
				{
					const k:int=line * width;
					var dx:int=k + ix; // start of line in dest
					var dlim:int=dx + iw; // end of dest line
					if ((k + width) < dlim)
					{
						dlim=k + width; // past dest edge
					}
					var sx:int=i * iw; // start of line in source
					var tmp:int=0;
					while (dx < dlim)
					{
						// map color and insert in destination
						tmp=act[(pixels[sx++]) & 0xff];
						if (tmp != 0)
						{
							dest[dx]=tmp;
							lastPixs[lastPlen++]=dx;
						}
						dx++;
					}
				}
			}

			image.setVector(image.rect, dest);
			image.unlock();

			dest.fixed=false;
			dest.length=0;
			dest=null;
		}

		/**
		 * Gets the image contents of frame n.
		 *
		 * @return BufferedImage representation of frame, or null if n is invalid.
		 */
		public function getFrame(n:int):BitmapData
		{
			var im:BitmapData=null;

			if ((n >= 0) && (n < frameCount))

			{
				im=frames[n];

			}
			else
				throw new RangeError("Wrong frame number passed");

			return im;
		}


		/**
		 * Reads GIF image from stream
		 *
		 * @param BufferedInputStream containing GIF file.
		 * @return read status code (0 = no errors)
		 */
		public function read(inStream:ByteArray):int
		{
			init();
			done=false;
			this.inStream=inStream;
			readHeader();
			return status;
		}

		// read GIF file content blocks
		private var done:Boolean=false;

		public function readFrame():Boolean
		{
			var t:Number=getTimer();
			while (!done)
			{
				readContents();
				if (getTimer() - t > 200)
				{
					break;
				}

				if (done || hasError())
				{
					done=true;
					break;
				}
			}

			return done;
		}

		public function end():int
		{
			if (!hasError())
			{
				if (frameCount < 0)
				{
					status=STATUS_FORMAT_ERROR;
				}
			}

			return status;
		}

		/**
		 * Main file parser.  Reads GIF content blocks.
		 */
		private function readContents():void
		{
			var code:int=readSingleByte();
			switch (code)
			{
				case 0x2C: // image separator
					readImage();
					break;

				case 0x21: // extension
					code=readSingleByte();
					switch (code)
				{
					case 0xf9: // graphics control extension
						readGraphicControlExt();
						break;

					case 0xff: // application extension
						readBlock();
						var app:String="";
						for (var i:int=0; i < 11; i++)
						{
							app+=String.fromCharCode(block[int(i)]);
						}
						if (app == "NETSCAPE2.0")
						{
							readNetscapeExt();
						}
						else
							skip(); // don't care
						break;

					default: // uninteresting extension
						skip();
						break;
				}
					break;

				case 0x3b: // terminator
					done=true;
					break;

				case 0x00: // bad byte, but keep going and see what happens
					break;

				default:
					status=STATUS_FORMAT_ERROR;
					break;
			}
		}

		/**
		 * Decodes LZW image data into pixel array.
		 * Adapted from John Cristy's ImageMagick.
		 */
		private function decodeImageData():void
		{
			const NullCode:int=-1;
			const npix:int=iw * ih;
			var available:int=0;
			var clear:int=0;
			var code_mask:int=0;
			var code_size:int=0;
			var end_of_information:int=0;
			var in_code:int=0;
			var old_code:int=0;
			var bits:int=0;
			var code:int=0;
			var count:int=0;
			var i:int=0;
			var datum:int=0;
			var data_size:int=0;
			var first:int=0;
			var top:int=0;
			var bi:int=0;
			var pi:int=0;

			if (pixels == null)
			{
				pixels=new ByteArray(); //(npix); // allocate new pixel array
			}
			if (pixels.length < npix)
			{
				pixels.length=npix;
			}

			if (prefix == null)
				prefix=new Vector.<int>(MaxStackSize, true); // (MaxStackSize);

			if (suffix == null)
				suffix=new ByteArray(); // (MaxStackSize);

			if (pixelStack == null)
				pixelStack=new ByteArray(); // (MaxStackSize + 1);

			//  Initialize GIF data stream decoder.

			data_size=readSingleByte();
			clear=1 << data_size;
			end_of_information=clear + 1;
			available=clear + 2;
			old_code=NullCode;
			code_size=data_size + 1;
			code_mask=(1 << code_size) - 1;
			for (code=0; code < clear; code++)
			{
				prefix[code]=0;
				suffix[code]=code;
			}

			//  Decode GIF pixel stream.
			datum=bits=count=first=top=pi=bi=0;

			for (i=0; i < npix; )
			{
				if (top == 0)
				{
					if (bits < code_size)
					{
						//  Load bytes until there are enough bits for a code.
						if (count == 0)
						{
							// Read a new data block.
							count=readBlock();
							if (count <= 0)
								break;
							bi=0;
						}
						datum+=(block[bi] & 0xff) << bits;
						bits+=8;
						bi++;
						count--;
						continue;
					}

					//  Get the next code.
					code=datum & code_mask;
					datum>>=code_size;
					bits-=code_size;
					//  Interpret the code
					if ((code > available) || (code == end_of_information))
						break;
					if (code == clear)
					{
						//  Reset decoder.
						code_size=data_size + 1;
						code_mask=(1 << code_size) - 1;
						available=clear + 2;
						old_code=NullCode;
						continue;
					}
					if (old_code == NullCode)
					{
						pixelStack[top++]=suffix[code];
						old_code=code;
						first=code;
						continue;
					}
					in_code=code;
					if (code == available)
					{
						pixelStack[top++]=first;
						code=old_code;
					}
					while (code > clear)
					{
						pixelStack[top++]=suffix[code];
						code=prefix[code];
					}
					first=(suffix[code]) & 0xff;

					//  Add a new string to the string table,

					if (available >= MaxStackSize)
						break;
					pixelStack[top++]=first;
					prefix[available]=old_code;
					suffix[available]=first;
					available++;
					if (((available & code_mask) == 0) && (available < MaxStackSize))
					{
						code_size++;
						code_mask+=available;
					}
					old_code=in_code;
				}

				//  Pop a pixel off the pixel stack.

				top--;
				pixels[pi++]=pixelStack[top];
				i++;
			}

			for (i=pi; i < npix; i++)
			{
				pixels[i]=0; // clear missing pixels
			}
		}

		/**
		 * Returns true if an error was encountered during reading/decoding
		 */
		private function hasError():Boolean
		{
			return status != STATUS_OK;
		}

		/**
		 * Initializes or re-initializes reader
		 */
		private function init():void
		{
			status=STATUS_OK;
			frameCount=0;
			frames=[];
			delays=[];
			gct=null;
			lct=null;
		}

		/**
		 * Reads a single byte from the input stream.
		 */
		private function readSingleByte():int
		{
			return inStream.readUnsignedByte();
		}

		/**
		 * Reads next variable length block from input.
		 *
		 * @return number of bytes stored in "buffer"
		 */
		private function readBlock():int
		{
			blockSize=readSingleByte();
			var n:int=0;
			if (blockSize > 0)
			{
				try
				{
					var count:int=0;
					while (n < blockSize)
					{

						inStream.readBytes(block, n, blockSize - n);
						if ((blockSize - n) == -1)
							break;
						n+=(blockSize - n);
					}
				}
				catch (e:Error)
				{
				}

				if (n < blockSize)
				{
					status=STATUS_FORMAT_ERROR;
				}
			}
			return n;
		}

		/**
		 * Reads color table as 256 RGB integer values
		 *
		 * @param ncolors int number of colors to read
		 * @return int array containing 256 colors (packed ARGB with full alpha)
		 */
		private function readColorTable(ncolors:int):Array
		{
			const nbytes:int=3 * ncolors;
			var tab:Array=null;
			var c:ByteArray=new ByteArray();
			var n:int=0;
			try
			{
				inStream.readBytes(c, 0, nbytes);
				n=nbytes;
			}
			catch (e:Error)
			{
			}
			if (n < nbytes)
			{
				status=STATUS_FORMAT_ERROR;
			}
			else
			{
				tab=[]; //size =256
				var i:int=0;
				var j:int=0;
				while (i < ncolors)
				{
					var r:int=(c[j++]) & 0xff;
					var g:int=(c[j++]) & 0xff;
					var b:int=(c[j++]) & 0xff;
					tab[i++]=(0xff000000 | (r << 16) | (g << 8) | b);
				}
			}
			return tab;
		}



		/**
		 * Reads Graphics Control Extension values
		 */
		private function readGraphicControlExt():void
		{
			readSingleByte(); // block size
			const packed:int=readSingleByte(); // packed fields
			dispose=(packed & 0x1c) >> 2; // disposal method
			if (dispose == 0)
			{
				dispose=1; // elect to keep old image if discretionary
			}
			transparency=(packed & 1) != 0;
			delay=readShort() * 10; // delay in milliseconds
			transIndex=readSingleByte(); // transparent color index
			readSingleByte(); // block terminator
		}

		/**
		 * Reads GIF file header information.
		 */
		private function readHeader():void
		{
			var id:String="";
			for (var i:int=0; i < 6; i++)
			{
				id+=String.fromCharCode(readSingleByte());

			}
			if (!(id.indexOf("GIF") == 0))
			{
				status=STATUS_FORMAT_ERROR;
//				throw new FileTypeError("Invalid file type");
				throw new Error();
				return;
			}
			readLSD();
			if (gctFlag && !hasError())
			{
				gct=readColorTable(gctSize);
				bgColor=gct[bgIndex];
			}
		}

		/**
		 * Reads next frame image
		 */
		private function readImage():void
		{
			ix=readShort(); // (sub)image position & size
			iy=readShort();
			iw=readShort();
			ih=readShort();

			var packed:int=readSingleByte();
			lctFlag=(packed & 0x80) != 0; // 1 - local color table flag
			interlace=(packed & 0x40) != 0; // 2 - interlace flag
			// 3 - sort flag
			// 4-5 - reserved
			lctSize=2 << (packed & 7); // 6-8 - local color table size

			if (lctFlag)
			{
				lct=readColorTable(lctSize); // read table
				act=lct; // make local table active
			}
			else
			{
				act=gct; // make global table active
				if (bgIndex == transIndex)
					bgColor=0;
			}
			var save:int=0;
			if (transparency)
			{
				save=act[transIndex];
				act[transIndex]=0; // set transparent color if specified
			}

			if (act == null)
			{
				status=STATUS_FORMAT_ERROR; // no color table defined
			}

			if (hasError())
				return;

			decodeImageData(); // decode pixel data
			skip();
			if (hasError())
				return;

			frameCount++;
			// create new image to receive frame data

			bitmap=new BitmapData(width, height, true, 0);

			image=bitmap;
			transferPixels(); // transfer pixel data to image
			frames.push(bitmap); // add image to frame list
			delays.push(delay);

			if (transparency)
				act[transIndex]=save;

			resetFrame();

			if (frameCount == 1 && firstFunc != null)
			{
				firstFunc();
			}
		}

		/**
		 * Reads Logical Screen Descriptor
		 */
		private function readLSD():void
		{

			// logical screen size
			width=readShort();
			height=readShort();

			// packed fields
			var packed:int=readSingleByte();

			gctFlag=(packed & 0x80) != 0; // 1   : global color table flag
			// 2-4 : color resolution
			// 5   : gct sort flag
			gctSize=2 << (packed & 7); // 6-8 : gct size
			bgIndex=readSingleByte(); // background color index
			pixelAspect=readSingleByte(); // pixel aspect ratio

		}

		/**
		 * Reads Netscape extenstion to obtain iteration count
		 */
		private function readNetscapeExt():void
		{
			do
			{
				readBlock();
				if (block[0] == 1)
				{
					// loop count sub-block
					var b1:int=(block[1]) & 0xff;
					var b2:int=(block[2]) & 0xff;
					loopCount=(b2 << 8) | b1;
				}
			} while ((blockSize > 0) && !hasError());
		}

		/**
		 * Reads next 16-bit value, LSB first
		 */
		private function readShort():int
		{
			// read 16-bit value, LSB first
			return readSingleByte() | (readSingleByte() << 8);
		}

		/**
		 * Resets frame state for reading next image.
		 */
		private function resetFrame():void
		{
			lastDispose=dispose;
			lastRect.setTo(ix, iy, iw, ih);
			lastImage=image;
			lastBgColor=bgColor;
			// int dispose = 0;
			//var transparency:Boolean = false;
			//var delay:int = 0;
			lct=null;
		}

		/**
		 * Skips variable length blocks up to and including
		 * next zero length block.
		 */
		private function skip():void
		{
			do
			{
				readBlock();

			} while ((blockSize > 0) && !hasError());
		}
	}

}
