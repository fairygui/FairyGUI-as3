/*
 * Copyright 2013 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.google.zxing.common.flexdatatypes
{
	import com.google.zxing.ReaderException;
	
	public class StringBuilder
	{
		public var _string:String = "";
		
		public function StringBuilder(ignore:int=0)
		{
				
		}

		public function charAt(index:int):String
		{
			return this._string.charAt(index);
		}

		
		public function setCharAt(index:int, char:String):void
		{
			var temp:Array = this._string.split("");
			temp[index] = char.charAt(0);
			this._string = temp.join(""); 
		}
		
		public function setLength(l:int):void
		{
			if (l == 0)
			{
				this._string = "";
			}
			else
			{
				this._string = this._string.substr(0,l);
			}
		}

		public function Append(o:Object,startIndex:int=-1,count:int=-1):void
		{
			if (startIndex == -1)
			{
				if (o is Array)
				{
					this._string = this._string + (o as Array).join("");
				}
				else if (o is String)
				{
					this._string = this._string + o;
				}
				else
				{
					this._string = this._string + o.toString();
				}
			}
			else if (count == -1)
			{
				this._string = this._string + (o.toString()).substr(startIndex);
			}
			else
			{
				this._string = this._string + (o.toString()).substr(startIndex,count);
			}
		}
		
		public function ToString():String
		{
			return this._string;
		}
		
		public function get length():int
		{
			return this._string.length;
		}
		
		public function set length(size:int):void
		{
			if (size==0) { this._string = "";}
			else
			{
				throw new ReaderException("size can ony be set to 0");
			}
		}
		public function Insert (pos:int,o:Object):void
		{
			if (pos == 0)
			{
				this._string = o.toString() + this._string;
			}
			else
			{
				throw new ReaderException('pos not supported yet');
			}
		}
		
		public function Remove(startIndex:int,length:int):void
		{
			
			var leftPart:String = "";
			var rightPart:String = "";
			if (startIndex > 0) { leftPart = this._string.substring(0,startIndex); }
			if ((startIndex+length) < this._string.length) 
			{ rightPart = this._string.substr(startIndex+length); }
			this._string = leftPart + rightPart;
		}
		
		public function toString():String
		{
			return this._string;
		}

public function toHexString():String
{
	var r:String="";
    var e:int=this._string.length;
    var c:int=0;
    var h:String;
    while(c<e){
        h=this._string.charCodeAt(c++).toString(16);
        while(h.length<3) h="0"+h;
        r+=h;
    }
    return r;
	
}
		
		public function deleteCharAt(index:int):void
		{
			var temp:Array = this._string.split("");
			var result:String = "";
			for(var i:int=0;i<temp.length;i++)
			{
				if (i!=index){result = result + (temp[i] as String); }
			}
			this._string = result;
		}
	}
}