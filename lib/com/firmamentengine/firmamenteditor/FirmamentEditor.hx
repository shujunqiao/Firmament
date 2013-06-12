package com.firmamentengine.firmamenteditor;


import com.firmamentengine.firmamenteditor.ui.EntitySelector;
import com.firmamentengine.firmamenteditor.ui.EntityWindow;
import com.firmamentengine.firmamenteditor.ui.ProjectSettings;
import com.firmamentengine.firmamenteditor.ui.ToolBar;

import com.firmamentengine.firmamenteditor.ui.ConfigEditor;



import firmament.component.physics.FPhysicsComponentInterface;
import firmament.world.FBox2DWorld;
import firmament.core.FCamera;
import firmament.core.FEntity;
import firmament.core.FEntity;
import firmament.core.FGame;
import firmament.core.FInput;
import firmament.core.FVector;
import firmament.ui.FDialog;
import firmament.ui.FStyle;
import firmament.ui.FWindow;
import nme.Assets;
import nme.display.StageAlign;
import nme.display.StageQuality;
import nme.display.StageScaleMode;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.Lib;
import nme.text.Font;
import nme.net.SharedObject;

/**
 * ...
 * @author Jordan Wambaugh
 */
using StringTools;
using firmament.util.FEntityCompat;
class FirmamentEditor
{
	
	public static var camera:FCamera;
	public static var projectEditor:ProjectSettings;
	public static var game:FGame;
	public static var entitySelector:EntitySelector;
	public static var toolBar:ToolBar;
	public static var entityWindow:EntityWindow;

	public static var settings:SharedObject;
	public static var dragEnt:FEntity;
	public static var cwd:String;
	public static var dragOffset:FVector;
    public static function main()
    {
	    #if (flash9 || flash10)
		haxe.Log.trace = function(v,?pos) { untyped __global__["trace"](pos.className+"#"+pos.methodName+"("+pos.lineNumber+"):",v); }
		#elseif flash
		haxe.Log.trace = function(v,?pos) { flash.Lib.trace(pos.className+"#"+pos.methodName+"("+pos.lineNumber+"): "+v); }
		#end


		var executableDir:String = Sys.executablePath();

		if(Sys.getEnv("FirmamentEditorCWD") != null && Sys.getEnv("FirmamentEditorCWD") != ""){
			Sys.setCwd(Sys.getEnv("FirmamentEditorCWD"));
			trace("set cwd to "+Sys.getEnv("FirmamentEditorCWD"));
		}

		if(Sys.getEnv("FirmamentEditorPath") != null && Sys.getEnv("FirmamentEditorPath") != ""){
			executableDir = Sys.getEnv("FirmamentEditorPath");
		}else{

			executableDir=executableDir.replace("\\","/");
			var arr:Array<String>=executableDir.split('/');
			arr.pop();
			executableDir = arr.join("/");
		}
		//Sys.setCwd(executableDir);
		//set styles

		cwd = Sys.getCwd();
		trace(executableDir);
		trace(cwd);
		//temporarily changeworking directory while we load our font
		Sys.setCwd(executableDir);
	
		var font:Font = Assets.getFont("assets/fonts/Ubuntu-R.ttf");
		
		FStyle.setStyleObj("",{
			fontName:font.fontName
			,fontHeightMultiplier:1
			,fontHeightAdd:5
					
		});

		//load settings
		settings = SharedObject.getLocal('FirmamentEditorSettings');

	   	
		var stage = Lib.current.stage;
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.quality = StageQuality.BEST;
		camera = new FCamera(stage.stageWidth,stage.stageHeight);
		camera.setDebugMode(true);
		game  = FGame.getInstance();
		
		game.enableSimulation = false;
		game.addCamera("main",camera);
		stage.addChild(camera);
		
		toolBar = new ToolBar();
		if(Reflect.isObject(settings.data.windowPositions) && Reflect.isObject(settings.data.windowPositions.toolBar)){
			toolBar.x = settings.data.windowPositions.toolBar.x;
			toolBar.y = settings.data.windowPositions.toolBar.y;
			if(settings.data.windowPositions.toolBar.expanded)toolBar.expand();
			else toolBar.collapse();
		}
		stage.addChild(toolBar);
	  
	    
		projectEditor = new ProjectSettings();
		projectEditor.y = 60;
		if(Reflect.isObject(settings.data.windowPositions) && Reflect.isObject(settings.data.windowPositions.projectEditor)){
			projectEditor.x = settings.data.windowPositions.projectEditor.x;
			projectEditor.y = settings.data.windowPositions.projectEditor.y;
			if(settings.data.windowPositions.projectEditor.expanded)projectEditor.expand();
			else projectEditor.collapse();
		}
		stage.addChild(projectEditor);
		
		
		entityWindow = new EntityWindow();
		entityWindow.x = 650;
		if(Reflect.isObject(settings.data.windowPositions)){
			entityWindow.x = settings.data.windowPositions.entityWindow.x;
			entityWindow.y = settings.data.windowPositions.entityWindow.y;
			if(settings.data.windowPositions.entityWindow.expanded)entityWindow.expand();
			else entityWindow.collapse();
		}
		stage.addChild(entityWindow);
		
		projectEditor.addEventListener(ProjectSettings.PROJECT_READY, function(e:Event) {
			if(entitySelector == null){
				entitySelector = new EntitySelector(projectEditor.getEntityDir());
				entitySelector.y = 350;
				if(Reflect.isObject(settings.data.windowPositions) && Reflect.isObject(settings.data.windowPositions.entitySelector)){
					entitySelector.x = settings.data.windowPositions.entitySelector.x;
					entitySelector.y = settings.data.windowPositions.entitySelector.y;
					if(settings.data.windowPositions.entitySelector.expanded)entitySelector.expand();
					else entitySelector.collapse();
				}
				stage.addChild(entitySelector);
			}
		});
		projectEditor.autoLoad();
		
		//enable auto resize
		stage.addEventListener(Event.RESIZE, function(e:Event) { camera.resizeToStage(); } );
		trace(stage.stageWidth);
		
		camera.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) { 
			var point:FVector = camera.getWorldPosition(e.localX, e.localY);
			var ents = FGame.getInstance().getEntitiesAtPoint(point);
			if (ents.length > 0) {
				ents.sort(function(a:FEntity,b:FEntity):Int{
					var bc = b.getPhysicsComponent();
					var ac = a.getPhysicsComponent();
					if(bc == null || ac == null){
						trace('null physics component!');
						return 0;
					}
					
					try{
					 	var cmp = cast(bc,FPhysicsComponentInterface).getZPosition() - cast(ac,FPhysicsComponentInterface).getZPosition();
					 	if (cmp==0) {
						return 0;	
						} else if (cmp > 0) return 1;
						return -1;
					}catch(e:Dynamic){
						trace('exception: '+e);
						trace(Type.getClass(bc));
						trace(Type.getClass(ac));
						return 0;
					}
					
				});
				dragEnt = cast(ents[0], FEntity);
				entityWindow.setEntity(cast(ents[0]));
				point.subtract(dragEnt.getPosition());
				dragOffset = point;
			}
		} );
		
		camera.addEventListener(MouseEvent.MOUSE_MOVE, function(e:MouseEvent) { 
			if (dragEnt == null) return;
			var point = camera.getWorldPosition(e.localX, e.localY);
			point.subtract(dragOffset);
			dragEnt.setPosition(point);
			stage.dispatchEvent(new Event('entityMove'));
		});
		camera.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) { 
			dragEnt = null;
		});
		
		
		var input = new FInput(stage);
		
		game.addEventListener(FGame.BEFORE_STEP, function(e:Event) {
			
			//trace(input.getStageX());
			
			if (input.isKeyPressed(38)) {
				camera.setPosition(new FVector(camera.getPositionX(),camera.getPositionY()-.2));
			}
			if (input.isKeyPressed(40)) {
				camera.setPosition(new FVector(camera.getPositionX(),camera.getPositionY()+.2));
			}
			if (input.isKeyPressed(37)) {
				camera.setPosition(new FVector(camera.getPositionX()-.2,camera.getPositionY()));
			}
			if (input.isKeyPressed(39)) {
				camera.setPosition(new FVector(camera.getPositionX()+.2,camera.getPositionY()));
			}
			if (input.isKeyPressed(270)) {
				camera.setZoom(camera.getZoom() * 1.02);
			}
			if (input.isKeyPressed(269)) {
				camera.setZoom(camera.getZoom() * .98);
			}
			
		} );

		//executed on close.
		stage.onQuit=function():Void{
			

			var windowPositions:Dynamic={};
			
			windowPositions.entityWindow={};
			windowPositions.entityWindow.x=entityWindow.x;
			windowPositions.entityWindow.y=entityWindow.y;
			windowPositions.entityWindow.expanded=entityWindow.isExpanded();

			windowPositions.projectEditor={};
			windowPositions.projectEditor.x=projectEditor.x;
			windowPositions.projectEditor.y=projectEditor.y;
			windowPositions.projectEditor.expanded=projectEditor.isExpanded();

			windowPositions.toolBar={};
			windowPositions.toolBar.x=toolBar.x;
			windowPositions.toolBar.y=toolBar.y;
			windowPositions.toolBar.expanded=toolBar.isExpanded();

			windowPositions.entitySelector={};
			windowPositions.entitySelector.x=entitySelector.x;
			windowPositions.entitySelector.y=entitySelector.y;
			windowPositions.entitySelector.expanded=entitySelector.isExpanded();

			settings.data.windowPositions = windowPositions;
			settings.flush();
			Lib.close();
		};

		Sys.setCwd(cwd);
		//FDialog.prompt("Howdy! please put somthing in here.", function(s) { } ,"Please enter your name","jordan");
    }
}
