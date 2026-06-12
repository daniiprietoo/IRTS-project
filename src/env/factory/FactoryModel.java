package factory;

import java.util.Arrays;
    // ─────────────────────────────────────────────────────────
    //  FactoryModel — pure Java data model
    // ─────────────────────────────────────────────────────────
    public class FactoryModel {
        public static final int BINS    = 6;
        public static final int PARTS   = 6;
        public static final int HOLDERS = 6;
        public static final int JOINTS  = 5;
        public static final int AREAS   = 2;

        public static final int[] JOINT_AREA   = { 1, 1, 1, 2, 2 };

        public static final int[]   PART_LENGTHS =
            { 55, 410, 452, 256, 275, 167 };
        public static final int[][] HOLDER_POS   =
            { {910,210},{757,183},{785,270},{500,309},{422,309},{449,448} };
        public static final int[]   ARM_BASE     = { 600,  613 };
        public static final int[]   WELDER_BASE  = { 1000,  70 };
        public static final int[]   MOVER_BASE   = {  300,  70 };
        public static final int[][] BIN_POS      =
            { {270,538},{270,568},{270,598},{270,628},{270,658},{270,688} };
        public static final int[][] JOINT_POS    =
            { 
                {914,194}, // Joint 1 — Area 1 (upper-right)
                {501,197}, // Joint 2 — Area 1 (upper-center)
                {501,215}, // Joint 4 — Area 2 (lower-left)
                {534,460}, // Joint 3 — Area 1 (upper-center)
                {358,459}  // Joint 5 — Area 2 (lower-right)
            };

        public static final int[][] PART_POS     =
            { {917,198,344},{705,194,90},{727,328,55},
            {515,327,352},{428,335,30},{445,458,90} };

        private static FactoryModel instance;

        boolean[] binfull  = new boolean[BINS];
        int   gripperPart  = -1;
        int   gripperAngle = 90;
        boolean welding    = false;
        boolean moving     = false;
        boolean[] holding  = new boolean[HOLDERS];
        boolean[] joint    = new boolean[JOINTS];
        boolean[] lockArea = new boolean[AREAS];

        int[] gripperPosition = { 270, 613 };
        int[][] welderPositions = { {1000, 470}, {1060, 470} };
        int[] moverPosition   = { 500, 70 };

    private FactoryModel() {
        Arrays.fill(binfull,  false);
        Arrays.fill(holding,  false);
        Arrays.fill(joint,    false);
        Arrays.fill(lockArea, false);
    }

    public static synchronized FactoryModel getInstance() {
        if (instance == null) {
            instance = new FactoryModel();
        }
        return instance;
    }

        boolean anyHolding() {
            for (boolean h : holding) if (h) return true;
            return false;
        }

        synchronized void pickPart(String ag, int p) {
            if (ag.equals("movingagent")
                    && moverPosition[0] == PART_POS[3][0]
                    && moverPosition[1] == PART_POS[3][1]) {
                moving = true;
            } else if (ag.equals("roboticarmagent")
                    && gripperPosition[0] == BIN_POS[p-1][0]
                    && gripperPosition[1] == BIN_POS[p-1][1]) {
                gripperPart = p;
                binfull[p-1] = false;
            }
        }

        synchronized void releasePart(String ag) {
            if (ag.equals("roboticarmagent"))  gripperPart = -1;
            else if (ag.equals("movingagent")) { moving = false; Arrays.fill(joint, false); }
        }

    synchronized void weld(String ag) {
        int index = ag.equals("weldingagent1") ? 0 : 1;
        for (int i = 0; i < JOINTS; i++) {
            if (welderPositions[index][0] == JOINT_POS[i][0]
                    && welderPositions[index][1] == JOINT_POS[i][1]) {
                welding = true;
                try { Thread.sleep(5000); }
                catch (InterruptedException e) { Thread.currentThread().interrupt(); }
                joint[i] = true;
                welding  = false;
            }
        }
    }

        synchronized void moveTowards(String ag, int tx, int ty, int ta) {
            if (ag.equals("roboticarmagent")) {
                gripperPosition[0] = step(gripperPosition[0], tx);
                gripperPosition[1] = step(gripperPosition[1], ty);
                gripperAngle       = stepAngle(gripperAngle, ta);
            } else if (ag.equals("weldingagent1")) {
                welderPositions[0][0] = step(welderPositions[0][0], tx);
                welderPositions[0][1] = step(welderPositions[0][1], ty);
            } else if (ag.equals("weldingagent2")) {
                welderPositions[1][0] = step(welderPositions[1][0], tx);
                welderPositions[1][1] = step(welderPositions[1][1], ty);
            } else if (ag.equals("movingagent")) {
                moverPosition[0] = step(moverPosition[0], tx);
                moverPosition[1] = step(moverPosition[1], ty);
            }
            try { Thread.sleep(10); }
            catch (InterruptedException e) { Thread.currentThread().interrupt(); }
        }

        void refillBin(int x)    { binfull[x-1]    = true;  }
        void lockArea(int a)      { lockArea[a-1]   = true;  }
        void unlockArea(int a)    { lockArea[a-1]   = false; }
        void holdPart(int n)      { holding[n-1]    = true;  }
        void unholdPart(int n)    { holding[n-1]    = false; }

        private int step(int cur, int t) {
            return cur < t ? Math.min(t, cur+5) : cur > t ? Math.max(t, cur-5) : cur;
        }
        private int stepAngle(int cur, int t) {
            int d = ((t - cur) % 360 + 360) % 360;
            if (d == 0) return cur;
            return d <= 180 ? (cur+1)%360 : (cur-1+360)%360;
        }
    }

