package org.ghostcat.display.movieclip
{
	import flash.display.DisplayObject;
	import flash.display.FrameLabel;
	import flash.media.Sound;
	import flash.media.SoundTransform;
	import flash.utils.Dictionary;
	
	import org.ghostcat.events.MoveEvent;
	import org.ghostcat.events.MovieEvent;
	import org.ghostcat.events.TickEvent;
	import org.ghostcat.util.Handler;
	import org.ghostcat.util.Tick;
	import org.ghostcat.util.Util;
	
	import org.ghostcat.display.GBase;

	[Event(name="movie_start",type="org.gameui.events.MovieEvent")]
	
	[Event(name="movie_end",type="org.gameui.events.MovieEvent")]
	
	[Event(name="movie_empty",type="org.gameui.events.MovieEvent")]
	
	
	/**
	 * 作为GMovieClip和BitmapMovieClip共同的基类。此类不允许实例化。
	 * 
	 * @author flashyiyi
	 * 
	 */
	public class GMovieClipBase extends GBase
	{
		/**
		 * 全局默认帧频，为0时则取舞台帧频。
		 */
		public static var defaultFrameRate:int=0;
		
		/**
		 * 保存着所有的帧上函数
		 */
		public static var labelHandlers:Dictionary = new Dictionary();
		
		/**
		 * 注册一个根据特定帧标签执行的函数
		 * 
		 * @param name
		 * @param h
		 * 
		 */		
		public static function registerHandler(name:String,h:Handler):void
		{
			labelHandlers[name] = h;
		}
		
		/**
		 * 注册一个根据特定帧标签播放的声音
		 * 
		 * @param name
		 * @param h
		 * 
		 */		
		public static function registerSound(name:String,s:Sound,loop:int = 1,volume:Number = 1.0,pan:Number = 0):void
		{
			registerHandler(name,new Handler(s.play,[0,loop,new SoundTransform(volume,pan)]));
		}
		
		private var _frameRate:int=0;
		
		private var numLoops:int=-1;//循环次数，-1为无限循环
		
		private var nextLabels:Array = [];//Labels列表
        
        protected var curLabelIndex:int=0;//缓存LabelIndex的序号，避免重复遍历
        
        private var frameTimer:int;//记时器

		private var _paused:Boolean;
		
		/**
		 * 是否暂停动画。暂停后的动画和原本的MovieClip行为相同。
		 * @return 
		 */		
		public function get paused():Boolean
		{
			return _paused;
		}

		public function set paused(v:Boolean):void
		{
			if (_paused == v)
				return;
				
			if (v){
				Tick.instance.addEventListener(TickEvent.TICK,tickHandler);
			}else{
				Tick.instance.removeEventListener(TickEvent.TICK,tickHandler);
			}
			_paused = v;
		}
		
		public function GMovieClipBase(skin:DisplayObject=null, replace:Boolean=true)
		{
			super(skin, replace);
		}
		
		/**
		 * 设置帧频，设为0表示使用默认帧频。
		 */		
		public function get frameRate():int
		{
			if (_frameRate > 0)
				return 	_frameRate;
			else if (defaultFrameRate > 0)
				return defaultFrameRate;
			else if (stage)
				return stage.frameRate;
			else
				return 0;
		}

		public function set frameRate(v:int):void
		{
			_frameRate = v;
		}
		
		/**
         * 获得标签的序号
         *  
         * @param labelName
         * @return 
         * 
         */
        public function getLabelIndex(labelName:String):int
        {
        	for (var i:int = 0;i<labels.length;i++)
        	{
        		if ((labels[i] as FrameLabel).name == labelName)
        			return i;
        	}
        	return -1;
        }
		
		/**
		 * 设置当前动画 
		 * @param labelName		动画名称
		 * @param repeat		动画循环次数，设为-1为无限循环
		 * 
		 */
		 		
		public function setLabel(labelName:String, repeat:int=-1):void
        {
        	nextLabels = [];
        	
            var index:int = getLabelIndex(labelName);
			if (index != -1)
			{
				numLoops = repeat;
				currentFrame  = labels[index].frame;
				curLabelIndex = index;
				
				dispatchEvent(Util.createObject(new MoveEvent(MovieEvent.MOVIE_START),{labelName:curLabelName}))
				
				if (GMovieClipBase.labelHandlers[labelName])
					(GMovieClipBase.labelHandlers[labelName] as Handler).call();
        	}
        }
        
        /**
         *
         * 将动画推入列表，延迟播放
         * @param labelName		动画名称
         * @param repeat		动画循环次数，设为-1为无限循环
         * 
         */
                 
        public function queueLabel(labelName:String, repeat:int=-1):void
        {
            nextLabels.push([labelName, repeat]);
        }
        
        /**
         * 清除动画队列 
         */
         		
        public function clearQueue():void
        {
            nextLabels = [];
        }
		
		protected function tickHandler(event:TickEvent):void
		{
			if (frameRate == 0)
				return;
			
			frameTimer -= event.interval;
            while (numLoops > 0 && frameTimer < 0) 
			{
				if (hasReachedLabelEnd())
				{
					if (numLoops > 0)
					{
						numLoops--;
					}
					
					if (numLoops == 0)
					{
						dispatchEvent(Util.createObject(new MoveEvent(MovieEvent.MOVIE_END),{labelName:curLabelName}));
						if (nextLabels.length > 0)
						{
							setLabel(nextLabels[0][0], nextLabels[0][1]);
							nextLabels.splice(0, 1);
						}
						else 
						{
							dispatchEvent(Util.createObject(new MoveEvent(MovieEvent.MOVIE_EMPTY),{labelName:curLabelName}));
						}
					}
					else 
					{
						loopBackToStart();
					}
				}
				else
				{
					nextFrame();
				}
				frameTimer += 1000/frameRate;
			}
		}
		
		/**
         * 回到当前动画的第一帧 
         */
        public function loopBackToStart():void
        {
            currentFrame = (labels.length > 0) ? labels[curLabelIndex].frame : 1;
        }
		
		
		public override function destory():void
		{
			super.destory();
			
			paused = false;
		}
		
		//检测是否已经到达当前区段的尾端
		private function hasReachedLabelEnd():Boolean
        {
            if (curLabelIndex + 1 < labels.length)
            {
                return currentFrame >= labels[curLabelIndex + 1].frame - 1;
            }
            return currentFrame >= totalFrames;
        }
        
        /**
		 * 所有标签
		 * @return 
		 * 
		 */
		public function get labels():Array
		{
			return null;
		}
		
		/**
		 * 当前动画名称
		 * @return 
		 * 
		 */	
		public function get curLabelName():String
		{
			return null;
		}
		
		/**
		 * 当前帧
		 * 
		 * @return 
		 * 
		 */
		public function get currentFrame():int
        {
        	return -1;
        }
        
        public function set currentFrame(frame:int):void
        {
        }
        
        /**
         * 总帧数
         * 
         * @return 
         * 
         */
        public function get totalFrames():int
        {
        	return -1;
        }
        
        /**
         * 下一帧
         * 
         */
        public function nextFrame():void
        {
        }
	}
}