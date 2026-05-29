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
    .print(Agent, " started. Managing bin ", N, " with quota ", Q, ".");

   // ensure period tracking beliefs are initialized
    -+period_start(0);
   -+bins_produced(0);

   // start period tracking
   .time(H, M, S, Ms);
   StartMs = (H * 3600000) + (M * 60000) + (S * 1000) + Ms;
   -+period_start(StartMs);

    // Track period as parallel so it does not block the rest.
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

   if (Produced < Q) {
      .print(Agent, " FAILED QUOTA. Produced ", Produced, " parts.");
   } else {
      .print(Agent, " MET QUOTA. Produced ", Produced, " parts.");
   }

   .time(H, M, S, Ms);
   TStart = (H * 3600000) + (M * 60000) + (S * 1000) + Ms;

   -+period_start(TStart);
   -+bins_produced(0);
   .print(Agent, " starting new 80-second shift.");
   !track_period. // Start new period immediately.


// fallback plan if factory/agent is not fully initialized yet, wait and retry
+!work : not period_start(_) | not bins_produced(_) | not binnumber(_)
<- .wait(1000);
   !work.


// Wait if bin is full
+!work : binfull(N) & binnumber(N)
<- .wait(1000);
    !work.

// Main work plan: if my bin is not full, check pace and work on it.
+!work
   : binnumber(N) & not binfull(N) & quota(Q) & bins_produced(Produced) & period_start(TStart)
<-  .time(H, M, S, Ms);
    NowMs = (H * 3600000) + (M * 60000) + (S * 1000) + Ms;
    Elapsed = math.max(1, NowMs - TStart);

    TargetPace = Elapsed * Q;
    CurrentPace = Produced * 80000;

    .my_name(Agent);
    if (CurrentPace >= TargetPace) {
        // Adead of pace: human is bored, human chats, becomes less efficient (longer wait time)
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

    refill_bin(N); // CArtAgO operation on factory_env

    -+bins_produced(Produced + 1);

    !work.
