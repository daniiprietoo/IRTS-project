# Assembly Factory — Jason 3.3 + CArtAgO

## Questions

- [ ] Impossible for humans to meet quotas, factory is too slow.


Modernised simulation of an assembly robot factory using
Jason 3.3 as the BDI runtime and CArtAgO 3.x as the
environment / artifact framework.

## Project structure

```
factory1.mas2j              ← Jason project file
src/
  agt/
    focus_factory.asl       ← shared include: lookupArtifact + focus
    binagent.asl
    holdingagent.asl
    roboticarmagent.asl     ← creates the artifact at startup
    weldingagent.asl
    movingagent.asl
    assemblyareaagent.asl
  env/
    factory/
      FactoryArtifact.java  ← CArtAgO artifact (replaces fac1env.java)
bin/                        ← compiled .class files go here
```

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

## Key design decisions

### Why `roboticarmagent` creates the artifact

Jason 3.3 with `cartago.CartagoEnvironment` does not support
workspace declarations in the `.mas2j` file (that is a JaCaMo
feature). Instead, one agent calls `makeArtifact` and all
others call `lookupArtifact` with a retry loop:

```
// In roboticarmagent.asl
makeArtifact("factory_env", "factory.FactoryArtifact", [], ArtId);
focus(ArtId);

// In every other agent (via focus_factory.asl include)
+!focus_factory : true
<- lookupArtifact("factory_env", ArtId); focus(ArtId).
-!focus_factory : true          // failure handler = retry
<- .wait(300); !focus_factory.
```

### Observable properties replace percepts

| Old (Jason 2.x Environment) | New (CArtAgO artifact) |
|------------------------------|------------------------|
| `addPercept("gripper(X,Y,A)")` | `updateObsProperty("gripper", X, Y, A)` |
| `removePercept(...)` | (automatic on update) |
| `informAgsEnvironmentChanged()` | (automatic) |

Agents that call `focus(ArtId)` automatically receive observable
property changes as Jason beliefs. No polling needed.

### binfull(N) compatibility rule

Instead of changing every plan that uses `binfull(N)`, each
bin agent defines a derivation rule:

```agentspeak
binfull(1) :- bin_1(true).
binfull(2) :- bin_2(true).
// ...
```

This maps the CArtAgO observable properties `bin_1(Bool)`..`bin_6(Bool)`
to the original belief form, keeping all other agent code unchanged.

### CArtAgO operations (no dispatcher needed)

Each environment action is now a dedicated `@OPERATION` method.
Agents call them by name once they have focused on the artifact:

```agentspeak
move_towards(X, Y, 0).   // calls FactoryArtifact.move_towards(x,y,0)
pick_part(Part).          // calls FactoryArtifact.pick_part(partnum)
refill_bin(N).            // calls FactoryArtifact.refill_bin(binnum)
```

No `executeAction` switch-case and no `Environment` subclass needed.
