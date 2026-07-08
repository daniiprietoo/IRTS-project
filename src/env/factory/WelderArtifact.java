package factory;

import cartago.*;

public class WelderArtifact extends Artifact {

    private FactoryModel model;

    void init(String agentName) {
        model = FactoryModel.getInstance();
        int index = agentName.equals("weldingagent1") ? 0 : 1;
        defineObsProperty("welder_x", model.welderPositions[index][0]);
        defineObsProperty("welder_y", model.welderPositions[index][1]);
    }

    @OPERATION
    void weld(String agentName) {
        model.weld(agentName);
        pushPosition(agentName);
    }

    @OPERATION
    void move_towards(String ag, int x, int y, int angle) {
        model.moveTowards(ag, x, y, angle);
        pushPosition(ag);
    }

    private void pushPosition(String agentName) {
        int index = agentName.equals("weldingagent1") ? 0 : 1;
        updateObsProperty("welder_x", model.welderPositions[index][0]);
        updateObsProperty("welder_y", model.welderPositions[index][1]);
    }
}