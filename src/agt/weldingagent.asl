// ============================================================
//  weldingagent.asl — Jason 3.3 + CArtAgO
//
//  Changes from Jason 2.x:
//   1. !focus_factory (lookupArtifact + focus with retry).
//   2. move_towards and weld are CArtAgO operations.
//   3. Bug fixed: ?waitingposition(X,Y) added before !moveTo
//      in the lockedArea(Area) variant of +!parkArm.
// ============================================================
{include("focus_factory.asl")}

waitingposition(1000, 470).

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

joint_needs_full_lock(4).
joint_needs_full_lock(5).

holdersReleased(N) :- not holding(N) & (N = 1 | holdersReleased(N-1)).
holdersReleased    :- holders(N) & holdersReleased(N).

!main.

+!main : true
<- !focus_factory;
   .my_name(Me);
   makeArtifact(Me, "factory.WelderArtifact", [Me], WelderId);
   focus(WelderId);
   +welder_art_id(WelderId);
   .print("Welding robot: waiting for new parts");
   !weldParts.

+!weldParts : joint(_) & holdersReleased
<- !forgetJoints; !weldParts.

// Plan to claim a joint to weld
+!claimJoint(Joint)
  <- +my_target(Joint);
     .broadcast(tell, targeted_by_other(Joint)).

+!weldParts : jointPartsInPlace(Joint) & not joint(Joint) 
            & not my_target(Joint) & not targeted_by_other(Joint)
  <- !claimJoint(Joint);
     !weldParts.

// Plan to lock the target of the welder agent
+!weldParts : my_target(Joint) & not joint(Joint)
            & joint_needs_full_lock(Joint)
              & (not lockedArea(1) & not lockedArea(2))
   <- .print("Welding robot: requesting FULL lock (areas 1 & 2) for joint ", Joint, ".");
      .my_name(Me);
      .send(assemblyareaagent, achieve, fullAreaLockFor(Me));
      .wait(1000);
      !weldParts.

+!weldParts : my_target(Joint) & not joint(Joint)
            & joint_needs_full_lock(Joint)
              & lockedArea(2) & not lockedArea(1)
   <- .print("Welding robot: requesting lock (area 1) for joint ", Joint, " (area 2 already locked).");
      .my_name(Me);
      .send(assemblyareaagent, achieve, lockAreaFor(Me, 1));
      .wait(1000);
      !weldParts.

+!weldParts : my_target(Joint) & not joint(Joint)
            & joint_needs_full_lock(Joint)
              & lockedArea(1) & not lockedArea(2)
   <- .print("Welding robot: requesting lock (area 2) for joint ", Joint, " (area 1 already locked).");
      .my_name(Me);
      .send(assemblyareaagent, achieve, lockAreaFor(Me, 2));
      .wait(1000);
      !weldParts.

+!weldParts : my_target(Joint) & not joint(Joint)
              & jointInArea(Joint, A) & not joint_needs_full_lock(Joint)
              & not lockedArea(A)
   <- .print("Welding robot: requesting area ", A, " for joint ", Joint, ".");
      .my_name(Me);
      .send(assemblyareaagent, achieve, lockAreaFor(Me, A));
      .wait(1000);
      !weldParts.


// Execute weld with FULL lock
+!weldParts : my_target(Joint) & not joint(Joint)
              & joint_needs_full_lock(Joint)
              & lockedArea(1) & lockedArea(2)
   <- .print("Welding robot: welding joint ", Joint, " with FULL lock.");
      .drop_intention(parkArm);
      ?jointPos(Joint, X, Y);
      !moveTo(X, Y);
      .my_name(Me);
      weld(Me);
      +joint(Joint);
      -my_target(Joint);
      .broadcast(tell, joint(Joint));
      !!parkArm;
      !weldParts.

// Execute weld with PARTIAL lock
+!weldParts : my_target(Joint) & not joint(Joint)
              & jointInArea(Joint, A) & not joint_needs_full_lock(Joint)
              & lockedArea(A)
   <- .print("Welding robot: welding joint ", Joint, " in area ", A, ".");
      .drop_intention(parkArm);
      ?jointPos(Joint, X, Y);
      !moveTo(X, Y);
      .my_name(Me);
      weld(Me); // CArtAgO operation passing dynamic agent name
      +joint(Joint);
      -my_target(Joint);
      .broadcast(tell, joint(Joint));
      !!parkArm;
      !weldParts.

+!weldParts : true
<- .wait(200);
   !weldParts.


+!forgetJoints : joint(N)
<- -joint(N);
   -my_target(N);
   -targeted_by_other(N);
   .broadcast(untell, joint(N));
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
<- !moveTo(X, Y); !parkArm.

// Bug fix: bind X,Y before moveTo (were unbound in Jason 2.x version)
// Park and release FULL lock
+!parkArm : lockedArea(1) & lockedArea(2)
<- ?waitingposition(X, Y);
   !moveTo(X, Y);
   .print("Welding arm: releasing FULL lock (areas 1 & 2)");
   .my_name(Me);
   .send(assemblyareaagent, achieve, fullAreaUnlockFor(Me));
   .wait(200);
   !parkArm.

// Park and release PARTIAL lock
+!parkArm : lockedArea(Area)
<- ?waitingposition(X, Y);
   !moveTo(X, Y);
   .print("Welding arm: releasing lock from area ", Area);
   .my_name(Me);
   .send(assemblyareaagent, achieve, unlockAreaFor(Me, Area));
   .wait(200);
   !parkArm.

+!parkArm.
