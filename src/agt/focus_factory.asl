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
<- .print("[", .my_name, "] Looking up assembly_board...");
   lookupArtifact("assembly_board", BoardId);
   focus(BoardId);
   +factory_art_id(BoardId); // Mantenemos el nombre antiguo para no romper tus guards
   .print("[", .my_name, "] Focus on assembly_board OK.").

+!focus_factory : factory_art_id(_).

-!focus_factory : true
<- .print("[", .my_name, "] assembly_board not ready, retrying...");
   .wait(500);
   !focus_factory.