package ghostcat.display.movieclip
{
	import flash.display.FrameLabel;
	import flash.display.Sprite;
	
	import ghostcat.debug.Debug;

	/**
	 * 使用动画剪辑模拟代码动画，可以再次继承此类来来处理特殊情况
	 * 
	 * @author flashyiyi
	 * 
	 */	
	
	public class GScriptMovieClip extends GMovieClipBase
	{
		/**
		 * 渲染方法，参数为GScrpitMovieClip本身
		 */
		public var cmd:Function;
		
		/**
		 * 
		 * @param cmd	渲染方法
		 * @param totalFrames	动画长度
		 * @param labels	标签数组，内容为FrameLabel类型
		 * @param paused	是否暂停
		 * 
		 */	
		public function GScriptMovieClip(cmd:Function,totalFrames:int,labels:Array=null,paused:Boolean=false)
		{
			this.cmd = cmd;
			this._totalFrames = totalFrames;
			this._labels = labels ? labels : [];
			
			super(new Sprite(),true,paused);
			
			reset();
		}
        /** @inheritDoc*/
        public override function set currentFrame(frame:int):void
        {
        	if (frame < 1)
        		frame = 1;
        	if (frame > totalFrames)
        		frame = totalFrames;
        	
        	if (_currentFrame == frame)
        		return;
        		
        	_currentFrame = frame;
        
        	cmd.call(null,this);
			
			super.currentFrame = frame;
		}
        
        public function set totalFrames(v:int):void
        {
        	_totalFrames = v;
        }
        
		public function set labels(v:Array):void
        {
        	_labels = v;
        }
	}
}