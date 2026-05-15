package factory;

import cartago.*;

public class MoverArtifact extends Artifact {

    private FactoryModel model;

    void init() {
        model = FactoryModel.getInstance();
        defineObsProperty("mover", 500, 70);
    }

    @OPERATION
    void pick_part(String ag, int partnum) {
        model.pickPart(ag, partnum);
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
        updateObsProperty("mover", model.moverPosition[0], model.moverPosition[1]);
    }
}