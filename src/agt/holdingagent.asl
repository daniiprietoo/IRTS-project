// ============================================================
//  holdingagent.asl — Jason 3.3 + CArtAgO
// ============================================================
{include("focus_factory.asl")}

holdernumber(1, holdingagent1).
holdernumber(2, holdingagent2).
holdernumber(3, holdingagent3).
holdernumber(4, holdingagent4).
holdernumber(5, holdingagent5).
holdernumber(6, holdingagent6).

!start.

// Part placed into this holder
+part_in_place(N) : holdernumber(N) & factory_art_id(_)
<- .print("Holding agent ", N, ": fixing part.");
   hold_part(N);                     // CArtAgO operation
   .broadcast(tell, holding(N)).

// Mover has gripped the assembled frame — release hold
+mover(hold) : holdernumber(N) & factory_art_id(_)
<- .print("Holding agent ", N, ": releasing part.");
   unhold_part(N);                   // CArtAgO operation
   .broadcast(untell, holding(N)).

+!start : true
<- !focus_factory;
   .my_name(Agent);
   ?holdernumber(N, Agent);
   +holdernumber(N);
   .print("Holding agent ", N, ": ready, waiting for part...").
