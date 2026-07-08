# Assembly Factory - Group 4 UDC

- Fernando Baña Amigo
- Daniel Prieto Diaz
- Alejandro Silva Durán

Submission for the final project of the IRTS course of the MIA.

## Requirements

| Tool | Version |
|------|---------|
| Java | 17+ (OpenJDK recommended) |
| Jason | 3.3 (`jason-3.3.jar`) |
| CArtAgO | 3.x (`cartago-3.x.jar`) |

## Compile the artifact

```bash
mkdir -p bin
javac -cp jason-3.3.jar:cartago-3.x.jar \
      src/env/factory/FactoryArtifact.java \
      -d bin
```

On Windows replace `:` with `;` in the classpath:
```cmd
mkdir -p bin
javac -cp jason-3.3.jar;cartago-3.x.jar ^
      src\env\factory\FactoryArtifact.java ^
      -d bin
```

## Run

```bash
jason factory1.mas2j
```

Or with explicit classpath (if `jason` is not on PATH):
```bash
java -cp jason-3.3.jar:cartago-3.x.jar:bin \
     jason.infra.centralised.RunCentralisedMAS factory1.mas2j
```

---

## Summary of the changes for both tasks

The two tasks were implemented in order to satisfy the requirements of the project. The first task (common) was to implenment the human agents with quotas and leave only two robot agents which could refill any bins. The second task was to implement two welding agents that could work simultaneously on the same area.

### Task 1

Human agents can refill their assigned bins and have a quota to meet in a 80000 ms shift or period. If they are ahead of their pace they will take a break and chat, if they are behind they will work faster. In order to achieve this, given the limitations of the slow working speed of the factory to create new frames, we propse a solution with a buffer system that allows the human agents to store parts in a local buffer when their bin is full.

#### 1a. Human bin agents with quota & buffer system

**New files:** `humanbinagent.asl`, `bob.asl`, `alice.asl`, `tom.asl`,
`mary.asl`

Six original `binagent` instances were replaced by four human agents
(each with their own `binnumber` and `quota`) and two `robotbinagent`
instances (see below).

The human agents (`humanbinagent.asl`) work in 80 second shifts.
At the end of each shift it checks whether its quota was met:

```agentspeak
+!track_period : true
<- .wait(80000);
   ?bins_produced(Produced);
   ?quota(Q);
   if (Produced < Q) {
     .print(Agent, " FAILED QUOTA. Produced ", Produced, "/", Q, " parts.");
   } else {
     .print(Agent, " MET QUOTA. Produced ", Produced, "/", Q, " parts.");
   }
   -+period_start(TStart);
   -+bins_produced(0);
   !track_period.
```

Each human agent adjusts its work speed based on whether it is ahead of or behind its target pace, if they are ahead they will take a break and chat which is modeled as a random time between 400 and 800 ms added to the working time of 2 seconds. If they are behind they will work faster and the working time is reduced to 1 second.

```agentspeak
TargetPace = Elapsed * Q;
CurrentPace = Produced * 80000;
if (CurrentPace >= TargetPace) {
    // ahead → chat, take longer
    ChatTime = 400 + (math.random * 400);
    TotalTime = 2000 + ChatTime;
} else {
    // behind → work faster (1 s)
    FastTime = 1000;
}
```

When the bin is full the agent stores parts in a local buffer (capacity = `quota * 2`). Reactive plans(`-bin_N(true) : buffer(B) & B > 0`) empty the buffer into the bin as soon as space is available, even interrupting the main work intention via `.drop_intention(work)`.

#### 1b. Robot bin agents with breakdown mechanic

The second part of the task was to implment logic for the robot agents to be able to refill any bin and a breakdown mechanic that would make the robot agents stop working for 5 seconds with a 10% chance of breaking down when refilling a bin.

**New file:** `robotbinagent.asl` (2 instances)

These agents scan all bins and they have no bin assignment. They have a 10 % breakdown chance (`.wait(5000)` for repair):

```agentspeak
Roll = math.random;
if (Roll < 0.1) {
    .print(Agent, " BROKE DOWN while refilling bin ", N, "!");
    .wait(5000);
}
```

They check whether a bin was already refilled by another agent before acting, preventing redundant work.

### Task 2 — Two welders working simultaneously

The second task was to implment two welding agents so that they could work simultaneously on the same area. The main challenge was to avoid collisions when both welders tried to weld the same joint at the same time. The solution was to implement a dynamic claiming protocol with a random waits to break possible ties when both welders try to claim the same joint. The shared area lock agent was also modified so that both welders could hold the same area simultaneously, while the robotic arm and moving agent still get exclusive access.

#### 2a. Two welding agent instances

**`factory1.mas2j`:**

```diff
- weldingagent agentArchClass jaca.CAgentArch;
+ weldingagent #2 agentArchClass jaca.CAgentArch;
```

#### 2b. Individual welder state in `FactoryModel.java`

We switched from a single `welderPosition` to an array of two positions, and from a single `welding` boolean to a `welding[2]` array:

```java
int[][] welderPositions = { {1000, 470}, {1060, 470} };
boolean[] welding = {false, false};
```

The `weld()` and `moveTowards()` methods now use agents by name (`"weldingagent1"` → index 0, `"weldingagent2"` → index 1):

```java
void weld(String ag) {
    int index = ag.equals("weldingagent1") ? 0 : 1;
    // ... use welderPositions[index], welding[index]
}
```

To make it possible for both welders to weld simultaneously, the `weld()` method was refactored to only synchronise the joint-target detection and the final joint-marking, while the 5-second `Thread.sleep` runs outside the lock:

```java
synchronized (this) {
    // check if joint is already welded or targeted
    // mark joint as welded and update GUI
}
```

#### 2c. Individual agent `WelderArtifact.java`

The artifact now receives the agent name at initialisation. It exposes `welder_x` / `welder_y` as separate observable properties (instead of a composite `welder(X,Y)`) so each agent instance only sees its own position:

```java
void init(String agentName) {
    model = FactoryModel.getInstance();
    int index = agentName.equals("weldingagent1") ? 0 : 1;
    defineObsProperty("welder_x", model.welderPositions[index][0]);
    defineObsProperty("welder_y", model.welderPositions[index][1]);
}
```

#### 2d. Joint claiming protocol

We initially tried a deterministic assignment of joints to the welders, but we thought that this was not felxible enough and we wanted to still achieve a solution that implemented a dynamic claiming of the joints, meaning that both welders could claim any joint, but if one of them already claimed it, the other would yield and try again later.

**Early approach**

Using beliefs to assign the joints to each welder:

```agentspeak
joint_owner(1, 1).
joint_owner(3, 1).
joint_owner(5, 1).

joint_owner(2, 2).
joint_owner(4, 2).
```

Then we created plans to handle the claiming logic:

```agentspeak
// Select only the joints assigned to this welder
+!weldParts : welder_id(ID) & joint_owner(Joint, ID)
            & jointPartsInPlace(Joint)
            & not joint(Joint)
            & not my_target(_)
  <- +my_target(Joint);
     .print("Welding robot: selected joint ", Joint, " to weld.");
     !weldParts.

// If someone else welded our current target already, drop it
+!weldParts : my_target(Joint) & joint(Joint)
  <- .print("Welding robot: target joint ", Joint, " already welded. Dropping target.");
     -my_target(Joint);
     !weldParts.

```

Essentially this would meet the requirements of having two welders working simultaneously, even in the same area because joints 1,2,3 are in area 1 and joints 4,5 are in area 2. However, we thought that this was not a very flexible solution and we wanted to implement a more dynamic claiming of the joints.

**Final approach:** Dynamic claiming with a random wait to break ties between welders, also giving priority to welder2 by having welder1 yielding as a fallback plan.

```agentspeak
+!weldParts : jointPartsInPlace(Joint)
            & not joint(Joint)
            & not targeted_joint(Joint)
            & not my_target(_)
<- .wait(math.random * 1000); // Random backoff to break ties
   if (not joint(Joint) & not targeted_joint(Joint)) {
     +my_target(Joint);
     +targeted_joint(Joint);
     .broadcast(tell, targeted_joint(Joint));
     !weldParts;
   } ...
```

```agentspeak
+targeted_joint(Joint)[source(Other)]
   : my_target(Joint) & .my_name(Me)
     & Me = weldingagent1 & Other = weldingagent2
<- -my_target(Joint);
   -targeted_joint(Joint);
   !parkArm;
   !weldParts.
```

#### 2e. Shared-area lock fixes for simultaneous welding (`assemblyareaagent.asl`)

We refactored the are locking logic so that both welders can hold the same area simultaneously, while the robotic arm and moving agent still get exclusive access. The key rule is the following:

```prolog
is_welder(weldingagent1).
is_welder(weldingagent2).

can_lock(Ag, Area) :- lockedAreaFor(Ag, Area).              % already holds it
can_lock(Ag, Area) :- not lockedAreaFor(_, Area).           % empty
can_lock(Ag, Area) :- is_welder(Ag)                         % welder + all holders are welders
                    & not (lockedAreaFor(Other, Area)
                           & not is_welder(Other)).
```

This means that an agent can lock an area if it already holds it, if the area is empty, or if it is a welder and all current holders are welders.

#### 2f. `my_lock` area tracking for welders

Each welding agent now tracks `my_lock(full | Area)` to avoid re-sending lock requests for an area it already requested. Denied requests (because the factory couldn't grant) clear `my_lock` and retry after a short delay.

#### 2h. Visualisation (`FactoryView.java`)

Lastly we also modified the GUI a bit to show the unwelded joints in a darker shade of red, to make it easier to see where the joints are that still need to be weldeed.
