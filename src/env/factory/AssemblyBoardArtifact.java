package factory;

import cartago.*;
import javax.swing.SwingUtilities;

public class AssemblyBoardArtifact extends Artifact {

    private FactoryModel model;

    void init() {
        model = FactoryModel.getInstance();

        // 1. Iniciar la Interfaz Gráfica una sola vez
        SwingUtilities.invokeLater(() -> new FactoryView());

        // 2. Propiedades observables estáticas y generales
        defineObsProperty("bins",    FactoryModel.BINS);
        defineObsProperty("parts",   FactoryModel.PARTS);
        defineObsProperty("holders", FactoryModel.HOLDERS);
        defineObsProperty("joints",  FactoryModel.JOINTS);

        defineObsProperty("area_locked_1", false);
        defineObsProperty("area_locked_2", false);

        for (int i = 1; i <= FactoryModel.BINS; i++) {
            defineObsProperty("bin_" + i, false);
        }

        for (int i = 0; i < FactoryModel.PARTS; i++) {
            defineObsProperty("partLength", i+1, FactoryModel.PART_LENGTHS[i]);
            defineObsProperty("holderPos",  i+1, FactoryModel.HOLDER_POS[i][0], FactoryModel.HOLDER_POS[i][1]);
            defineObsProperty("partPos",    i+1, FactoryModel.PART_POS[i][0], FactoryModel.PART_POS[i][1], FactoryModel.PART_POS[i][2]);
            defineObsProperty("binPos",     i+1, FactoryModel.BIN_POS[i][0], FactoryModel.BIN_POS[i][1]);
        }
        for (int i = 0; i < FactoryModel.JOINTS; i++) {
            defineObsProperty("jointPos", i+1, FactoryModel.JOINT_POS[i][0], FactoryModel.JOINT_POS[i][1]);
        }
    }

    @OPERATION
    void hold_part(int partnum) {
        model.holdPart(partnum);
        signal("part_held", partnum);
    }

    @OPERATION
    void unhold_part(int partnum) {
        model.unholdPart(partnum);
        signal("part_unhold", partnum);
    }

    @OPERATION
    void lock_area(int area) {
        model.lockArea(area);
        updateObsProperty("area_locked_" + area, true);
    }

    @OPERATION
    void unlock_area(int area) {
        model.unlockArea(area);
        updateObsProperty("area_locked_" + area, false);
    }

    @OPERATION
    void refill_bin(int binnum) {
        model.refillBin(binnum);
        updateObsProperty("bin_" + binnum, true);
    }

    @LINK
    void updateBinObs(int partnum, boolean state) {
        updateObsProperty("bin_" + partnum, state);
    }
}