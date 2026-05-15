package factory;

import cartago.*;

public class WelderArtifact extends Artifact {

    private FactoryModel model;

    void init() {
        model = FactoryModel.getInstance();
        defineObsProperty("welder", 1000, 470);
    }

    @OPERATION
    void weld() {
        model.weld();
        pushPosition();
    }

    @OPERATION
    void move_towards(String ag, int x, int y, int angle) {
        model.moveTowards(ag, x, y, angle);
        pushPosition();
    }

    private void pushPosition() {
        updateObsProperty("welder", model.welderPosition[0], model.welderPosition[1]);
    }
}