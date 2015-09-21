package fairygui.utils 
{
	public class SimpleDispatcher 
	{
		private var _elements:Array;
		private var _enumI:int;
		private var _dispatchingType:int;
		
		public function SimpleDispatcher():void {
			_elements = [];
			_dispatchingType = -1;
		}
		
		public function addListener(type:int, e:Function):void {
			var arr:Array = _elements[type];
			if(!arr) {
				arr = [];
				_elements[type] = arr;
				arr.push(e);
			}
			else if(arr.indexOf(e)==-1) {
				arr.push(e);
			}
		}
		
		public function removeListener(type:int, e:Function):void {
			var arr:Array = _elements[type];
			if(arr) {
				var i:int = arr.indexOf(e);
				if(i!=-1) {
					arr.splice(i,1);
					if(type==_dispatchingType && i<=_enumI)
						_enumI--;
				}
			}
		}
		
		public function hasListener(type:int):Boolean {
			var arr:Array = _elements[type];
			if(arr && arr.length>0)
				return true;
			else
				return false;
		}
		
		public function dispatch(source:Object, type:int):void {
			var arr:Array = _elements[type];
			if(!arr || arr.length==0 || _dispatchingType==type)
				return;
			
			_enumI = 0;
			_dispatchingType = type;
			while(_enumI<arr.length) {
				var e:Function = arr[_enumI];
				if(e.length==1)
					e(source);
				else
					e();
				_enumI++;
			}
			_dispatchingType = -1;
		}
		
		public function clear():void {
			_elements.length = 0;
		}
		
		public function copy(source:SimpleDispatcher):void {
			_elements = source._elements.concat();
		}
		
	}
}