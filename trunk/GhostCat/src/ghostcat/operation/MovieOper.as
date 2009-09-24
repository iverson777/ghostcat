package ghostcat.operation
{
	import ghostcat.display.movieclip.GMovieClip;
	import ghostcat.events.MovieEvent;

	/**
	 * 动画播放
	 * 
	 * @author flashyiyi
	 * 
	 */
	public class MovieOper extends Oper
	{
		/**
		 * 动画实例
		 */
		public var mc:GMovieClip;
		/**
		 * 标签名
		 */
		public var labelName:String;
		/**
		 * 循环次数 
		 */
		public var loop:int;
		
		public function MovieOper(mc:GMovieClip,labelName:String,loop:int = 1)
		{
			this.mc = mc;
			this.labelName = labelName;
			this.loop = loop;
		}
		
		public override function execute():void
		{
			super.execute();
			
			mc.addEventListener(MovieEvent.MOVIE_END,result);
			
			mc.setLabel(labelName,loop);
		}
		
		public override function result(event:* = null) : void
		{
			super.result(event);
			
			mc.removeEventListener(MovieEvent.MOVIE_END,result);
		}
		
		public override function fault(event:* = null) : void
		{
			super.fault(event);
		
			mc.removeEventListener(MovieEvent.MOVIE_END,result);
		}
	}
}