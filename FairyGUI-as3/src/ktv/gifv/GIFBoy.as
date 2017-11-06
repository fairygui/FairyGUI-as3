
package ktv.gifv
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.events.Event;

	public class GIFBoy extends Bitmap
	{

		public var updateFunc:Function=null;
		public var firstFunc:Function=null;

		//timer
		private const myTimer:Timer=new Timer(1000 / 10, 0);

		private var index:int=0;
		private var totle:uint=0;
		private var f_width:int=0;
		private var f_height:int=0;
		private var inited:Boolean=false;

		//datas
		private var gifDecoder:GIFDecoder=new GIFDecoder();
		private var aFrames:Array=[];
		private var aDelays:Array=[];

		public function GIFBoy()
		{
			this.addEventListener(Event.REMOVED_FROM_STAGE, removeStage);
		}

		private function removeStage(e:Event):void
		{
			this.removeEventListener(Event.REMOVED_FROM_STAGE, removeStage);
			dispose();
		}

		/**
		 * read data
		 */
		public function loadBytes(gBytes:ByteArray):void
		{
			if (!aFrames)
			{
				aFrames=[];
				aDelays=[];
				gifDecoder=new GIFDecoder();
			}
			try
			{
				gifDecoder.firstFunc=firstView;
				var st:int=gifDecoder.read(gBytes);

				if (st != GIFDecoder.STATUS_OK)
				{
					fail();
				}
				else
				{
					myTimer.start();
					if (!myTimer.hasEventListener(TimerEvent.TIMER))
					{
						myTimer.addEventListener(TimerEvent.TIMER, update);
					}
				}

			}
			catch (e:Error)
			{
				fail();
			}
		}

		/**
		 * info
		 */
		public function getFrameWidth():int
		{
			return f_width;
		}

		public function getFrameHeight():int
		{
			return f_height;
		}

		public function getCurrent():int
		{
			return index;
		}

		public function getFrames():int
		{
			return totle;
		}

		public function isInited():Boolean
		{
			return inited;
		}

		public function getFrame(i:int):BitmapData
		{
			return aFrames[i];
		}

		public function dispose():void
		{
			this.bitmapData=null;
			myTimer.stop();
			aFrames=null;
			aDelays=null;
			index=0;
			totle=0;
			f_width=0;
			f_height=0;
			inited=false;

			gifDecoder.disposeObject();
			gifDecoder.disposeFrames();
			gifDecoder.firstFunc=null;
			gifDecoder=null;

			if (myTimer.hasEventListener(TimerEvent.TIMER))
			{
				myTimer.removeEventListener(TimerEvent.TIMER, update);
			}
		}

		private function firstView():void
		{
			this.bitmapData=gifDecoder.getImage();
			this.f_width=gifDecoder.getW();
			this.f_height=gifDecoder.getH();

			if (firstFunc != null)
			{
				firstFunc();
			}

			if (updateFunc != null)
			{
				updateFunc();
			}
		}

		private function update(pEvt:TimerEvent):void
		{
			if (!aFrames)
			{
				return;
			}

			if (!inited)
			{
				try
				{
					inited=gifDecoder.readFrame();
					totle=gifDecoder.getFrameCount();
				}
				catch (e:Error)
				{
					fail();
				}
				if (inited)
				{
					var st:int=gifDecoder.end();
					if (st != GIFDecoder.STATUS_OK)
					{
						fail();
					}
					else
					{
						for (var i:int=0; i < totle; i++)
						{
							aFrames[i]=gifDecoder.getFrame(i);
							var tdlay:int=gifDecoder.getDelay(i);
							if (tdlay < 17)
							{
								tdlay=17;
							}
							aDelays[i]=tdlay;
						}
						dispatchEvent(new GIFEvent(GIFEvent.OK));
					}

					index=0;
					gifDecoder.disposeObject();
				}
			}
			else
			{
				var delay:int=aDelays[index];
				if (myTimer.delay != delay)
				{
					myTimer.delay=delay;
				}

				renderFrame(index);

				if (updateFunc != null)
				{
					updateFunc();
				}

				index=(index + 1) % totle;
			}
		}

		private function fail():void
		{
			if (gifDecoder)
			{
				dispose();
			}
			dispatchEvent(new GIFEvent(GIFEvent.FAIL));
		}

		private function renderFrame(index:int):void
		{
			var b:BitmapData=aFrames[index];
			if (b && this.bitmapData != b)
			{
				this.bitmapData=b;
				this.smoothing=true;
			}
		}
	}
}
