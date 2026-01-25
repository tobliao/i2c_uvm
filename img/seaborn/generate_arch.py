import matplotlib
matplotlib.use("Agg")  # headless backend (no Tk required)
import matplotlib.pyplot as plt
import matplotlib.patches as patches
import os

# Ensure output directory exists
output_dir = os.path.dirname(os.path.abspath(__file__))

# IEEE Publication Style
plt.rcParams['font.family'] = 'sans-serif'
plt.rcParams['font.sans-serif'] = ['Arial', 'Helvetica', 'DejaVu Sans']
plt.rcParams['figure.dpi'] = 300

# Consistent sizes
PORT_SIZE = 0.08
FONT_LABEL = 10
FONT_CLASS = 9
FONT_LEGEND = 7.5

def draw_box(ax, xy, width, height, label=None, sublabel=None, facecolor='white',
             edgecolor='black', lw=1.2, zorder=10, critical=False, linestyle='solid'):
    """Draws a sharp-cornered component box."""
    if critical:
        lw = 2.0
    
    rect = patches.FancyBboxPatch(xy, width, height, 
                                  boxstyle="square,pad=0.015",
                                  linewidth=lw, edgecolor=edgecolor, 
                                  facecolor=facecolor, zorder=zorder, 
                                  linestyle=linestyle)
    ax.add_patch(rect)
    
    cx, cy = xy[0] + width/2, xy[1] + height/2
    if sublabel:
        ax.text(cx, cy + 0.14, label, ha='center', va='center',
                fontsize=FONT_LABEL, weight='bold', zorder=zorder+1)
        ax.text(cx, cy - 0.14, sublabel, ha='center', va='center',
                fontsize=FONT_CLASS, family='monospace', color='#333333', zorder=zorder+1)
    elif label:
        ax.text(cx, cy, label, ha='center', va='center',
                fontsize=FONT_LABEL, weight='bold', zorder=zorder+1)
    return rect

def draw_arrow(ax, start, end, color='black', lw=1.0, style='->', linestyle='solid', zorder=25):
    """Draws an arrow."""
    arrow = patches.FancyArrowPatch(start, end, arrowstyle=style, color=color,
                                    linewidth=lw, mutation_scale=10, zorder=zorder,
                                    linestyle=linestyle, shrinkA=0, shrinkB=0)
    ax.add_patch(arrow)

def draw_line(ax, points, color='black', lw=1.0, linestyle='solid', zorder=5):
    """Draws a polyline (behind boxes)."""
    xs = [p[0] for p in points]
    ys = [p[1] for p in points]
    ax.plot(xs, ys, color=color, lw=lw, linestyle=linestyle, zorder=zorder)

def add_port(ax, xy, zorder=45):
    """Adds a uniform port indicator."""
    rect = patches.Rectangle((xy[0] - PORT_SIZE/2, xy[1] - PORT_SIZE/2), 
                              PORT_SIZE, PORT_SIZE,
                              facecolor='black', edgecolor='black', zorder=zorder)
    ax.add_patch(rect)

def add_num(ax, xy, num, zorder=50):
    """Adds a circled number annotation."""
    circle = plt.Circle(xy, 0.16, facecolor='white', edgecolor='black', lw=0.8, zorder=zorder)
    ax.add_patch(circle)
    ax.text(xy[0], xy[1], str(num), ha='center', va='center', fontsize=8, 
            weight='bold', zorder=zorder+1)

def generate_arch_diagram():
    print("Generating IEEE Access Architecture Diagram (Final)...")
    
    # Double-column optimized size
    fig, ax = plt.subplots(figsize=(11, 9))
    ax.set_xlim(0, 13)
    ax.set_ylim(-1.2, 10)
    ax.axis('off')
    
    # Only 2 gray shades + white
    C_LIGHT = '#F0F0F0'
    C_MID   = '#D0D0D0'
    C_WHITE = '#FFFFFF'
    C_BUS   = '#505050'

    # Standard box sizes
    W_BOX = 1.9
    H_BOX = 0.9

    # =========================================================================
    # LAYER 1: BACKGROUNDS
    # =========================================================================
    
    # UVM Environment
    draw_box(ax, (0.3, 2.2), 12.4, 7.5, facecolor=C_LIGHT, edgecolor='#666666', lw=1.0, zorder=1)
    ax.text(0.5, 9.45, "UVM Environment", fontsize=11, weight='bold', zorder=2)
    ax.text(2.65, 9.45, "i2c_env", fontsize=10, family='monospace', color='#444444', zorder=2)

    # I2C Agent
    draw_box(ax, (0.6, 2.5), 8.0, 6.5, facecolor=C_LIGHT, edgecolor='black', lw=1.2, zorder=2)
    ax.text(0.8, 8.75, "I2C Agent", fontsize=10, weight='bold', zorder=3)
    ax.text(2.2, 8.75, "i2c_agent", fontsize=9, family='monospace', color='#444444', zorder=3)

    # =========================================================================
    # LAYER 2: COMPONENTS (Grid Aligned)
    # =========================================================================
    
    # Row 1 (y=7.3): Config
    draw_box(ax, (3.5, 7.3), W_BOX, H_BOX, "Config", "i2c_config", facecolor=C_MID, zorder=10)

    # Row 2 (y=5.9): Sequencer
    draw_box(ax, (1.0, 5.9), W_BOX, H_BOX, "Sequencer", "i2c_sequencer", facecolor=C_WHITE, zorder=10)

    # Row 3 (y=4.3): Driver, Event Pool, Monitor
    draw_box(ax, (1.0, 4.3), W_BOX, H_BOX, "Driver", "i2c_driver", facecolor=C_WHITE, critical=True, zorder=10)
    draw_box(ax, (3.8, 4.3), 1.6, H_BOX, "Event Pool", "i2c_event_pool", facecolor=C_MID, zorder=10)
    draw_box(ax, (6.2, 4.3), W_BOX, H_BOX, "Monitor", "i2c_monitor", facecolor=C_WHITE, critical=True, zorder=10)

    # Row 4 (y=3.0): Virtual Interface
    draw_box(ax, (2.0, 3.0), 4.8, 0.75, "Virtual Interface", "i2c_if", 
             facecolor=C_WHITE, linestyle='dashed', zorder=10)

    # Right column (vertically aligned)
    col_x = 9.5
    draw_box(ax, (col_x, 7.3), W_BOX, H_BOX, "Scoreboard", "i2c_scoreboard", facecolor=C_MID, zorder=10)
    draw_box(ax, (col_x, 5.6), W_BOX, H_BOX, "Coverage", "i2c_coverage", facecolor=C_MID, zorder=10)
    draw_box(ax, (col_x, 3.9), W_BOX, H_BOX, "BOI Checker", None, facecolor=C_WHITE, zorder=10)

    # =========================================================================
    # LAYER 3: PHYSICAL BUS
    # =========================================================================
    
    # Bus lines
    ax.plot([1.0, 12.5], [1.6, 1.6], color=C_BUS, lw=2.5, zorder=0)  # SDA
    ax.plot([1.0, 12.5], [1.0, 1.0], color=C_BUS, lw=2.5, zorder=0)  # SCL
    
    # Labels
    ax.text(0.5, 1.6, "SDA", weight='bold', va='center', fontsize=10, zorder=5,
            bbox=dict(facecolor='white', edgecolor='none', pad=1.5))
    ax.text(0.5, 1.0, "SCL", weight='bold', va='center', fontsize=10, zorder=5,
            bbox=dict(facecolor='white', edgecolor='none', pad=1.5))

    # RTL DUTs
    draw_box(ax, (9.0, 0.4), 1.6, 0.8, "RTL Master", facecolor=C_MID, zorder=10)
    draw_box(ax, (11.0, 0.4), 1.6, 0.8, "RTL Slave", facecolor=C_MID, zorder=10)

    # Bus taps
    ax.plot([3.5, 3.5], [3.0, 1.6], color='black', lw=0.8, zorder=5)
    ax.plot([4.3, 4.3], [3.0, 1.0], color='black', lw=0.8, zorder=5)
    ax.scatter([3.5, 4.3], [1.6, 1.0], color='black', s=20, zorder=10)
    
    ax.plot([9.8, 9.8], [1.6, 0.4], color='black', lw=0.8, zorder=5)
    ax.plot([11.8, 11.8], [1.6, 0.4], color='black', lw=0.8, zorder=5)
    ax.scatter([9.8, 11.8], [1.6, 1.6], color='black', s=20, zorder=10)

    # =========================================================================
    # LAYER 4: CONNECTIONS
    # =========================================================================

    # 1: Sequencer -> Driver
    add_port(ax, (1.95, 5.9))
    add_port(ax, (1.95, 5.2))
    draw_arrow(ax, (1.95, 5.82), (1.95, 5.28), lw=1.0)
    add_num(ax, (1.55, 5.55), 1)

    # 2: Config -> Driver (route line ABOVE Sequencer box)
    add_port(ax, (3.9, 7.3))
    add_port(ax, (2.3, 5.2))
    # Horizontal line at y=7.05 to clear Sequencer (which ends at y=6.8)
    draw_line(ax, [(3.9, 7.22), (3.9, 7.05), (2.3, 7.05), (2.3, 5.28)], linestyle='dashed', lw=0.8)
    add_num(ax, (3.1, 7.05), 2)  # On the horizontal line, above Sequencer

    # Config -> Monitor
    add_port(ax, (4.9, 7.3))
    add_port(ax, (7.1, 5.2))
    draw_line(ax, [(4.9, 7.22), (4.9, 7.05), (7.1, 7.05), (7.1, 5.28)], linestyle='dashed', lw=0.8)

    # 3: Driver -> Interface
    add_port(ax, (2.3, 4.3))
    add_port(ax, (2.3, 3.75))
    draw_arrow(ax, (2.3, 4.22), (2.3, 3.83), lw=1.0)
    add_num(ax, (1.9, 4.0), 3)

    # 4: Interface -> Monitor
    add_port(ax, (6.5, 3.75))
    add_port(ax, (7.1, 4.3))
    draw_line(ax, [(6.5, 3.83), (6.5, 4.05), (7.1, 4.05), (7.1, 4.22)], lw=1.0)
    add_num(ax, (6.8, 3.9), 4)

    # 5: Driver <-> Event Pool
    add_port(ax, (2.9, 4.75))
    add_port(ax, (3.8, 4.75))
    draw_arrow(ax, (2.98, 4.75), (3.72, 4.75), linestyle='dotted', lw=1.0, style='<->')
    add_num(ax, (3.35, 5.0), 5)

    # 6: Event Pool <-> Monitor
    add_port(ax, (5.4, 4.75))
    add_port(ax, (6.2, 4.75))
    draw_arrow(ax, (5.48, 4.75), (6.12, 4.75), linestyle='dotted', lw=1.0, style='<->')
    add_num(ax, (5.8, 5.0), 6)

    # 7: Monitor -> Scoreboard/Coverage
    add_port(ax, (8.1, 4.75))
    draw_line(ax, [(8.18, 4.75), (8.9, 4.75)], lw=1.0)
    
    add_port(ax, (col_x, 7.75))
    draw_line(ax, [(8.9, 4.75), (8.9, 7.75), (col_x - 0.08, 7.75)], lw=1.0)
    
    add_port(ax, (col_x, 6.05))
    draw_line(ax, [(8.9, 4.75), (8.9, 6.05), (col_x - 0.08, 6.05)], lw=1.0)
    add_num(ax, (8.9, 6.9), 7)

    # 8: Monitor -> BOI Checker
    add_port(ax, (col_x, 4.35))
    draw_line(ax, [(8.9, 4.75), (8.9, 4.35), (col_x - 0.08, 4.35)], lw=1.0)
    add_num(ax, (8.9, 4.55), 8)

    # =========================================================================
    # LAYER 5: LINE TYPE LEGEND (Bottom Left - 2x2 arrangement, bigger text)
    # =========================================================================
    
    leg_font = 9  # Bigger font
    leg_x = 0.5
    leg_y_top = 0.25
    leg_y_bot = -0.15
    
    # Row 1
    ax.plot([leg_x, leg_x + 0.7], [leg_y_top, leg_y_top], color='black', lw=1.2)
    ax.text(leg_x + 0.85, leg_y_top, "Data path", fontsize=leg_font, va='center')
    
    ax.plot([leg_x + 2.8, leg_x + 3.5], [leg_y_top, leg_y_top], color='black', lw=1.0, linestyle='dashed')
    ax.text(leg_x + 3.65, leg_y_top, "Control path", fontsize=leg_font, va='center')
    
    # Row 2
    ax.plot([leg_x, leg_x + 0.7], [leg_y_bot, leg_y_bot], color='black', lw=1.2, linestyle='dotted')
    ax.text(leg_x + 0.85, leg_y_bot, "Event sync", fontsize=leg_font, va='center')
    
    add_port(ax, (leg_x + 2.95, leg_y_bot))
    ax.text(leg_x + 3.15, leg_y_bot, "Port", fontsize=leg_font, va='center')

    # =========================================================================
    # LAYER 6: NUMBERED LEGEND BOX (Bottom Right - Professional)
    # =========================================================================
    
    # Legend box
    leg_box_x = 7.2
    leg_box_y = -0.9
    leg_box_w = 5.4
    leg_box_h = 1.1
    
    draw_box(ax, (leg_box_x, leg_box_y), leg_box_w, leg_box_h, 
             facecolor='white', edgecolor='#888888', lw=0.8, zorder=40)
    
    # Full professional labels
    legends = [
        (1, "TLM seq_item"),
        (2, "cfg.is_master"),
        (3, "scl_drive / sda_drive"),
        (4, "bus sample path"),
        (5, "ROLE_UPDATE event"),
        (6, "BUS_IDLE / START / STOP"),
        (7, "analysis_port"),
        (8, "BOI invariant check"),
    ]
    
    # 2 columns, 4 rows
    col1_x = leg_box_x + 0.25
    col2_x = leg_box_x + 2.8
    row_spacing = 0.24
    start_y = leg_box_y + 0.92
    
    for i, (num, txt) in enumerate(legends):
        if i < 4:
            x = col1_x
            y = start_y - (i * row_spacing)
        else:
            x = col2_x
            y = start_y - ((i - 4) * row_spacing)
        
        # Circled number
        circle = plt.Circle((x, y), 0.11, facecolor='white', edgecolor='black', lw=0.6, zorder=45)
        ax.add_patch(circle)
        ax.text(x, y, str(num), ha='center', va='center', fontsize=7, weight='bold', zorder=46)
        # Label text
        ax.text(x + 0.2, y, txt, fontsize=FONT_LEGEND, ha='left', va='center', zorder=45)

    plt.tight_layout()
    
    # Save as PNG
    plt.savefig(os.path.join(output_dir, 'architecture_diagram.png'), bbox_inches='tight')
    
    # Save as PDF
    plt.savefig(os.path.join(output_dir, 'architecture_diagram.pdf'), bbox_inches='tight', format='pdf')
    
    plt.close()
    print("IEEE Access architecture diagram generated (PNG + PDF).")

if __name__ == "__main__":
    try:
        generate_arch_diagram()
    except Exception as e:
        print("Error generating diagram: {}".format(e))
