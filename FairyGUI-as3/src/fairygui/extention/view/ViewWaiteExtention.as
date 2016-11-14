package fairygui.extention.view
{
	/**
	 * 
	 * @author once <br/>
	 * version 1.0.0 <br/>
	 * createTime: 2016-9-28下午5:08:55 <br/>
	 **/
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import fairygui.GComponent;
	import fairygui.GComponentExtention;
	import fairygui.GObject;
	
	import once.GameApp;
	
	import tools.storage.DictionaryBase;
	
	public class ViewWaiteExtention extends GComponentExtention
	{
		protected static var _waiteMap:DictionaryBase = new DictionaryBase();
		private var _target:GObject;
		private var _continueTime:int;
		public function ViewWaiteExtention()
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
		protected function TargetSizeChange(target:GObject, viewWaite:GComponent):void
		{
			
		}
		protected function TargetXYChange(target:GObject, viewWaite:GObject):void
		{
			
		}
		protected function Borrow():ViewWaiteExtention
		{
			throw new Error("请在子类重写此函数");
		}
		protected function Return(value:ViewWaiteExtention):void
		{
			throw new Error("请在子类重写此函数");
		}
		//***************
		//private
		//***************
		private function Alpha1(waite:ViewWaiteExtention):void
		{
			waite.alpha = 1;
			if(waite._continueTime > 0) GameApp.timer.doOnce(waite._continueTime, HideFrome, [waite._target]);
		}
		//***************
		//eventHandler
		//***************
		private static function OnTargetSizeChange(target:GObject):void
		{
			var waite:ViewWaiteExtention = _waiteMap[target];
			if(waite!=null)
			{
				waite.setSize(target.width + 2, target.height + 2);
				waite.TargetSizeChange(target, waite);
			}
			else
			{
				target.removeSizeChangeCallback(OnTargetSizeChange);
				target.removeXYChangeCallback(OnTargetXYChange);
			}
		}
		private static function OnTargetXYChange(target:GObject):void
		{
			var waite:ViewWaiteExtention = _waiteMap[target];
			if(waite!=null)
			{
				waite.setXY(target.x- 1, target.y - 1);
				waite.TargetXYChange(target, waite);
			}
			else
			{
				target.removeSizeChangeCallback(OnTargetSizeChange);
				target.removeXYChangeCallback(OnTargetXYChange);
			}
		}
		private function OnTargetRemoved(e:Event):void
		{
			GameApp.timer.clearTimer(Alpha1);
			(e.currentTarget as DisplayObject).removeEventListener(Event.REMOVED_FROM_STAGE, OnTargetRemoved);
			if(_target!=null) GameApp.timer.doLoop(100, HideFrome, [_target]);
		}
		//***************
		//public
		//***************
		final public function ShowOn(target:GObject, showAt:GComponent=null, continueTime:int=300, immediately:Boolean=false):void
		{
			if(_waiteMap[target]==null && target.parent!=null && target.displayObject!=null)
			{
				var waite:ViewWaiteExtention = Borrow();
				waite._continueTime = continueTime;
				waite._target = target;
				showAt = showAt==null ? target.parent : showAt;
				showAt.addChild(waite);
				target.addXYChangeCallback(OnTargetXYChange);
				target.addSizeChangeCallback(OnTargetSizeChange);
				target.displayObject.addEventListener(Event.REMOVED_FROM_STAGE, waite.OnTargetRemoved);
				_waiteMap.Add(target, waite);
				OnTargetSizeChange(target);
				OnTargetXYChange(target);
				if(!immediately)
				{
					waite.alpha = 0;
					GameApp.timer.doOnce(300, waite.Alpha1, [waite]);
				}
				else waite.Alpha1(waite);
			}
		}
		final public function HideFrome(target:GObject):void
		{
			GameApp.timer.clearTimer(HideFrome);
			target.removeXYChangeCallback(OnTargetSizeChange);
			target.removeXYChangeCallback(OnTargetXYChange);
			var waite:ViewWaiteExtention = _waiteMap.Del(target);
			if(waite!=null)
			{
				GameApp.timer.clearTimer(waite.Alpha1);
				waite._target = null;
				waite.removeFromParent();
				Return(waite);
			}
		}
	}
}