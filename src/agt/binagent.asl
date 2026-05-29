// ============================================================
//  binagent.asl — Jason 3.3 + CArtAgO
//
//  Changes from Jason 2.x:
//   1. !focus_factory (lookupArtifact + focus with retry).
//   2. binfull(N) derived from obs. property bin_N(true).
//   3. math.random(X) instead of .random(X).
//   4. refill_bin(N) is a CArtAgO operation (no extra annotation).
// ============================================================
{include("focus_factory.asl")}

timer(25000).

binnumber(5, binagent1).
binnumber(6, binagent2).

// binfull(N) derived from CArtAgO observable properties bin_1..bin_6
binfull(1) :- bin_1(true).
binfull(2) :- bin_2(true).
binfull(3) :- bin_3(true).
binfull(4) :- bin_4(true).
binfull(5) :- bin_5(true).
binfull(6) :- bin_6(true).

!start.

// Reactive: bin became empty — refill it
// -binfull(N) : binnumber(N) & factory_art_id(_)
//     <- !refill.

+!start : true
<- !focus_factory;
   .my_name(Agent);
   ?binnumber(N, Agent);
   +binnumber(N);
   .print("Bin agent ", N, " started.");
   !refill.

+!refill : not binnumber(_)
<- .print("Bin agent: no bin number assigned, cannot refill.");
   .wait(1000);
   !refill.

// Reactive: bin became full — wait for it to be emptied
+!refill : binnumber(N) & binfull(N)
   <- .wait(1000);
      !refill.

+!refill : binnumber(N) & timer(T) & not binfull(N)
<- // math.random used as arithmetic expression (not as action)
   // to avoid CArtAgO intercepting it as an artifact operation.
   WaitTime = math.random * T;
   .print("Bin agent ", N, " waiting ", WaitTime div 1000, " s for new parts...");
   .wait(WaitTime);
   .print("Bin agent ", N, " has received new parts.");
   refill_bin(N);        // CArtAgO operation on factory_env
   !refill.
