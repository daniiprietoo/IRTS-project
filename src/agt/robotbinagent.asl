// ============================================================
//  robot_bin_agent.asl
//  Dynamic workers that poll all bins and occasionally break.
// ============================================================
{include("focus_factory.asl")}

// Utility rule: map factory properties to local beliefs
binfull(1) :- bin_1(true).
binfull(2) :- bin_2(true).
binfull(3) :- bin_3(true).
binfull(4) :- bin_4(true).
binfull(5) :- bin_5(true).
binfull(6) :- bin_6(true).

// define explicit bins that this agent can work on, so jason's logic works properly
valid_bin(1). valid_bin(2). valid_bin(3). 
valid_bin(4). valid_bin(5). valid_bin(6).

!start.

+!start : true
<- !focus_factory;
   .my_name(Agent);
   .print(Agent, " has started, ready to start ANY bin.");
   !work.

// All bins are full
+!work : binfull(1) & binfull(2) & binfull(3) & 
         binfull(4) & binfull(5) & binfull(6)
<- .wait(1000);
    !work.

// There is a bin that is not full, try to work on it
+!work : valid_bin(N) & not binfull(N)
<- .my_name(Agent);
    .print(Agent, " is refilling bin ", N, ".");

    .wait(1500);

    // Breakdown logic: 10% chance of breakdown when refilling
    Roll = math.random;
    if (Roll < 0.1) {
        .print(Agent, " BROKE DOWN while refilling bin ", N, "!");
        .wait(5000);
    }

    // in case the bin has been filled by another agent while waiting/repairing, check again
    if (not binfull(N)) {
        refill_bin(N);  // CArtAgO operation on factory_env
        .print(Agent, " has refilled bin ", N, ".");
    } else {
        .print(Agent, " found bin ", N, " already refilled by someone else.");
    }

    !work.

// fallback when starting and factory is not set up yet
+!work: true
<- .wait(1000);
   !work.
