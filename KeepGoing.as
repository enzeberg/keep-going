package {
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.sampler.Sample;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	
	public class KeepGoing extends Sprite {
		private var operatedObject: Shape;
		private var circle: Shape;
		private var line:Shape;
		private var triangle:Shape;
		private var shield:Shape;
		private var satellite:Shape;
		private var splashScreenShp:Shape;//Splash Screen意为“闪屏”（启动画面）。
		private var supporter:Sprite;
		private var orbit:Sprite;
		private var randomNumList:Array;
		private var angle: Number = 0;
		private var angleForLine:Number=0;
		private var angleForTri:Number=0;
		private var angleForSatellite:Number=0;
		private var distance:Number;
		private var splashScreenTF:TextField;
		private var tipTF:TextField;
		private var timeTF:TextField;
		private var distanceTF:TextField;
		private var levelTF:TextField;
		private var mainTimer:Timer;//mainTimer为控制敌人出现快慢的计时器。
		private var shieldTimer:Timer;//shieldTimer为控制shield(防护盾)如何出现的计时器。
		private var satelliteTimer:Timer;///satelliteTimer为控制satellite（卫星）如何出现的计时器。
		private var startTime:uint;
		private const radius: uint = 100;
		private const oneStep:Number=2;
		private const anotherStep:uint=20;
		private const shieldSpeed:uint=10;
		private const orbitSpeed:uint=8;
		private var supporters:Array;
		private var circleList:Array;
		private var lineList:Array;
		private var triList:Array;
		private var enemies:Array;//每派出一个敌人，就push进去一个。使用此变量的一个好处是，方便检测operatedObject与敌人碰撞。
		private var shields:Array;
		private var leftArrow,upArrow,rightArrow,downArrow:Boolean=false;
		private var tipVec:Vector.<String>;
		private var winTipVec:Vector.<String>;
		private var loseTipVec:Vector.<String>;
		private var numOfFailures:uint=0;//该变量记录玩家失败的次数，用以让程序知道在玩家失败后该显示那条tip。这比用levelIndex变量好，若用levelIndex，
		                                 //那么如果玩家在同一关中失败两次，显示的tip也是一样的，没有新鲜感，也会造成一些tip没机会显示出来的状况。
		private var invokedTimes:uint=0;//该变量记录某一函数被调用的次数。
		private var levelIndex:uint;//该变量记录玩家玩到了第几关，0代表第一关，1代表第二关...
		private var withShield:Boolean=false;
		private const longestDelay:uint=1200;
		private const longDelay:uint=1000;
		private const shortDelay:uint=800;
		private const shortestDelay:uint=500;
		public function KeepGoing() {
			initialise();
			
		}
		private function initialise(): void {
			
			onSplashScreen();
		}
		private function onSplashScreen():void{
			
			showSplashScreen();
			loadXML();
		}
		private function showSplashScreen():void{//主要是绘制一些图形，这些图形会在加载XML完毕后被移出舞台。所以当加载几乎不消耗时间时，看不到闪屏。
            splashScreenShp=new Shape();
			splashScreenShp.graphics.beginFill(0x444345);
			splashScreenShp.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
			splashScreenShp.graphics.endFill();
			addChild(splashScreenShp);
			splashScreenTF=new TextField();
			splashScreenTF.defaultTextFormat=new TextFormat("等线 Light",100,0xffffff);
			splashScreenTF.text="Keep Going";
			splashScreenTF.autoSize="left";
			splashScreenTF.x=stage.stageWidth/2-splashScreenTF.width/2;
			splashScreenTF.y=stage.stageHeight/2;
			addChild(splashScreenTF);
		}
		private function loadXML():void{
			var loader:URLLoader=new URLLoader();
			var theRequest:URLRequest=new URLRequest("KeepGoing.xml");
			loader.load(theRequest);
			loader.addEventListener(Event.COMPLETE,finishLoading,false,0,true);
			tipVec=new Vector.<String>();
			winTipVec=new Vector.<String>();
			loseTipVec=new Vector.<String>();
		}
		private function finishLoading(e:Event):void{
			var resultXML:XML=new XML(e.target.data);
			
			
			for(var k in resultXML.tips.tip){
				tipVec.push(resultXML.tips.tip[k]);
			}
			for(var l in resultXML.tips.afterWinning.tip){
				winTipVec.push(resultXML.tips.afterWinning.tip[l]);
			}
			for(var j in resultXML.tips.afterLosing.tip){
				loseTipVec.push(resultXML.tips.afterLosing.tip[j]);
			}
			startGame();
			removeEventListener(Event.COMPLETE,finishLoading);
		}
		private function startGame():void{
			//removeSplashScreen();//将“闪屏”移出舞台。
			onGame();
		}
		private function onGame():void{
			introduceSomething();
			
		}
		private function introduceSomething():void{
			var tipTimer:Timer=new Timer(2500,3);
			//tipTimer.delay=0;
			tipTimer.start();
			tipTimer.addEventListener(TimerEvent.TIMER,introduceSthBeforePlaying);
			tipTimer.addEventListener(TimerEvent.TIMER_COMPLETE,startPlaying);
			setTimeout(removeSplashScreenTF,2500);
			setTimeout(removeSplashScreenShp,7500);
		}
		private function removeSplashScreenTF():void{
			removeChild(splashScreenTF);
		}
		private function removeSplashScreenShp():void{
			removeChild(splashScreenShp);
		}
		private function introduceSthBeforePlaying(e:TimerEvent):void{
			showTip(tipVec[invokedTimes]);
			invokedTimes++;
			
		}
		private function startPlaying(e:TimerEvent):void{
			firstLevel();//进入第一关。
            
			//e.target.stop();
			removeEventListener(TimerEvent.TIMER,introduceSthBeforePlaying);
			removeEventListener(TimerEvent.TIMER_COMPLETE,startPlaying);
			
		}
		//*********************************设置关卡********************************************************************
		//***********第一关*****************
		private function firstLevel():void{
			levelIndex=0;
			lineList=new Array();
			everyLevelNeeds();
			mainTimer=new Timer(longDelay);
			mainTimer.start();
			mainTimer.addEventListener(TimerEvent.TIMER,dispatchEnemy);
		}
        //***********第二关******************
		private function secondLevel():void{
			levelIndex=1;
			everyLevelNeeds();
			randomNumList=new Array();//第二关会出现circle,因此要初始化这个变量
			lineList=new Array();
			circleList=new Array();
			mainTimer=new Timer(longDelay);
			mainTimer.start();
			mainTimer.addEventListener(TimerEvent.TIMER,dispatchEnemy);
		}
		private function thirdLevel():void{
			levelIndex=2;
			everyLevelNeeds();
			randomNumList=new Array();
			circleList=new Array();
			triList=new Array();
			mainTimer=new Timer(longDelay);
			mainTimer.start();
			mainTimer.addEventListener(TimerEvent.TIMER,dispatchEnemy);
		}
		private function fourthLevel():void{
			levelIndex=3;
			everyLevelNeeds();
			triList=new Array();
			lineList=new Array();
			mainTimer=new Timer(longDelay);
			mainTimer.start();
			mainTimer.addEventListener(TimerEvent.TIMER,dispatchEnemy);
		}
		private function fifthLevel():void{
			levelIndex=4;
			everyLevelNeeds();
			triList=new Array();
			lineList=new Array();
			circleList=new Array();
			mainTimer=new Timer(longestDelay);
			mainTimer.start();
			mainTimer.addEventListener(TimerEvent.TIMER,dispatchEnemy);
			shieldTimer=new Timer(8000);
			shieldTimer.start();
			shieldTimer.addEventListener(TimerEvent.TIMER,dispatchShield);
		}
		private function sixthLevel():void{
			levelIndex=5;
			everyLevelNeeds();
			triList=new Array();
			lineList=new Array();
			circleList=new Array();
			mainTimer=new Timer(longDelay);
			mainTimer.start();
			mainTimer.addEventListener(TimerEvent.TIMER,dispatchEnemy);
			shieldTimer=new Timer(8000);
			shieldTimer.start();
			shieldTimer.addEventListener(TimerEvent.TIMER,dispatchShield);
		}
		private function seventhLevel():void{
			levelIndex=6;
			everyLevelNeeds();
			triList=new Array();
			lineList=new Array();
			circleList=new Array();
			mainTimer=new Timer(shortDelay);
			mainTimer.start();
			mainTimer.addEventListener(TimerEvent.TIMER,dispatchEnemy);
			shieldTimer=new Timer(8000);
			shieldTimer.start();
			shieldTimer.addEventListener(TimerEvent.TIMER,dispatchShield);
			satelliteTimer=new Timer(5000);
			satelliteTimer.start();
			satelliteTimer.addEventListener(TimerEvent.TIMER,dispatchSatellite);
		}
		private function eighthLevel():void{
			
		}
		private function ninthLevel():void{
			
		}
		private function tenthLevel():void{
			
		}
		//*********************************设置关卡 收尾**********************************************************************************
		private function everyLevelNeeds():void{//将每一关都需要用到的代码放到一个函数里。
			supporters=new Array();
			enemies=new Array();
			prepareOperatedObject();
			displayHead();
			add_event_listener();
		}
		//eeeeeeee            eeeeeeeeeeeee跟派出敌人有关的两个函数eeeeeeeeeeeeeeee        eeeeeeeeeeeeeeeeeeee
		private function dispatchEnemy(e:TimerEvent):void{//dispatchEnemy(e)侦听器能够判断玩家所在的关卡，根据所在关卡来派出敌人
		    prepareSupporter();
			if(levelIndex==0){
				lineCome();
			}else{
				randomEnemyCome();
			}
		}
		private function randomEnemyCome():void{
			var func:Function=new Function();
			switch(levelIndex){
				case 1:func=new Array(lineCome,circleCome)[Math.floor(Math.random()*2)];break;
				case 2:func=new Array(circleCome,triCome)[Math.floor(Math.random()*2)];break;
				case 3:func=new Array(triCome,lineCome)[Math.floor(Math.random()*2)];break;
			}
			if(levelIndex>=4){
				func=new Array(lineCome,circleCome,triCome)[Math.floor(Math.random()*3)];
			}
			func.apply();
		}
		//eeeeeeeeeeeeeeeeeeeeeeeeeee跟派出敌人有关的两个函数  收尾eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
		private function enterTheNextLevel():void{
			switch(levelIndex){
				case 0:secondLevel();break;
				case 1:thirdLevel();break;
				case 2:fourthLevel();break;
				case 3:fifthLevel();break;
				case 4:sixthLevel();break;
				case 5:seventhLevel();break;
				case 6:eighthLevel();break;
				case 7:ninthLevel();break;
				case 8:tenthLevel();break;
			}
		}
		
		
		//。。。。。。。。。。。。。。。显示游戏界面顶部的内容。。。。。。。。。。。。。。。。。。。。。
		private function displayHead():void{
			startTime=getTimer();
			var textFormat:TextFormat=new TextFormat("Verdana",20,0xffffff);
			timeTF=new TextField();
			timeTF.defaultTextFormat=textFormat;
			timeTF.autoSize="left";
			timeTF.x=10;
			timeTF.y=6;
			addChild(timeTF);
			levelTF=new TextField();
			levelTF.defaultTextFormat=new TextFormat("Calibri",40,0xffffff);
			levelTF.autoSize="left";
			levelTF.x=300;
			levelTF.y=timeTF.y;
			levelTF.text="Level "+String(levelIndex+1);
			addChild(levelTF);
			distanceTF=new TextField();
			distanceTF.defaultTextFormat=textFormat;
			distanceTF.autoSize="left";
			distanceTF.x=530;
			distanceTF.y=timeTF.y;
			addChild(distanceTF);
			addEventListener(Event.ENTER_FRAME,showClockAndDistance);
		}
		private function showClockAndDistance(e:Event):void{
			var deltaTime:int=getTimer()-startTime;
			var seconds:int=Math.floor(deltaTime/1000);
			var minutes:int=Math.floor(seconds/60);
			seconds-=minutes*60;
			var timeString:String=minutes+":"+String(seconds+100).substr(1,2);
			timeTF.text="Time "+timeString;
			distance=oneStep*(deltaTime/1000);
			distanceTF.text="Distance "+String(distance);
			//放弃之前尝试过的levelDurationTimer计时器，在此处控制每一关“玩家需要坚持的时间”
			var levelDuration:uint=levelIndex*3000+30000;//这个levelDuration变量的计算方式还需更改，现在是为了测试方便，把它设置得比较小。
			if(deltaTime>=levelDuration){
				transition();//通过某一关后，在正式进入下一关之前的过渡
				showTip(winTipVec[levelIndex]);
				enterTheNextLevel();
			}
		}
		//。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。。
		private function prepareRandomNum():void{
			for(var u:int=0;u<circleList.length;u++){
				var r:Number=Math.random();//可让不同的circle有着不同的旋转半径
				randomNumList.push(r);
			}	
		}
		private function prepareOperatedObject(): void {
			operatedObject = new Shape();
			operatedObject.graphics.beginFill(0x456789);
			operatedObject.graphics.drawRoundRect(-10,-10,20,20,12,12);
			operatedObject.graphics.endFill();
			operatedObject.x=5,operatedObject.y=stage.stageHeight/2;
			addChild(operatedObject);
		}
		
		private function moveSupporter(e:Event):void{
			for(var d in supporters){
				supporters[d].x+=-2;
			}
		}
		///////////////////////////将添加侦听器和移除侦听器的代码分别放到一个函数内，便于调用//////////////
		private function add_event_listener():void{
			stage.addEventListener(KeyboardEvent.KEY_DOWN,keydown);
			stage.addEventListener(KeyboardEvent.KEY_UP,keyup);
			addEventListener(Event.ENTER_FRAME,moveOperatedObject);
		}
		private function remove_event_listener():void{
			stage.removeEventListener(KeyboardEvent.KEY_DOWN,keydown);
			stage.removeEventListener(KeyboardEvent.KEY_UP,keyup);
			removeEventListener(Event.ENTER_FRAME,moveOperatedObject);
		    removeEventListener(Event.ENTER_FRAME,showClockAndDistance);
			removeEventListener(TimerEvent.TIMER,dispatchEnemy);
			removeEventListener(Event.ENTER_FRAME,moveSupporter);
			if(levelIndex==0){
				removeEventListener(Event.ENTER_FRAME,up_and_down);
			}else if(levelIndex==1){
				removeEventListener(Event.ENTER_FRAME,up_and_down);
				removeEventListener(Event.ENTER_FRAME,rotate);
			}else if(levelIndex==2){
				removeEventListener(Event.ENTER_FRAME,rotate);
				removeEventListener(Event.ENTER_FRAME,quiver);
			}else if(levelIndex==3){
				removeEventListener(Event.ENTER_FRAME,quiver);
			    removeEventListener(Event.ENTER_FRAME,up_and_down);
			}else if(levelIndex>=4){
				removeEventListener(Event.ENTER_FRAME,up_and_down);
				removeEventListener(Event.ENTER_FRAME,rotate);
				removeEventListener(Event.ENTER_FRAME,quiver);
				removeEventListener(TimerEvent.TIMER,dispatchShield);
				removeEventListener(Event.ENTER_FRAME,moveShield);
				removeEventListener(Event.ENTER_FRAME,follow);
				if(levelIndex>=6){
					removeEventListener(TimerEvent.TIMER,dispatchSatellite);
					removeEventListener(Event.ENTER_FRAME,orbitMove);
					removeEventListener(Event.ENTER_FRAME,satelliteRotate);
					removeEventListener(Event.ENTER_FRAME,orbitFollow);
				}
			}
		}
		///////////////////////////////////////////////////////////////////////////////////
		
		//---------------------------------------碰到敌人---------------------------------------------------------------------------------------------------------
		private function hitOneEnemy():void{
			for(var e in enemies){
				if(operatedObject.hitTestObject(enemies[e])){
					if(shield!=null){
						if(ifShieldHitsOO()){
						    removeShield();
						    shieldTimer.start();
						}else{
						      numOfFailures++;
						      transition();
						      showTip(loseTipVec[numOfFailures-1]);
						      setTimeout(playTheLevelAgain,2000);
					    }
					}else if(satellite!=null){   //与shield不同的是，satellite能保住玩家两条命。
					    if(ifOrbitHitsOO()){
							if(satellite.alpha==1){
							   destroySatellite();
						    }else{
							   removeSatellite();
							   satelliteTimer.start();
							   trace("satelliteTimer.start()");
						    }
						}else{
						   numOfFailures++;
						   transition();
						   showTip(loseTipVec[numOfFailures-1]);
						   setTimeout(playTheLevelAgain,2000);
					    }
					    
					}else{
						numOfFailures++;
						transition();
						showTip(loseTipVec[numOfFailures-1]);
						setTimeout(playTheLevelAgain,2000);
					}
					break;
				}
			}
		}
		//----------------------------------------------------------------------------------------------------------------------------------------------------------
		//tttttttttttttttt过渡，即  从一个关卡到下一个关卡（通过这一关）或回到这个关卡重玩（未通过这一关）   的过程中需要发生什么ttttttttttttttttttttttttttt
		private function transition():void{
			
			mainTimer.stop();
			mainTimer=null;		    
			
			if(shieldTimer!=null){
				shieldTimer.stop();
				shieldTimer=null;
			}
			if(satelliteTimer!=null){
				satelliteTimer.stop();
				satelliteTimer=null;
			}
			resetArrow();//重置leftArrow,rightArrow,upArrow,downArrow这些布尔变量，让它们再次为false.
			clearUp();
			remove_event_listener();
			//setTimeout(clearUp,1900);//该时间是根据showTip()所花时间来随便设定的。
		}
		//ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
		private function clearUp():void{//清理一些显示对象，并重置一些数组。
            if(stage.contains(operatedObject)){
				removeChild(operatedObject);
				//operatedObject=null;
			}
			if(stage.contains(timeTF)){
				removeChild(timeTF);
				timeTF=null;
			}
			if(stage.contains(levelTF)){
				removeChild(levelTF);
				levelTF=null;
			}
			if(stage.contains(distanceTF)){
				removeChild(distanceTF);
				distanceTF=null;
			}
			if(shield!=null){
				if(stage.contains(shield)){
					removeChild(shield);
					//shield=null;
				}
			}
			if(orbit!=null){
				if(stage.contains(orbit)){
					removeChild(orbit);
				}
			}
			for(var e in enemies){
				/*supporters[e].removeChild(enemies[e]);
				enemies[e]=null;*/
				if(supporters[e].contains(enemies[e])){
					supporters[e].removeChild(enemies[e]);
					enemies[e]=null;
				}
			}
			for(var s in supporters){
				if(stage.contains(supporters[s])){
					removeChild(supporters[s]);
					supporters[s]=null;
				}
			}
			enemies=null;
			supporters=null;
			//以下几条对于有些关卡是不需要的。比如第一关中只有lineList被实例化了，没必要将circleList,triList也设为null，但这样做是为了方便，“不管你有没有被实例化，一律设为null”
			lineList=null;
			circleList=null;
			triList=null;
			
		}
		private function playTheLevelAgain():void{
			var whichLevelFuncList:Array=[firstLevel,secondLevel,thirdLevel,fourthLevel,fifthLevel,sixthLevel,seventhLevel,eighthLevel,ninthLevel,tenthLevel];
			var intoWhichLevel:Function=whichLevelFuncList[levelIndex];
			intoWhichLevel.apply();
		}
        private function resetArrow():void{ 
			leftArrow=false;
			rightArrow=false;
			upArrow=false;
			downArrow=false;
		}
		//.................................跟显示tip有关的代码.....................................................
		private function showTip(txt:String):void{//showTip()会让那一条条tip显示再消失。
			tipTF=new TextField();
			tipTF.autoSize="left";
			tipTF.defaultTextFormat=new TextFormat("幼圆",30,0xffffff);
			tipTF.text=txt;
			tipTF.x=(stage.stageWidth-tipTF.width)/2;
			tipTF.y=(stage.stageHeight-tipTF.height)/2;
			addChild(tipTF);
			setTimeout(removeTip,800);
		}
		private function removeTip():void{
			addEventListener(Event.ENTER_FRAME,removeTipGradually,false,0,true);  //为了让tip在消失的过程中有一个渐隐的效果，只好再调用一个事件类型为ENTER_FRAME的侦听器函数。
		}
		private function removeTipGradually(e:Event):void{
			tipTF.alpha-=0.03;
			if(tipTF.alpha<=0){//在tipTF变为完全透明后，将它移出舞台，并移除“将tipTF移出舞台”的侦听器，即这个函数本身。
				removeChild(tipTF);
				removeEventListener(Event.ENTER_FRAME,removeTipGradually);
			}
		}
		//.................................跟显示tip有关的代码  收尾..............
		private function checkForOut():void{
			if(operatedObject.x<=0){
				operatedObject.x=0;
			}
			if(operatedObject.x>=stage.stageWidth){
				operatedObject.x=stage.stageWidth;
			}
			if(operatedObject.y<=0){
				operatedObject.y=0;
			}
			if(operatedObject.y>=stage.stageHeight){
				operatedObject.y=stage.stageHeight;
			}
		}
		private function reminder(txt:String):void{
			var tf:TextField=new TextField();
			tf.autoSize="left";
			tf.defaultTextFormat=new TextFormat("幼圆",30,0xffffff);
			tf.text=txt;
			tf.x=(stage.stageWidth-tf.width)/2;
			tf.y=(stage.stageHeight-tf.height)/2;
			addChild(tf);
		}
		//................................
		
		private function prepareSupporter():void{
			supporter=new Sprite();
			supporter.x=randomX();
			supporter.y=randomY();
			addChild(supporter);
			supporters.push(supporter);
			addEventListener(Event.ENTER_FRAME,moveSupporter);
		}
		//XXX       XXX    XXXXXX     XXXXXXX  三种类型的敌人  XXXXXXXXXXXXXXXXXX
		public function circleCome():void{
			
			circle=new Shape();
			circle.graphics.beginFill(0xffffff*Math.random());
			circle.graphics.drawCircle(0,0,Math.random()+4);
			circle.graphics.endFill();
			supporters[enemies.length].addChild(circle);//此行重要，必须放在"enemies.push(circle)"
			//前面。举个例子，当suppoters数组长度为1时，enemies数组长度还为0，正好为"supporters[0].addChild(circle)".
			enemies.push(circle);
			circleList.push(circle);
			addEventListener(Event.ENTER_FRAME, rotate);
			prepareRandomNum();
		}
		public function lineCome():void{
			line=new Shape();
			var linex:Number=Math.random();
			var liney:Number=Math.random();
			line.graphics.lineStyle(Math.random()+1,0xffffff*Math.random());
			line.graphics.moveTo(linex,liney);
			line.graphics.lineTo(linex,liney+Math.random()*100);
			supporters[enemies.length].addChild(line);
			enemies.push(line);
			lineList.push(line);
			addEventListener(Event.ENTER_FRAME,up_and_down);
		}
		private function triCome():void{
			var ran:Number=Math.random();
			triangle=new Shape();
			triangle.graphics.beginFill(0xffffff*Math.random());
			triangle.graphics.drawTriangles(Vector.<Number>([0,0,ran*50,0,ran*50/2,ran*20]));
			triangle.graphics.endFill();
			supporters[enemies.length].addChild(triangle);
			enemies.push(triangle);
			triList.push(triangle);
			addEventListener(Event.ENTER_FRAME,quiver);
		}
		//XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
		//SSSSSSSSSSSSSSSSSSSSSSSS              三种运动方式             SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
		private function rotate(e:Event):void{
			for(var c in circleList){
			  circleList[c].x=randomNumList[c]*radius*Math.cos(angle);
			  circleList[c].y=randomNumList[c]*radius*Math.sin(angle);
			}
			angle+=.1;
		}		
		private function up_and_down(e:Event):void{
			for(var l in lineList){
				lineList[l].y=Math.sin(angleForLine)*30;
			
			}
			angleForLine+=.6;
			
		}
		private function quiver(e:Event):void{
			for(var t in triList){
			  triList[t].x=Math.sin(angleForTri)*50*Math.random();
			  triList[t].y=Math.sin(angleForTri)*25*Math.random();
			}
			angleForTri+=.2;
		}
		//SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS
		//盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾       跟防护盾有关的函数       盾盾盾盾盾盾盾盾盾盾盾盾
		private function dispatchShield(e:TimerEvent):void{
			shield=new Shape();
			shield.graphics.lineStyle(2,0x258369,.6);
			shield.graphics.drawCircle(0,0,25);
			shield.x=randomX();
			shield.y=randomY();
			addChild(shield);
			addEventListener(Event.ENTER_FRAME,moveShield);
		}
		private function moveShield(e:Event):void{
            shield.x-=10;			
			ifShieldHitsOO();
		    if(shield.x<=-10){
				removeEventListener(Event.ENTER_FRAME,moveShield);//shield都越出屏幕了，把shield设为null，也要移除这个让它移动的侦听器。
				removeChild(shield);
				//shield=null;
			}
		}
		private function ifShieldHitsOO():Boolean{
			if(shield.hitTestObject(operatedObject)){
				shieldTimer.stop();
				removeEventListener(Event.ENTER_FRAME,moveShield);
				addEventListener(Event.ENTER_FRAME,follow);
				//showTip("这个宝贝或许能让你体验一下横冲直撞的快感");
				return true;
			}
			return false;
		}
		private function follow(e:Event):void{
			shield.x=operatedObject.x;
			shield.y=operatedObject.y;
		}
		private function removeShield():void{
			addEventListener(Event.ENTER_FRAME,removeShieldGradually);			
		}
		private function removeShieldGradually(e:Event):void{
			shield.alpha-=.03;
			if(shield.alpha<=0){
				//removeChild(shield);
				//shield=null;
				removeEventListener(Event.ENTER_FRAME,follow);
				removeEventListener(Event.ENTER_FRAME,removeShieldGradually);

			}
		}
		//盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾盾
		//卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫          跟“卫星”有关的函数           卫卫卫卫卫卫卫卫卫卫卫卫卫卫
		private function dispatchSatellite(e:TimerEvent):void{
			satellite=new Shape();
			satellite.graphics.beginFill(0x456789);
			satellite.graphics.drawCircle(0,0,5);
			satellite.graphics.endFill();
			orbit=new Sprite();
			orbit.graphics.lineStyle(2,0x666666);
			orbit.graphics.drawCircle(0,0,27);
			orbit.graphics.endFill();
			orbit.x=randomX();
			orbit.y=randomY();
			addChild(orbit);
			orbit.addChild(satellite);
			addEventListener(Event.ENTER_FRAME,orbitMove);
			addEventListener(Event.ENTER_FRAME,satelliteRotate);
		}
		private function orbitMove(e:Event):void{
			orbit.x-=orbitSpeed;
			ifOrbitHitsOO();
			if(orbit.x<-20){
				removeEventListener(Event.ENTER_FRAME,orbitMove);
				removeChild(satellite);
				removeChild(orbit);
			}
		}
		private function satelliteRotate(e:Event):void{
			satellite.x=Math.sin(angleForSatellite)*27;
			satellite.y=Math.cos(angleForSatellite)*27;
			angleForSatellite+=0.08;

		}
		private function ifOrbitHitsOO():Boolean{
			if(orbit.hitTestObject(operatedObject)){
				satelliteTimer.stop();
				removeEventListener(Event.ENTER_FRAME,orbitMove);
				addEventListener(Event.ENTER_FRAME,orbitFollow);
				return true;
			}
			return false;
		}
		private function orbitFollow(e:Event):void{
			orbit.x=operatedObject.x;
			orbit.y=operatedObject.y;
		}
		private function destroySatellite():void{
			satellite.alpha=0.5;
		}
		private function removeSatellite():void{
			removeChild(satellite);
		}
		//卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫卫
		private function keydown(e:KeyboardEvent):void{
			if(e.keyCode==37){
				leftArrow=true;
			}else if(e.keyCode==39){
				rightArrow=true;
			}else if(e.keyCode==38){
				upArrow=true;
			}else if(e.keyCode==40){
				downArrow=true;
			}
		}
		private function keyup(e:KeyboardEvent):void{
			if(e.keyCode==37){
				leftArrow=false;
			}else if(e.keyCode==39){
				rightArrow=false;
			}else if(e.keyCode==38){
				upArrow=false;
			}else if(e.keyCode==40){
				downArrow=false;
			}
		}
		private function moveOperatedObject(e:Event):void{
			if(leftArrow){
				operatedObject.x+=-anotherStep;
			}else if(rightArrow){
				operatedObject.x+=anotherStep;
			}else if(upArrow){
				operatedObject.y+=-anotherStep;
			}else if(downArrow){
				operatedObject.y+=anotherStep;
			}
			checkForOut();
			hitOneEnemy();
		}
		private function randomX():Number{
			var rx:Number=stage.stageWidth+Math.random()*20;
			return rx;
		}
		private function randomY():Number{
			var ry:Number=stage.stageHeight*Math.random();
			return ry;
		}
	}
}
