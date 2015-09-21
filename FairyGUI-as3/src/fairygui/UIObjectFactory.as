package fairygui
{
	public class UIObjectFactory
	{
		internal static var packageItemExtensions:Object = {};
		private static var loaderExtension:Class;
		
		public function UIObjectFactory()
		{
		}
		
		public static function setPackageItemExtension(url:String, type:Class):void
		{
			packageItemExtensions[url.substring(5)] = type;
		}
		
		public static function setLoaderExtension(type:Class):void
		{
			loaderExtension = type;
		}
		
		public static function newObject(pi:PackageItem):GObject
		{
			switch (pi.type)
			{
				case PackageItemType.Image:
					return new GImage();
				
				case PackageItemType.MovieClip:
					return new GMovieClip();
				
				case PackageItemType.Swf:
					return new GSwfObject();
				
				case PackageItemType.Component:
					{
						var cls:Class = packageItemExtensions[pi.owner.id + pi.id];
						if (cls)
							return new cls();
						
						var xml:XML = pi.owner.getComponentData(pi);
						var extention:String = xml.@extention;
						if (extention != null)
						{
							switch (extention)
							{
								case "Button":
									return new GButton();

								case "Label":
									return new GLabel();
								
								case "ProgressBar":
									return new GProgressBar();
								
								case "Slider":
									return new GSlider();
								
								case "ScrollBar":
									return new GScrollBar();

								case "ComboBox":
									return new GComboBox();
									
								default:
									return new GComponent();
							}
						}
						else
							return new GComponent();
					}
			}
			return null;
		}
		
		public static function newObject2(type:String):GObject
		{
			switch (type)
			{
				case "image":
					return new GImage();
					
				case "movieclip":
					return new GMovieClip();
					
				case "swf":
					return new GSwfObject();
					
				case "component":
					return new GComponent();
					
				case "text":
					return new GTextField();
					
				case "richtext":
					return new GRichTextField();
					
				case "group":
					return new GGroup();
					
				case "list":
					return new GList();
					
				case "graph":
					return new GGraph();
					
				case "loader":
					if (loaderExtension != null)
						return new loaderExtension();
					else
						return new GLoader();
			}
			return null;
		}
	}
}