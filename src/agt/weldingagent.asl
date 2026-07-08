// ============================================================
//  weldingagent.asl — Jason 3.3 + CArtAgO
//
//  Changes from Jason 2.x:
//   1. !focus_factory (lookupArtifact + focus with retry).
//   2. move_towards and weld are CArtAgO operations.
//   3. Area locking is handled per joint area; no full-area lock
//      is requested by this agent anymore.
// ============================================================
{include("focus_factory.asl")}

welder(X, Y) :- welder_x(X) & welder_y(Y).

// Which parts must be in place for each joint
jointPartsInPlace(1) :- holding(1) & holding(2) & holding(3).
jointPartsInPlace(2) :- holding(2) & holding(4).
jointPartsInPlace(3) :- holding(3) & holding(4) & holding(6).
jointPartsInPlace(4) :- holding(4) & holding(5).
jointPartsInPlace(5) :- holding(5) & holding(6).

// Joints 1-3 in area 1, joints 4-5 in area 2
jointInArea(1, 1).
jointInArea(2, 1).
jointInArea(3, 1).
jointInArea(4, 2).
jointInArea(5, 2).

// Fixed ownership so welders never choose the same joint
welder_id(weldingagent1, 1).
welder_id(weldingagent2, 2).

joint_owner(1, 1).
joint_owner(3, 1).
joint_owner(5, 1).

joint_owner(2, 2).
joint_owner(4, 2).

holdersReleased(N) :- not holding(N) & (N = 1 | holdersReleased(N-1)).
holdersReleased    :- holders(N) & holdersReleased(N).

!main.

// Separate waiting positions per welder
+!set_waiting_pos(weldingagent1) <- +waitingposition(1000, 470).
+!set_waiting_pos(_)             <- +waitingposition(1060, 470).

+!set_welder_id(weldingagent1) <- +welder_id(1).
+!set_welder_id(_)             <- +welder_id(2).

+!main : true
<- !focus_factory;
   .my_name(Me);
   !set_waiting_pos(Me);
   !set_welder_id(Me);
   makeArtifact(Me, "factory.WelderArtifact", [Me], WelderId);
   focus(WelderId);
   +welder_art_id(WelderId);
   .print("Welding robot: waiting for new parts");
   !weldParts.

// Reset at end of frame
+!weldParts : joint(_) & holdersReleased
<- !forgetJoints;
   !weldParts.

// Select any joint that is ready, not done, and not targeted by another welder
+!weldParts : jointPartsInPlace(Joint)
            & not joint(Joint)
            & not targeted_joint(Joint)
            & not my_target(_)
  <- 
     .wait(math.random * 1000); // Random wait to avoid collisions
     if (not joint(Joint) & not targeted_joint(Joint)) {
       +my_target(Joint);
       +targeted_joint(Joint);
       .broadcast(tell, targeted_joint(Joint)); // Claim the joint globally
       .print("Welding robot: selected joint ", Joint, " to weld.");
       !weldParts;
     } else {
       !weldParts;
     }.

// If another agent targeted the same joint and my name is weldingagent1, yield to weldingagent2
+targeted_joint(Joint)[source(Other)] : my_target(Joint) & .my_name(Me) & Me = weldingagent1 & Other = weldingagent2
  <- .print("Welding robot: yielding target joint ", Joint, " to ", Other);
     -my_target(Joint);
     -targeted_joint(Joint);
     !parkArm;
     !weldParts.

// If someone else welded our current target already, drop it
+!weldParts : my_target(Joint) & joint(Joint)
  <- .print("Welding robot: target joint ", Joint, " already welded. Dropping target.");
     -my_target(Joint);
     !weldParts.


// -------- Lock plans --------

// Request area lock
+!weldParts : my_target(Joint) & not joint(Joint)
              & jointInArea(Joint, A)
              & not my_lock(A)
<- .print("Welding robot: requesting area ", A, " for joint ", Joint, ".");
   .my_name(Me);
   +my_lock(A);
   .send(assemblyareaagent, achieve, lockAreaFor(Me, A));
   .wait(1000);
   !weldParts.

// Area lock denied/retry
+!weldParts : my_target(Joint) & not joint(Joint)
              & jointInArea(Joint, A)
              & my_lock(A) & not lockedArea(A)
<- .print("Welding robot: factory denied lock for area ", A, ". Retrying...");
   -my_lock(A);
   .wait(500);
   !weldParts.

// weld with area lock
+!weldParts : my_target(Joint) & not joint(Joint)
              & jointInArea(Joint, A)
              & lockedArea(A)
              & my_lock(A)
<- .print("Welding robot: welding joint ", Joint, " in area ", A, ".");
   .drop_intention(parkArm);
   ?jointPos(Joint, X, Y);
   !moveTo(X, Y);
   .my_name(Me);
   weld(Me);
   +joint(Joint);
   -my_target(Joint);
   -targeted_joint(Joint);
   .broadcast(tell, joint(Joint));
   .broadcast(untell, targeted_joint(Joint));
   !!parkArm;
   !weldParts.

+!weldParts : true
<- .wait(200);
   !weldParts.

//  cleanup
+!forgetJoints : joint(N)
<- .abolish(joint(N));
   .abolish(my_target(N));
   .abolish(targeted_joint(N));
   .broadcast(untell, joint(N));
   .broadcast(untell, targeted_joint(N));
   !forgetJoints.

+!forgetJoints.

// Movement
+!moveTo(X, Y) : not welder(X, Y)
<- .my_name(Me);
   move_towards(Me, X, Y, 0);
   !moveTo(X, Y).

+!moveTo(X, Y) : welder(X, Y).

// Park arm
+!parkArm : waitingposition(X, Y) & not welder(X, Y)
<- !moveTo(X, Y);
   !!parkArm.

// Park and release area lock
+!parkArm : lockedArea(Area) & my_lock(Area)
<- ?waitingposition(X, Y);
   !moveTo(X, Y);
   .print("Welding arm: releasing lock from area ", Area);
   .my_name(Me);
   -my_lock(Area);
   .send(assemblyareaagent, achieve, unlockAreaFor(Me, Area));
   .wait(200);
   !parkArm.

+!parkArm.
