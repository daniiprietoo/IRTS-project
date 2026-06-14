// ============================================================
//  movingagent.asl — Jason 3.3 + CArtAgO
// ============================================================
{include("focus_factory.asl")}

waitingposition(500, 70).
framestockposition(-400, 300).

// Soft-goal retry for mover percept
+?mover(X, Y) : true
  <- ?mover(X, Y).

holdersReleased(N) :- not holding(N) & (N = 1 | holdersReleased(N-1)).
holdersReleased    :- holdersReleased(6).

jointDone(N)       :- joint(N) & (N = 1 | jointDone(N-1)).
weldingCompleted   :- joints(N) & jointDone(N).

!start.

+!start : true
<- !focus_factory;   
   makeArtifact("mover_tool", "factory.MoverArtifact", [], MoverId);
   focus(MoverId);
   +mover_art_id(MoverId);
   .print("Moving robot: waiting for finished frame");
   !removeFrame.

// Request FULL lock
+!removeFrame : weldingCompleted 
              & not lockedArea(1) & not lockedArea(2)
              & not my_lock(_) 
   <- .print("Moving robot: requesting FULL lock (areas 1 & 2).");
      .my_name(Me);
      +my_lock(full); 
      .send(assemblyareaagent, achieve, fullAreaLockFor(Me));
      .wait(1000);
      !removeFrame.

// Denied lock handler
+!removeFrame : weldingCompleted & my_lock(full) & (not lockedArea(1) | not lockedArea(2))
   <- .print("Moving robot: Factory denied FULL lock. Retrying...");
      -my_lock(full);
      .wait(500);
      !removeFrame.

// Execute move 
+!removeFrame : weldingCompleted & lockedArea(1) & lockedArea(2) & my_lock(full)
<- .print("Moving robot: moving finished frame away.");
   !pickFrame;
   !moveAway;
   !removeFrame.

+!removeFrame : not weldingCompleted
<- .wait(200); !removeFrame.

+!pickFrame : true
<- ?partPos(4, X, Y, _);
   !moveTo(X, Y);
   pick_part("movingagent", 4);
   .broadcast(tell, mover(hold)).

+!moveAway : holdersReleased
<- ?framestockposition(X2, Y2);
   !moveTo(X2, Y2);
   release_part("movingagent");
   .broadcast(untell, mover(hold));
   !awaitUnlockArea;
   !parkArm.

+!moveAway : true
<- .wait(200); !moveAway.

+!moveTo(X, Y) : not mover(X, Y)
  <- move_towards("movingagent", X, Y, 0);
     !moveTo(X, Y).

+!moveTo(X, Y) : mover(X, Y).

+!parkArm : true
<- ?waitingposition(X, Y);
   !moveTo(X, Y).

// Safely unlock the areas
+!awaitUnlockArea : lockedArea(1) & lockedArea(2) & my_lock(full)
<- .print("Moving robot: giving way to others.");
   .my_name(Me);
   -my_lock(full);
   .send(assemblyareaagent, achieve, fullAreaUnlockFor(Me));
   .wait(200);
   !awaitUnlockArea.

+!awaitUnlockArea.
