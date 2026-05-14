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

// Soft-goal retry for welder percept
+?welder(X, Y) : true
  <- ?welder(X, Y).

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

holdersReleased(N) :- not holding(N) & (N = 1 | holdersReleased(N-1)).
holdersReleased    :- holders(N) & holdersReleased(N).

!main.

+!main : true
<- !focus_factory;
   .print("Welding robot: waiting for new parts");
   !weldParts.

+!weldParts : joint(_) & holdersReleased
<- !forgetJoints; !weldParts.

// +!weldParts : jointPartsInPlace(1) & not joint(1) & not lockedArea(2)
// <- .print("Welding robot: requesting area 2.");
//    .my_name(Agent);
//    .send(assemblyareaagent, achieve, lockAreaFor(Agent, 2));
//    .send(assemblyareaagent, achieve, unlockAreaFor(Agent, 1));
//    .wait(200);
//    !weldParts.

+!weldParts : jointPartsInPlace(Joint) & not joint(Joint) & jointInArea(Joint, A) & not lockedArea(A) 
   <- .print("Welding robot: requesting area ", A, " for joint ", Joint, ".");
      .my_name(Agent);
      .send(assemblyareaagent, achieve, lockAreaFor(Agent, A));
      .wait(1000);
      !weldParts.

+!weldParts : jointPartsInPlace(Joint) & not joint(Joint) & jointInArea(Joint, A) & lockedArea(A)
   <- .print("Welding robot: welding joint ", Joint, " in area ", A, ".");
      .drop_intention(parkArm);
      ?jointPos(Joint, X, Y);
      !moveTo(X, Y);
      weld;                           // CArtAgO operation
      +joint(Joint);
      .broadcast(tell, joint(Joint));
      !!parkArm;
      !weldParts.


// +!weldParts : (Joint = 1 & jointPartsInPlace(Joint) & not joint(Joint) & lockedArea(2)) |
//               (Joint > 1 & jointPartsInPlace(Joint) & not joint(Joint) & lockedArea(1) & lockedArea(2))
// <- .print("Welding robot: welding joint ", Joint);
//    .drop_intention(parkArm);
//    ?jointPos(Joint, X, Y);
//    !moveTo(X, Y);
//    weld;                           // CArtAgO operation
//    +joint(Joint);
//    .broadcast(tell, joint(Joint));
//    !!parkArm;
//    !weldParts.

// +!weldParts : Joint > 1 & jointPartsInPlace(Joint) & not joint(Joint)
//             & (not lockedArea(1) | not lockedArea(2))
// <- .print("Welding robot: requesting areas 1 and 2.");
//    .my_name(Agent);
//    .send(assemblyareaagent, achieve, fullAreaLockFor(Agent));
//    .wait(200);
//    !weldParts.

+!weldParts : true
<- .wait(200);
   !weldParts.

+!forgetJoints : joint(N)
<- -joint(N);
   .broadcast(untell, joint(N));
   !forgetJoints.

+!forgetJoints.

// Movement
+!moveTo(X, Y) : not welder(X, Y)
  <- move_towards("weldingagent", X, Y, 0);
     !moveTo(X, Y).

+!moveTo(X, Y) : welder(X, Y).

// Park arm
+!parkArm : waitingposition(X, Y) & not welder(X, Y)
<- !moveTo(X, Y); !parkArm.

// Bug fix: bind X,Y before moveTo (were unbound in Jason 2.x version)
+!parkArm : lockedArea(Area)
<- ?waitingposition(X, Y);
   !moveTo(X, Y);
   .print("Welding arm: releasing lock from area ", Area);
   .my_name(Agent);
   .send(assemblyareaagent, achieve, unlockAreaFor(Agent, Area));
   .wait(200);
   !parkArm.

+!parkArm.
