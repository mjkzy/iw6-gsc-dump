#include maps\mp\_utility;
#include common_scripts\utility;

// _elevator_v2: used in mp_mines.gsc (original was used in mp_fahrenheit).
// Making adjustments to allow for multiple types of elevators

//	ELEVATOR TEST
ELEVATOR_DOOR_TIME = 2;
ELEVATOR_FLOOR_MOVE_TIME = 5;
ELEVATOR_AUTOCLOSE_TIMEOUT = 10;

ELEVATOR_DOOR_STATE_CLOSED = 0;
ELEVATOR_DOOR_STATE_OPENING = 1;
ELEVATOR_DOOR_STATE_OPEN = 2;
ELEVATOR_DOOR_STATE_CLOSING = 3;

// should scale elevator door speed based on the actual distance moved
// in case of interrupts

init_elevator( config )
{
	elevator = GetEnt( config.name, "targetname" );
	AssertEx( IsDefined( elevator ), "Could not find an elevator entity named " + config.name );
	elevator.unresolved_collision_func = ::handleUnreslovedCollision;
	
	elevator.doors = [];
	if ( IsDefined( config.doors ) )
	{
		foreach ( floorname, doorset in config.doors )
		{
			list = [];
			foreach ( doorname in doorset )
			{
				list[ list.size ] = setupDoor( doorName + "left", false, config.doorMoveDist );
				list[ list.size ] = setupDoor( doorName + "right", true, config.doorMoveDist );
			}
			
			elevator.doors[ floorname ] = list;
		}
		
		if ( IsDefined( config.doorOpenTime ) )
			elevator.doorOpenTime = config.doorOpenTime;
		else
			elevator.doorOpenTime = ELEVATOR_DOOR_TIME;
		
		elevator.doorSpeed = config.doorMoveDist / elevator.doorOpenTime;
		
		if ( IsDefined( config.autoCloseTimeout ) )
			elevator.autoCloseTimeout = config.autoCloseTimeout;
		else
			elevator.autoCloseTimeout = ELEVATOR_AUTOCLOSE_TIMEOUT;
		
		elevator.trigBlock = GetEnt( config.trigBlockName, "targetname" );
		AssertEx( IsDefined( elevator.trigBlock ), "Could not find an elevator trigger named " + config.trigBlockName );
		
		if ( IsDefined( config.autoCloseTimeout ) )
			elevator.autoCloseTimeout = config.autoCloseTimeout;
		else
			elevator.autoCloseTimeout = ELEVATOR_AUTOCLOSE_TIMEOUT;
		
		elevator.doorOpenSfx = config.doorOpenSfx;	// scn_elevator_doors_opening
		elevator.doorCloseSfx = config.doorCloseSfx;	// scn_elevator_doors_closing
	}
	
	if ( IsDefined( config.moveTime ) )
		elevator.moveTime = config.moveTime;
	else
		elevator.moveTime = ELEVATOR_FLOOR_MOVE_TIME;
	
	elevator.destinations = [];
	elevator.pathBlockers = [];
	elevator.buttons = GetEntArray( config.buttons, "targetname" );
	foreach ( button in elevator.buttons )
	{
		button setupButton( elevator );
	}
	
	// set up destinations
	destinationStructs = getstructarray( config.destinations, "targetname" );
	foreach ( destination in destinationStructs )
	{
		elevator setupDestination( destination );
	}
	elevator.destinationNames = config.destinationNames;
	
	elevator.curFloor = config.destinationNames[0];	// "floor1"; should this be determined from destinations?
	elevator.requestedFloor = elevator.curFloor;
	elevator.doorState = ELEVATOR_DOOR_STATE_CLOSED;
	
	if ( IsDefined( config.models ) )
	{
		elevatorModels = GetEntArray( config.models, "targetname" );
		if ( IsDefined( elevatorModels ) )
		{
			foreach ( eleModel in elevatorModels )
			{
				eleModel LinkTo( elevator );
			}
		}
	}
	
	elevator thread elevatorThink();
	
	if (elevator.doors.size > 0)
	{
		elevator thread openElevatorDoors( elevator.curFloor, false );
	}
	
	// sounds
	elevator.startSfx = config.startSfx;	// "scn_elevator_startup"
	elevator.stopSfx = config.stopSfx;	//  "scn_elevator_stopping"
	elevator.loopSfx = config.loopSfx;	// "scn_elevator_moving_lp"
	elevator.beepSfx = config.beepSfx;	// "scn_elevator_beep"
	
	
	// callback on init
	elevator.onMoveCallback = config.onMoveCallback;
	elevator.onArrivedCallback = config.onArrivedCallback;
	
	return elevator;
}

setupDoor( doorName, isRightSide, moveDistance )
{
	door = GetEnt( doorName, "targetname" );
	if (IsDefined(door))
	{
		door.closePos = door.origin;
		if (IsDefined(door.target))
		{
			targetStruct = getstruct( door.target, "targetname" );
			door.openPos = targetStruct.origin;
		}
		else
		{
			offset = AnglesToForward( door.angles ) * moveDistance;
			/*
			if (isRightSide)
			{
				offset *= -1;
			}
			*/
			door.openPos = door.origin + offset;
		}
		
		// door.unresolved_collision_func = ::handleUnreslovedCollision;
		
		return door;
	}
	else
	{
		AssertEx( IsDefined( door ), "Could not find an elevator door entity named " + doorName );
		return;
	}
}

setupButton( elevator )	// self == button
{
	self.owner = elevator;
	
	if ( IsDefined( self.target ) )
	{
		destination = getstruct( self.target, "targetname" ); 		
		self setupDestination( destination );
	}
	
	self enableButton();
}

setupDestination( destination )	// self == elevator
{
	
	if ( IsDefined( destination ) )
	{
		self.destinations[ destination.script_label ] = destination.origin;
		if ( IsDefined( destination.target ) )
		{
			blocker = GetEnt( destination.target, "targetname" );
			if ( IsDefined( blocker ) )
			{
				self.pathBlockers[ destination.script_label ] = blocker;
			}
		}
	}
}

enableButton()	// self == button
{
	self SetHintString( &"MP_ELEVATOR_USE" );
	self MakeUsable();
	
	self thread buttonThink();
}

disableButton()
{
	self MakeUnusable();
}

buttonThink()
{
	elevator = self.owner;
	elevator endon( "elevator_busy" );
	
	while ( true )
	{
		self waittill( "trigger" );
		
		if ( !IsDefined( self.script_label ) || self.script_label == "elevator" )
		{
			// do some stuff
			if ( elevator.curFloor == elevator.destinationNames[0] )
			{
				elevator.requestedFloor = elevator.destinationNames[1];
			}
			else
			{
				elevator.requestedFloor = elevator.destinationNames[0];
			}
		}
		else
		{
			elevator.requestedFloor = self.script_label;
		}
		
		elevator notify( "elevator_called" );
	}
}

elevatorThink()
{
	hasDoors = self.doors.size > 0;
	
	while ( true )
	{
		self waittill( "elevator_called" );
		
		foreach ( button in self.buttons )
		{
			button disableButton();
		}
		
		if ( self.curFloor != self.requestedFloor )
		{
			if ( self.doorState != ELEVATOR_DOOR_STATE_CLOSED )
			{
				self notify ("elevator_stop_autoclose");
				self thread closeElevatorDoors( self.curFloor );
				self waittill( "elevator_doors_closed" );
			}
			else if ( !hasDoors )
			{
				self elevatorBlockPath( self.curFloor );
			}
			
			self elevatorMoveToFloor( self.requestedFloor );
			wait (0.25);
		}
		
		if ( hasDoors )
		{
			self thread openElevatorDoors( self.curFloor, false );
			self waittill ( "elevator_doors_open" );
		}
		else
		{
			self elevatorClearPath( self.curFloor );
		}
		
		foreach ( button in self.buttons )
		{
			button enableButton();
		}
	}
}

elevatorMoveToFloor( targetFloor )
{
	//self PlaySound( self.startSfx );
	//self PlayLoopSound( self.loopSfx );
	
	destinationPos = self.destinations[ targetFloor ];
	deltaZ = destinationPos[2] - self.origin[2];	// may need to change this to full vector later
	
	if ( IsDefined( self.doors[ "elevator" ] ) )
	{
		// move doors
		foreach ( door in self.doors[ "elevator" ] )
		{
			door MoveZ( deltaZ, self.moveTime );
		}
	}
	
	// move the floor
	self MoveZ( deltaZ, self.moveTime );
	
	if ( IsDefined( self.onMoveCallback ) )
	{
		self thread [[ self.onMoveCallback ]]( targetFloor );
	}
	
	wait ( self.moveTime );
	
	//self StopLoopSound ( self.loopSfx );	
	//self PlaySound ( self.stopSfx );
	if ( IsDefined( self.beepSfx ) )
		self PlaySound ( self.beepSfx );
	
	self.curFloor = self.requestedFloor;
	
	if ( IsDefined( self.onArrivedCallback ) )
	{
		self thread [[ self.onArrivedCallback ]]( self.curFloor );
	}
}

openElevatorDoors( floorName, autoClose )	// elevator
{
	doorset = self.doors[ floorName ];
	
	self.doorState = ELEVATOR_DOOR_STATE_OPENING;
	
	// figre out the time it takes to move 1 door, assume it's the same fo rall
	door = doorset[0];
	doorDest = (door.openPos[0], door.openPos[1], door.origin[2]);
	moveDelta = doorDest - door.origin;
	moveDist = Length( moveDelta );
	
	// this might move 0 time / 0 dist
	// but we need it to counteract the closing elevator
	// wish I could just tell it to stop, instead
	movetime = moveDist / self.doorSpeed;
	accelTime = 0.25;
	if (moveTime == 0.0)
	{
		moveTime = 0.05;
		accelTime = 0.0;
	}
	else
	{
		self PlaySound( self.doorOpenSfx );
		accelTime = min(accelTime, moveTime);
	}

	foreach ( door in doorset )
	{
		door MoveTo( (door.openPos[0], door.openPos[1], door.origin[2]), movetime, 0.0, accelTime );
	}
	wait ( movetime );
	
	self.doorState = ELEVATOR_DOOR_STATE_OPEN;
	
	self notify ( "elevator_doors_open" );
	
	self elevatorClearPath( floorName );
	
	if ( autoClose )
	{
		self thread elevatorDoorsAutoClose();
	}
}

closeElevatorDoors( floorName )
{
	self endon( "elevator_close_interrupted" );
	
	self thread watchCloseInterrupted( floorName );
	
	doorset = self.doors[ floorName ];
	
	self.doorState = ELEVATOR_DOOR_STATE_CLOSING;
	
	// figre out the time it takes to move 1 door, assume it's the same fo rall
	door = doorset[0];
	doorDest = (door.closePos[0], door.closePos[1], door.origin[2]);
	moveDelta = doorDest - door.origin;
	moveDist = Length( moveDelta );
	
	if ( moveDist != 0.0 )
	{
		movetime = moveDist / self.doorSpeed;
		foreach ( door in doorset )
		{
			// we assume the doors all begin closed,
			// so door.closePos should eventually be defined by the time we need it
			door MoveTo( (door.closePos[0], door.closePos[1], door.origin[2]), movetime, 0.0, 0.25 );
		}
		self PlaySound( self.doorCloseSfx );
		wait ( movetime );
	}
	
	self.doorState = ELEVATOR_DOOR_STATE_CLOSED;
	
	self elevatorBlockPath( floorName );
	
	self notify( "elevator_doors_closed" );
}

watchCloseInterrupted( floorName )
{
	// if the doors have closed successfully, we don't care any more
	self endon( "elevator_doors_closed" );
	
	// make sure there is nothing in the way now
	nothingBlocking = true;
	foreach ( character in level.characters )
	{
		if ( character isTouchingTrigger( self.trigBlock ) )
		{
			nothingBlocking = false;
			break;
		}
	}
	
	if ( nothingBlocking )
	{
		self.trigBlock waittill( "trigger" );
	}
	
	self notify( "elevator_close_interrupted" );
	
	self openElevatorDoors( floorName, true );
}

isTouchingTrigger( trigger ) // self == player
{
	return ( IsAlive( self ) && self IsTouching( trigger ) );
}

elevatorDoorsAutoClose()	// self == elevator
{
	self endon( "elevator_doors_closed" );
	self endon( "elevator_stop_autoclose" );
	
	wait ( self.autoCloseTimeout );
	
	self closeElevatorDoors( self.curFloor);
}

handleUnreslovedCollision( hitEnt )	// self == mover, hitEnt == player (usually)
{
	if ( !IsPlayer( hitEnt ) )
	{
		hitEnt DoDamage( 1000, hitEnt.origin, self, self, "MOD_CRUSH" );
	}
}

elevatorClearPath( floorName )	// self == elevator
{
	blocker = self.pathBlockers[ floorName ];
	if ( IsDefined( blocker ) )
	{
		blocker ConnectPaths();
		blocker Hide();
		blocker NotSolid();
	}
}

elevatorBlockPath( floorName )
{
	blocker = self.pathBlockers[ floorName ];
	if ( IsDefined( blocker ) )
	{
		blocker Show();
		blocker Solid();
		blocker DisconnectPaths();
	}
}