// ============================================================
//  assemblyareaagent.asl — Jason 3.3 + CArtAgO
//
//  lock_area(N) and unlock_area(N) are CArtAgO operations that
//  update area_locked_N on the artifact (used by GUI rendering).
//  The lockedAreaFor/2 coordination beliefs are still managed
//  locally in this agent via .send to keep the agent-side
//  area reservation protocol unchanged.
// ============================================================
{include("focus_factory.asl")}

// welder agents allowed to share areas with other welders
is_welder(weldingagent1).
is_welder(weldingagent2).

// A lock is granted if:
// 1) Agent already holds it, OR
// 2) Area is empty, OR
// 3) Requester is a welder and all current holders are welders.
can_lock(Ag, Area) :- lockedAreaFor(Ag, Area).
can_lock(Ag, Area) :- not lockedAreaFor(_, Area).
can_lock(Ag, Area) :- is_welder(Ag) & not (lockedAreaFor(Other, Area) & not is_welder(Other)).

!start.

+!start : true
<- !focus_factory;
   .print("Assembly Area Agent: ready.").

// ── Full area lock ────────────────────────────────────────────
@fullLock [atomic]
+!fullAreaLockFor(Agent)
    : factory_art_id(_)
    & can_lock(Agent, 1) & can_lock(Agent, 2) // implementatio of shared lock rule for welders
<- .print("Assembly Area Agent: locking full area for ", Agent);
   +lockedAreaFor(Agent, 1);
   +lockedAreaFor(Agent, 2);
   lock_area(1);
   lock_area(2);
   .send(Agent, tell, lockedArea(1));
   .send(Agent, tell, lockedArea(2));
   .print("Assembly Area Agent: locked for ", Agent).

+!fullAreaLockFor(Agent) : true
<- .print("Assembly Area Agent: cannot lock full area for ", Agent).

// ── Partial lock ──────────────────────────────────────────────
@partialLock [atomic]
+!lockAreaFor(Agent, Area)
    : factory_art_id(_)
    & can_lock(Agent, Area)
<- .print("Assembly Area Agent: locking sub-area ", Area, " for ", Agent);
   +lockedAreaFor(Agent, Area);
   lock_area(Area);
   .send(Agent, tell, lockedArea(Area));
   .print("Assembly Area Agent: locked sub-area ", Area, " for ", Agent).

+!lockAreaFor(Agent, Area) : true
<- .print("Assembly Area Agent: cannot lock sub-area ", Area, " for ", Agent).

// ── Full area unlock ──────────────────────────────────────────
@fullAreaUnlockFor [atomic]
+!fullAreaUnlockFor(Agent)
    : factory_art_id(_)
    & lockedAreaFor(Agent, 1) & lockedAreaFor(Agent, 2)
<- -lockedAreaFor(Agent, 1);
   -lockedAreaFor(Agent, 2);
   .send(Agent, untell, lockedArea(1));
   .send(Agent, untell, lockedArea(2));
   if (not lockedAreaFor(_, 1)) { unlock_area(1); }
   if (not lockedAreaFor(_, 2)) { unlock_area(2); }.

+!fullAreaUnlockFor(Agent).

// ── Partial unlock ────────────────────────────────────────────
@unlockAreaFor [atomic]
+!unlockAreaFor(Agent, Area)
    : factory_art_id(_) & lockedAreaFor(Agent, Area)
<- -lockedAreaFor(Agent, Area);
   .send(Agent, untell, lockedArea(Area));
   if (not lockedAreaFor(_, Area)) { unlock_area(Area); }.

+!unlockAreaFor(Agent, Area).
