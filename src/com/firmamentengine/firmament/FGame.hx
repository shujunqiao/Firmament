package com.firmamentengine.firmament;

/**
 * ...
 * @author Jordan Wambaugh
 */


import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.events.TimerEvent;
import nme.Lib;
import nme.events.Event;

import nme.utils.Timer;

import com.firmamentengine.firmament.FPhysicsEntity;
import com.firmamentengine.firmament.FPhysicsWorld;
import com.firmamentengine.firmament.FCamera;
class FGame 
{
	var camera:FCamera;
	var world:FPhysicsWorld;
	var worldArray:Array<FWorld>;
	public function new() 
	{
		var stage = Lib.current.stage;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		// entry point
		
		world = new FPhysicsWorld(new FVector(0, 1));
		world.createEntity( {
			test:'blah'
			,position:new FVector(0, 0)
			,type:'dynamic'
			,shapes:[
				{
					type:'circle'
					,radius:1
					,restitution:1
				}
			]
		});
		world.createEntity( {
			test:'blah'
			,position:new FVector(.5, 0)
			,type:'dynamic'
			,shapes:[
				{
					type:'circle'
					,radius:1
					,restitution:1
				}
				
			]
		});
		
		world.createEntity( {
			test:'blah'
			,position:new FVector(.5, 3)
			,type:'static'
			,shapes:[
				{
					type:'box'
					,width:10
					,height:.2
				}
				
			]
		});
		camera = new FCamera(500,500);
		worldArray = new Array<FWorld>();
		worldArray.push(world);
		stage.addEventListener(Event.ENTER_FRAME, this_onEnterFrame);
		
		var timer = new Timer(33);
		timer.addEventListener(TimerEvent.TIMER, this_step);
		timer.start();
		
		stage.addChild(camera);
		
	}
	private function this_step(timer):Void {
		//trace('step');
		for (world in this.worldArray) {
			world.step();
			
		}
	}
	private function this_onEnterFrame (event:Event):Void {
		//trace('this is called.');
		camera.render(worldArray);
		
	}
}