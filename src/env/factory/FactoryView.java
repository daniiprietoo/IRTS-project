package factory;

import cartago.*;
import javax.swing.*;
import java.awt.*;
import java.util.Random;

import static factory.FactoryModel.*;

// ─────────────────────────────────────────────────────────
//  FactoryView — Swing window (modernised rendering)
// ─────────────────────────────────────────────────────────
public class FactoryView {

    // Catppuccin Mocha palette
    static final Color BG        = new Color(0x1E, 0x1E, 0x2E);
    static final Color AREA_LOCK = new Color(0x31, 0x38, 0x4A);
    static final Color AREA_FREE = new Color(0x28, 0x2A, 0x3A);
    static final Color AREA_BDR  = new Color(0x45, 0x47, 0x5A);
    static final Color COL_ARM   = new Color(0x89, 0xB4, 0xFA);
    static final Color COL_WELD  = new Color(0xA6, 0xE3, 0xA1);
    static final Color COL_MOVE  = new Color(0xF3, 0x8B, 0xA8);
    static final Color COL_PART  = new Color(0xF9, 0xE2, 0xAF);
    static final Color COL_JOINT = new Color(0xEB, 0x6C, 0xBF);
    static final Color COL_H_ON  = new Color(0xA6, 0xE3, 0xA1);
    static final Color COL_H_OFF = new Color(0x45, 0x47, 0x5A);
    static final Color COL_B_FULL= new Color(0xCB, 0xA6, 0xF7);
    static final Color COL_B_EMP = new Color(0x31, 0x32, 0x44);
    static final Color TEXT      = new Color(0xCD, 0xD6, 0xF4);
    static final Color TEXT_DIM  = new Color(0x6C, 0x70, 0x86);
    static final Color GLOW      = new Color(0xFF, 0xA5, 0x00, 200);

    public FactoryView() {
        FactoryModel model = FactoryModel.getInstance();
        JFrame frame = new JFrame("Assembly Factory  —  Jason 3.3 + CArtAgO");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setLayout(new BorderLayout());
        frame.add(new Canvas(model), BorderLayout.CENTER);
        frame.add(statusBar(), BorderLayout.SOUTH);
        frame.setSize(1120, 800);
        frame.setLocationRelativeTo(null);
        frame.setVisible(true);
    }

    JPanel statusBar() {
        JPanel bar = new JPanel(new FlowLayout(FlowLayout.LEFT, 16, 4));
        bar.setBackground(new Color(0x18, 0x18, 0x2E));
        bar.setBorder(BorderFactory.createMatteBorder(1,0,0,0, AREA_BDR));
        JLabel lbl = new JLabel(
            "  Assembly Factory  |  Jason 3.3  +  CArtAgO 3.x");
        lbl.setForeground(TEXT_DIM);
        lbl.setFont(new Font("Monospaced", Font.PLAIN, 11));
        bar.add(lbl);
        return bar;
    }
}

// ─────────────────────────────────────────────────────────
//  Canvas — animated 2D scene
// ─────────────────────────────────────────────────────────
class Canvas extends JComponent {

    private final FactoryModel m;
    private final Random rng = new Random();

    Canvas(FactoryModel model) {
        this.m = model;
        Thread t = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                repaint();
                try { Thread.sleep(33); }
                catch (InterruptedException e) { Thread.currentThread().interrupt(); }
            }
        });
        t.setDaemon(true);
        t.start();
    }

    @Override
    protected void paintComponent(Graphics g) {
        Graphics2D g2 = (Graphics2D) g;
        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                            RenderingHints.VALUE_ANTIALIAS_ON);
        g2.setRenderingHint(RenderingHints.KEY_RENDERING,
                            RenderingHints.VALUE_RENDER_QUALITY);
        int W = getWidth(), H = getHeight();

        // Background + grid
        g2.setColor(FactoryView.BG);
        g2.fillRect(0, 0, W, H);
        g2.setColor(new Color(0x30, 0x30, 0x45, 70));
        g2.setStroke(new BasicStroke(0.5f));
        for (int x = 0; x < W; x += 40) g2.drawLine(x, 0, x, H);
        for (int y = 0; y < H; y += 40) g2.drawLine(0, y, W, y);

        drawAreas(g2);
        drawBins(g2);
        drawHolders(g2);
        drawJointsUnwelded(g2);
        drawJoints(g2, 0, 0);
        drawArm(g2);
        drawWelder(g2);
        drawMover(g2);
        drawLabels(g2);
    }

    // Assembly areas
    void drawAreas(Graphics2D g2) {
        // Area 1 -> upper, joints 1, 2, 3
        // Area 2 -> lower, joints 4, 5 
        int[][] areas = { {300,150,650, 200}, {300, 350, 650, 150} };
        for (int i = 0; i < AREAS; i++) {
            int[] a = areas[i];
            g2.setColor(m.lockArea[i] ? FactoryView.AREA_LOCK : FactoryView.AREA_FREE);
            g2.fillRoundRect(a[0], a[1], a[2], a[3], 8, 8);
            g2.setColor(FactoryView.AREA_BDR);
            g2.setStroke(new BasicStroke(1.5f));
            g2.drawRoundRect(a[0], a[1], a[2], a[3], 8, 8);
            g2.setColor(FactoryView.TEXT_DIM);
            g2.setFont(new Font("SansSerif", Font.PLAIN, 10));
            g2.drawString("AREA " + (i+1) +
                (m.lockArea[i] ? "  [LOCKED]" : ""), a[0]+6, a[1]+14);
        }
    }

    static int getJointArea(int jointNum) {
        if (jointNum < 1 || jointNum > JOINTS) throw new IllegalArgumentException("Invalid joint number");
        return JOINT_AREA[jointNum-1];
    }

    void drawJointsUnwelded(Graphics2D g2) {
        int[][] joints    =
            { 
                {914,194}, // Joint 1 — Area 1 (upper-right)
                {501,197}, // Joint 2 — Area 1 (upper-center)
                {501,215}, // Joint 4 — Area 2 (lower-left)
                {534,460}, // Joint 3 — Area 1 (upper-center)
                {358,459}  // Joint 5 — Area 2 (lower-right)
            };

        for (int i = 0; i < JOINTS; i++) {
            g2.setColor(m.joint[i] ? FactoryView.COL_JOINT : FactoryView.COL_JOINT.darker());
            g2.fillOval(joints[i][0]-10, joints[i][1]-10, 20, 20);
            g2.setColor(FactoryView.BG);
            g2.setStroke(new BasicStroke(1f));
            g2.drawOval(joints[i][0]-10, joints[i][1]-10, 20, 20);
            g2.setFont(new Font("SansSerif", Font.PLAIN, 9));
            g2.setColor(FactoryView.TEXT_DIM);
            g2.drawString("J" + (i+1),
                joints[i][0]+12, joints[i][1]+4);
        }
    }

    // Bin status strip
    void drawBins(Graphics2D g2) {
        for (int i = 0; i < BINS; i++) {
            int by = 495 + (i+1) * 30;
            g2.setColor(m.binfull[i] ? FactoryView.COL_B_FULL : FactoryView.COL_B_EMP);
            g2.fillRoundRect(5, by, 260, 24, 5, 5);
            g2.setColor(FactoryView.TEXT_DIM);
            g2.setStroke(new BasicStroke(0.8f));
            g2.drawRoundRect(5, by, 260, 24, 5, 5);
            g2.setColor(m.binfull[i] ? FactoryView.BG : FactoryView.TEXT_DIM);
            g2.setFont(new Font("Monospaced", Font.PLAIN, 11));
            g2.drawString(String.format("BIN %d  %s", i+1,
                m.binfull[i] ? "FULL" : "empty"), 13, by+16);
            if (m.binfull[i])
                paintPart(g2, i+1, 90, BIN_POS[i][0], BIN_POS[i][1], 0.5f);
        }
    }

    // Holder indicators
    void drawHolders(Graphics2D g2) {
        for (int i = 0; i < PARTS; i++) {
            if (m.holding[i])
                paintPart(g2, i+1, PART_POS[i][2],
                    PART_POS[i][0], PART_POS[i][1], 1f);
            g2.setColor(m.holding[i] ? FactoryView.COL_H_ON : FactoryView.COL_H_OFF);
            g2.fillOval(HOLDER_POS[i][0], HOLDER_POS[i][1], 20, 20);
            g2.setColor(FactoryView.TEXT_DIM);
            g2.setStroke(new BasicStroke(0.8f));
            g2.drawOval(HOLDER_POS[i][0], HOLDER_POS[i][1], 20, 20);
            g2.setFont(new Font("SansSerif", Font.PLAIN, 9));
            g2.drawString("H"+(i+1), HOLDER_POS[i][0]+24, HOLDER_POS[i][1]+13);
        }
    }

    // Welded joints
    void drawJoints(Graphics2D g2, int dx, int dy) {
        for (int i = 0; i < JOINTS; i++) {
            if (m.joint[i]) {
                g2.setColor(FactoryView.COL_JOINT);
                g2.fillOval(JOINT_POS[i][0]+dx-9, JOINT_POS[i][1]+dy-9, 18, 18);
                g2.setColor(FactoryView.BG);
                g2.setStroke(new BasicStroke(1f));
                g2.drawOval(JOINT_POS[i][0]+dx-9, JOINT_POS[i][1]+dy-9, 18, 18);
                g2.setFont(new Font("SansSerif", Font.PLAIN, 9));
                g2.setColor(FactoryView.TEXT_DIM);
                // Label joints according to their position not their index
                g2.drawString("J" + (i+1) + " (A" + getJointArea(i+1) + ")",
                    JOINT_POS[i][0]+dx+12, JOINT_POS[i][1]+dy+4);
            }
        }
    }

    // Robotic arm
    void drawArm(Graphics2D g2) {
        int bx=ARM_BASE[0], by=ARM_BASE[1];
        int ex=m.gripperPosition[0], ey=m.gripperPosition[1];
        // Cable
        g2.setColor(FactoryView.COL_ARM.darker());
        g2.setStroke(new BasicStroke(12, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g2.drawLine(bx, by, ex, ey);
        g2.setColor(FactoryView.COL_ARM);
        g2.setStroke(new BasicStroke(4));
        g2.drawLine(bx, by, ex, ey);
        // Base
        g2.setColor(FactoryView.COL_ARM.darker());
        g2.setStroke(new BasicStroke(10, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g2.drawLine(bx-30, by-30, bx+30, by+30);
        g2.drawLine(bx-30, by+30, bx+30, by-30);
        // Gripper end
        if (m.gripperPart < 0) {
            g2.setColor(FactoryView.COL_ARM);
            g2.fillOval(ex-9, ey-9, 18, 18);
        } else {
            paintPart(g2, m.gripperPart, m.gripperAngle, ex, ey, 1f);
            g2.setColor(FactoryView.COL_PART);
            g2.fillOval(ex-7, ey-7, 14, 14);
        }
    }

    // Welding robot
    void drawWelder(Graphics2D g2) {
        int bx=WELDER_BASE[0], by=WELDER_BASE[1];
        int ex=m.welderPosition[0], ey=m.welderPosition[1];
        g2.setColor(FactoryView.COL_WELD.darker());
        g2.setStroke(new BasicStroke(12, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g2.drawLine(bx, by, ex, ey);
        g2.setColor(FactoryView.COL_WELD);
        g2.setStroke(new BasicStroke(4));
        g2.drawLine(bx, by, ex, ey);
        g2.setColor(FactoryView.COL_WELD.darker());
        g2.setStroke(new BasicStroke(10, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g2.drawLine(bx-30, by-30, bx+30, by+30);
        g2.drawLine(bx-30, by+30, bx+30, by-30);
        // Weld glow
        if (m.welding && rng.nextBoolean()) {
            g2.setColor(FactoryView.GLOW);
            g2.fillOval(ex-20, ey-20, 40, 40);
        }
        g2.setColor(m.welding ? new Color(0xFF,0x50,0x10) : FactoryView.COL_WELD);
        g2.fillOval(ex-10, ey-10, 20, 20);
    }

    // Moving robot
    void drawMover(Graphics2D g2) {
        int bx=MOVER_BASE[0], by=MOVER_BASE[1];
        int ex=m.moverPosition[0], ey=m.moverPosition[1];
        g2.setColor(FactoryView.COL_MOVE.darker());
        g2.setStroke(new BasicStroke(12, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g2.drawLine(bx, by, ex, ey);
        g2.setColor(FactoryView.COL_MOVE);
        g2.setStroke(new BasicStroke(4));
        g2.drawLine(bx, by, ex, ey);
        g2.setColor(FactoryView.COL_MOVE.darker());
        g2.setStroke(new BasicStroke(10, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g2.drawLine(bx-30, by-30, bx+30, by+30);
        g2.drawLine(bx-30, by+30, bx+30, by-30);
        if (m.moving) {
            int dx = ex - PART_POS[3][0], dy = ey - PART_POS[3][1];
            for (int p = 1; p <= PARTS; p++)
                paintPart(g2, p, PART_POS[p-1][2],
                    PART_POS[p-1][0]+dx, PART_POS[p-1][1]+dy, 0.6f);
            drawJoints(g2, dx, dy);
        }
        g2.setColor(m.moving ? FactoryView.COL_PART : FactoryView.COL_MOVE);
        g2.fillOval(ex-10, ey-10, 20, 20);
    }

    // Labels
    void drawLabels(Graphics2D g2) {
        g2.setFont(new Font("Monospaced", Font.BOLD, 11));
        label(g2, "ROBOTIC ARM", ARM_BASE[0]+20,   ARM_BASE[1]-8,  FactoryView.COL_ARM);
        label(g2, "WELDER",      WELDER_BASE[0]-90, WELDER_BASE[1]-8, FactoryView.COL_WELD);
        label(g2, "MOVER",       MOVER_BASE[0]-10,  MOVER_BASE[1]+40, FactoryView.COL_MOVE);
    }

    void label(Graphics2D g2, String t, int x, int y, Color c) {
        g2.setColor(FactoryView.BG); g2.drawString(t, x+1, y+1);
        g2.setColor(c);             g2.drawString(t, x, y);
    }

    // Draw one structural part as a line through its centre
    void paintPart(Graphics2D g2, int p, int deg, int cx, int cy, float a) {
        double rad = Math.toRadians(90 - deg);
        int h = PART_LENGTHS[p-1] / 2;
        int dx = (int)(Math.cos(rad)*h), dy = (int)(Math.sin(rad)*h);
        Color c = FactoryView.COL_PART;
        g2.setColor(new Color(c.getRed(), c.getGreen(), c.getBlue(), (int)(255*a)));
        g2.setStroke(new BasicStroke(4*a, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g2.drawLine(cx-dx, cy+dy, cx+dx, cy-dy);
    }
}
