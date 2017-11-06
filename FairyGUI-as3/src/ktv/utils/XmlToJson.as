package ktv.utils
{
	
	public class XmlToJson
	{
		
		private static var _arrays:Array;
		
		public static function parse(node:XML):Object 
		{
			var obj:Object = {};
			var numOfChilds:int = node.children().length();
			for(var i:int = 0; i<numOfChilds; i++) 
			{
				var childNode:* = node.children()[i];
				var childNodeName:String = childNode.name();
				var value:*;
				if(childNode.children().length() == 1 && childNode.children()[0].name() == null)
				{
					if(childNode.attributes().length() > 0) 
					{
						value = 
							{
								_content: childNode.children()[0].toString()
							};
						var numOfAttributes:int = childNode.attributes().length();
						for(var j:int=0; j<numOfAttributes; j++) 
						{
							value[childNode.attributes()[j].name().toString()] = childNode.attributes()[j];
						}
					}
					else 
					{
						value = childNode.children()[0].toString();
					}
				} 
				else
				{
					value = parse(childNode);
				}
				if(obj[childNodeName])
				{
					if(getTypeof(obj[childNodeName]) == "array") 
					{
						obj[childNodeName].push(value);
					} 
					else 
					{
						obj[childNodeName] = [obj[childNodeName], value];
					}
				}
				else if(isArray(childNodeName))
				{
					obj[childNodeName] = [value];
				} 
				else 
				{
					obj[childNodeName] = value;
				}
			}
			numOfAttributes = node.attributes().length();			
			for(i=0; i<numOfAttributes; i++)
			{
				obj[node.attributes()[i].name().toString()] = node.attributes()[i];
			}
			if(numOfChilds == 0)
			{
				if(numOfAttributes == 0)
				{
					obj = "";
				} 
				else
				{
					obj._content = "";
				}
			}
			return obj;
		}
		
		public static function get arrays():Array
		{
			if(!_arrays) 
			{
				_arrays = [];
			}
			return _arrays;
		}
		
		public static function set arrays(a:Array):void
		{
			_arrays = a;
		}
		
		private static function isArray(nodeName:String):Boolean 
		{
			var numOfArrays:int = _arrays ? _arrays.length : 0;
			for(var i:int=0; i<numOfArrays; i++) 
			{
				if(nodeName == _arrays[i]) 
				{
					return true;
				}
			}
			return false;
		}
		
		private static function getTypeof(o:*):String 
		{
			if(typeof(o) == "object")
			{
				if(o.length == null) 
				{
					return "object";
				} 
				else if(typeof(o.length) == "number")
				{
					return "array";
				} 
				else 
				{
					return "object";
				}
			} 
			else 
			{
				return typeof(o);
			}
		}
		
	}
	
}