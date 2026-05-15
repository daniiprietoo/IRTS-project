package factory;

import cartago.*;

public class ArmArtifact extends Artifact {

    private FactoryModel model;

    void init() {
        model = FactoryModel.getInstance();
        defineObsProperty("gripper", 270, 613, 90);
    }

    @OPERATION
    void pick_part(String ag, int partnum) {
        model.pickPart(ag, partnum);
        try {
            ArtifactId boardId = this.lookupArtifact("assembly_board");
            this.execLinkedOp(boardId, "updateBinObs", partnum, false);
        } catch (Exception e) { e.printStackTrace(); }
        
        pushPosition();
    }

    @OPERATION
    void release_part(String ag) {
        model.releasePart(ag);
        pushPosition();
    }

    @OPERATION
    void move_towards(String ag, int x, int y, int angle) {
        model.moveTowards(ag, x, y, angle);
        pushPosition();
    }

    private void pushPosition() {
        updateObsProperty("gripper", model.gripperPosition[0], model.gripperPosition[1], model.gripperAngle);
    }

}