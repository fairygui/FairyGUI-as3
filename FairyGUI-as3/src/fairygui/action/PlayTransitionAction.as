package fairygui.action
{
	import fairygui.Controller;
	import fairygui.Transition;

	public class PlayTransitionAction extends ControllerAction
	{
		public var transitionName:String;
		public var repeat:int;
		public var delay:Number;
		public var stopOnExit:Boolean;
		
		private var _currentTransition:Transition;
		
		public function PlayTransitionAction()
		{
			repeat = 1;
			delay = 0;
		}
		
		override protected function enter(controller:Controller):void
		{	
			var trans:Transition = controller.parent.getTransition(transitionName);
			if(trans)
			{
				if(_currentTransition && _currentTransition.playing)
					trans.changeRepeat(repeat);
				else
					trans.play(null, null, repeat, delay);	
				_currentTransition = trans;
			}
		}
		
		override protected function leave(controller:Controller):void
		{
			if(stopOnExit && _currentTransition)
			{
				_currentTransition.stop();
				_currentTransition = null;
			}
		}
		
		override public function setup(xml:XML):void
		{
			super.setup(xml);
			
			transitionName = xml.@transition;
			
			var str:String;
			
			str = xml.@repeat;
			if(str)
				repeat = parseInt(str);
			
			str = xml.@delay;
			if(str)
				delay = parseFloat(str);
			
			str = xml.@stopOnExit;
			stopOnExit = str=="true";
		}
	}
}