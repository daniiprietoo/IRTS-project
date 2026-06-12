// ============================================================
//  human_bin_agent.asl
//  Included by bob, alice, tom, mary.
// ============================================================
{include("focus_factory.asl")}

binfull(1) :- bin_1(true).
binfull(2) :- bin_2(true).
binfull(3) :- bin_3(true).
binfull(4) :- bin_4(true).
binfull(5) :- bin_5(true).
binfull(6) :- bin_6(true).

!start.

+!start : true
    <- !focus_factory;
       .my_name(Agent);
       ?binnumber(N);
       ?quota(Q);
       .print(Agent, " started. Managing bin ", N, " with quota ", Q, ". Max buffer capacity: ", Q * 2, ".");
       
       // ensure period tracking beliefs are initialized
       -+period_start(0);
       -+bins_produced(0);
       -+buffer(0);
       
       // initialize state flags for clean logging
       -+waiting(false);
       -+buffer_full(false);
       -+reactivate(false);

       // start period tracking
       .time(H, M, S, Ms);
       StartMs = (H * 3600000) + (M * 60000) + (S * 1000) + Ms;
       -+period_start(StartMs);

       // Track period as parallel so it does not block the wait.
       !!track_period;
       !work.

// main plan for period tracking, every 80 seconds check if quota has been met, then reset counters and start new period.
+!track_period
   : true
<- 
    .wait(80000);
   .my_name(Agent);
   ?bins_produced(Produced);
   ?quota(Q);
   ?buffer(B);
   if (Produced < Q) {
      .print(Agent, " FAILED QUOTA. Produced ", Produced, "/", Q, " parts. (Buffered: ", B, ")");
   } else {
      .print(Agent, " MET QUOTA. Produced ", Produced, "/", Q, " parts. (Buffered: ", B, ")");
   }
   .time(H, M, S, Ms);
   TStart = (H * 3600000) + (M * 60000) + (S * 1000) + Ms;

   -+period_start(TStart);
   -+bins_produced(0);
   -+waiting(false); // Reset waiting state for the new shift
   .print(Agent, " starting new 80-second shift.");
   !track_period. // Start new period immediately.


// fallback plan if factory/agent is not fully initialized yet, wait and retry
+!work : not period_start(_) | not bins_produced(_) | not binnumber(_)
<- .wait(1000);
   !work.


// Plan to limit the activity to quota size and bin filled, and inform that the agent can now wait
+!work : binnumber(N) & binfull(N) & quota(Q) & bins_produced(Produced) & Produced >= Q & waiting(false)
<-  .my_name(Agent);
    .print(Agent, " reached base quota (", Q, ") and the bin is full. ", Agent, " is now waiting.");
    -+waiting(true);
    .wait(2000);
    !work.

+!work : binnumber(N) & binfull(N) & quota(Q) & bins_produced(Produced) & Produced >= Q & waiting(true)
<-  .wait(2000);
    !work.

// Plan to stop the production until buffer has free space
// Triggers if the buffer is full (Q * 2) and the bin is currently occupied.
+!work : quota(Q) & buffer(B) & B >= Q * 2 & buffer_full(false) & binnumber(N) & binfull(N)
<-  .my_name(Agent);
    .print(Agent, " buffer is FULL (", B, "/", Q * 2, "). Waiting for factory.");
    -+buffer_full(true);
    .wait(2000);
    !work.

// Plan to stop the production until buffer has free space (Already full: Wait silently)
// Wait silently while trapped.
+!work : quota(Q) & buffer(B) & B >= Q * 2 & buffer_full(true) & binnumber(N) & binfull(N)
<-  .wait(2000);
    !work.


// If the buffer has items and its time for the agent to decide, it uses the buffer items
+!work : binnumber(N) & not binfull(N) & buffer(B) & B > 0
<-  
    -+buffer(B - 1);
    -+buffer_full(false);
    .my_name(Agent);
    ?quota(Q);
    .print(Agent, " extracts a piece from the buffer to place it on the table (bin ", N, "). (Pieces still stored: ", B - 1, "/", Q * 2, ")");
    refill_bin(N);
    !work.


// Main work plan: check pace and work on it.
// El agente produce si no ha llegado a la cuota O si el bin está vacío.
+!work 
   : binnumber(N) & quota(Q) & bins_produced(Produced) & (Produced < Q | not binfull(N)) & period_start(TStart)
<-  
    // Si acaba de salir de waiting, configuramos el flag para evitar chatting
    if (waiting(true)) {
        -+waiting(false);
        -+reactivate(true);
    }

    .time(H, M, S, Ms);
    NowMs = (H * 3600000) + (M * 60000) + (S * 1000) + Ms;
    Elapsed = math.max(1, NowMs - TStart);

    TargetPace = Elapsed * Q;
    CurrentPace = Produced * 80000;

    .my_name(Agent);
    
    if (reactivate(true)) {
        // If the agent was waiting, it doesn't chat
        -+reactivate(false);
        .print(Agent, " was waiting, ",  Agent, " cannot chat (Producing part ", Produced + 1, ")");
        .wait(2000);
    } elif (CurrentPace >= TargetPace) {
        // Ahead of pace: human is bored, human chats
        ChatTime = 400 + (math.random * 400); // 0.4-0.8s
        TotalTime = 2000 + ChatTime;
        .print(Agent, " is AHEAD. Taking a break to chat (", Produced, "/", Q, ")");
        .wait(TotalTime);
    } else {
        // behind pace: human is stressed, works faster
        FastTime = 1000;
        .print(Agent, " is BEHIND. Working faster (", Produced, "/", Q, ")");
         .wait(FastTime);
    }

    // Fabricating a part finishes here. Decide where to put it.
    if (not binfull(N)) {
        // Bin is empty, goes directly to bin
        refill_bin(N); 
    } else {
        // Bin is full, goes to buffer
        ?buffer(B);
        -+buffer(B + 1);
        .print(Agent, " created a piece for bin ", N, " but ", Agent, " found the bin full or a robot placed a piece first");
        .print("The piece is stored in buffer. (Buffered: ", B + 1, "/", Q * 2, ")");
    }

    -+bins_produced(Produced + 1);

    !work.


// Plan to extract a piece from the buffer and put it into the bin if the bin is empty (Reactive / Interruption)

-bin_1(true) : binnumber(1) & buffer(B) & B > 0 <- !use_buffer(1, B).
-bin_2(true) : binnumber(2) & buffer(B) & B > 0 <- !use_buffer(2, B).
-bin_3(true) : binnumber(3) & buffer(B) & B > 0 <- !use_buffer(3, B).
-bin_4(true) : binnumber(4) & buffer(B) & B > 0 <- !use_buffer(4, B).
-bin_5(true) : binnumber(5) & buffer(B) & B > 0 <- !use_buffer(5, B).
-bin_6(true) : binnumber(6) & buffer(B) & B > 0 <- !use_buffer(6, B).

+!use_buffer(N, B)
<- 
    .drop_intention(work); 
    -+buffer(B - 1);
    -+buffer_full(false); 
    
    .my_name(Agent);
    ?quota(Q); 
    .print(Agent, " extracts a piece from the buffer to place it on the table (bin ", N, "). (Pieces still stored: ", B - 1, "/", Q * 2, ")");
    
    refill_bin(N);
    !work.