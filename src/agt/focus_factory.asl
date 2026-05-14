// ============================================================
//  focus_factory.asl — included by all agents except roboticarmagent
//
//  Provides !focus_factory that looks up the shared artifact
//  created by roboticarmagent, focuses on it and stores the
//  ArtId as a belief factory_art_id(ArtId).
//
//  Storing ArtId lets agents guard operations with:
//    : factory_art_id(_)   <-- ensures focus completed
//
//  The failure plan (-!focus_factory) retries every 500 ms
//  until roboticarmagent has created the artifact.
// ============================================================

+!focus_factory : not factory_art_id(_)
<- .print("[", .my_name, "] Looking up factory_env...");
   lookupArtifact("factory_env", ArtId);
   focus(ArtId);
   +factory_art_id(ArtId);
   .print("[", .my_name, "] Focused on factory_env OK.").

// Already focused — nothing to do
+!focus_factory : factory_art_id(_).

// Failure plan: artifact not yet created — wait and retry
-!focus_factory : true
<- .print("[", .my_name, "] factory_env not ready, retrying...");
   .wait(500);
   !focus_factory.
