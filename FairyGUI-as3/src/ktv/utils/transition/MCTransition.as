package ktv.utils.transition
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	
	import fl.transitions.Blinds;
	import fl.transitions.Fade;
	import fl.transitions.Iris;
	import fl.transitions.PixelDissolve;
	import fl.transitions.Transition;
	import fl.transitions.TransitionManager;
	import fl.transitions.Wipe;
	import fl.transitions.easing.None;
	import fl.transitions.easing.Strong;
	


	/** 
	 * 作用：图片过渡工具类
	 * 
	 */
	public class MCTransition
	{
		/**
		 * 图片轮播效果
		 * @param mc
		 * @param type
		 */
		public static  function transEffect(mc:DisplayObject,modes:int=NaN):void
		{			
			if(!modes){
				modes = int(Math.random() * 5 + 1);
			}
			switch (modes)
			{
				case 1:
					TweenLite.from(mc,0.6,{alpha:0});
					break;
				case 2: 
					TweenLite.from(mc,0.6,{scaleX:0});
					break;
				case 3: 
					TweenLite.from(mc,0.6,{x:mc.width,scaleX:0});
					break;
				case 4: 
					TweenLite.from(mc,0.6,{scaleY:0});
					break;
				case 5: 
					TweenLite.from(mc,0.6,{y:mc.height,scaleY:0});
					break;
			}
		}
		
		
		/**
		 * //幻灯片的10种方法 
		 * @param mc 	
		 * @param type  动画播放效果类型   1-8   =-1(随机效果)
		 * @param duration 动画持续的时间
		 * @param fun 动画结束回调
		 * 
		 */
		public static  function transEffect1(mc:MovieClip,type:int=-1,duration:Number=1,fun:Function=null):void
		{			
			var transition:Transition;
			var num:int = int(Math.random() * 8 + 1);
			if(type!=-1)
			{
				num=type;
			}
			//用switch的方法随机执行以下8中切换图片的方法，里面的内容全部都是切换图片的方法，可以自己查TransitionManager的帮助方法
			switch (num)
			{
				case 1://百叶窗
					transition=TransitionManager.start(mc, {type: Blinds, direction: Transition.IN, duration:duration, easing: None.easeNone, numStrips: 10, dimension: 0});
					break;
				case 2: //百叶窗
					transition=TransitionManager.start(mc, {type: Blinds, direction: Transition.IN, duration: duration, easing: None.easeNone, numStrips: 10, dimension: 1});
					break;
				case 3: //淡入淡出
					transition=TransitionManager.start(mc, {type: Fade, direction: Transition.IN, duration: duration, easing: None.easeNone});
					break;
				case 4: 
					transition=TransitionManager.start(mc, {type: Iris, direction: Transition.IN, duration: duration, easing: Strong.easeOut, startPoint: 5, shape: Iris.CIRCLE});
					break;
				case 5: 
					transition=TransitionManager.start(mc, {type: Iris, direction: Transition.IN, duration: duration, easing: Strong.easeOut, startPoint: 5, shape: Iris.SQUARE});
					break;
				case 6: 
					transition=TransitionManager.start(mc, {type: PixelDissolve, direction: Transition.IN, duration: duration, easing: None.easeNone, xSections: 10, ySections: 10});
					break;
				case 7: 
					transition=TransitionManager.start(mc, {type: Wipe, direction: Transition.IN, duration: duration, easing: None.easeNone, startPoint: 1});
					break;
				case 8: 
					transition=TransitionManager.start(mc, {type: Wipe, direction: Transition.IN, duration: duration, easing: None.easeNone, startPoint: 3});
					break;
			}
			if(transition&&fun!=null)
			{
				//侦听动画播放完毕
				transition.addEventListener("transitionInDone",fun);
			}
		}
	}
}