`default_nettype none

// hdmi_1080p.sv - standard 1080p60 HDMI output of the menu (SiDi128)
// Shaeon (Carlos Palmero), 2026
//
// Output: CEA-861 1920x1080p60 (VIC 16), 148.5 MHz, 2200x1125 total, positive
// syncs, RGB 4:4:4 with DE. Fixed timing, independent of the VGA output and of
// the PAL/NTSC option, so every HDMI TV and monitor can lock on it and the
// sync never stops.
//
// The menu picture (640x312) is drawn again by a second menu_render running at
// 14.85 MHz (148.5 / 10), locked to the HDMI timing: one source line every 3
// HDMI lines (6600 HDMI clocks = 660 render clocks). Each rendered line goes,
// with the OSD on top, to a two-line buffer in block RAM, which the HDMI side
// reads with integer scaling:
//   4:3  : x2 horizontal, x3 vertical -> 1280x936, centered (black borders)
//   Wide : x3 horizontal, x3 vertical -> 1920x936
// No frame buffer and no SDRAM: the latency is about one source line.

module hdmi_1080p #(
    parameter BIG_OSD = 1'b1
) (
    input  wire        hclk,           // 148.5 MHz
    input  wire        rclk,           // 14.85 MHz, same PLL, hclk / 10
    input  wire        locked,

    // menu settings (any clock domain, quasi static)
    input  wire [63:0] status,
    input  wire [63:0] rtc,
    input  wire [22:0] noise,
    input  wire        wide,

    // OSD
    input  wire        SPI_SCK,
    input  wire        SPI_SS3,
    input  wire        SPI_DI,
    input  wire  [1:0] rotate,
    input  wire signed [10:0] osd_x_offset,
    input  wire signed [10:0] osd_y_offset,
    input  wire  [2:0] osd_color,

    // background picture (bmp_bram port B, rclk)
    output wire  [9:0] file_x,
    output wire  [8:0] file_row,
    input  wire [23:0] file_q,
    input  wire        file_ok,

    // to the HDMI transmitter
    output reg   [7:0] HDMI_R,
    output reg   [7:0] HDMI_G,
    output reg   [7:0] HDMI_B,
    output reg         HDMI_HS,
    output reg         HDMI_VS,
    output reg         HDMI_DE
);

// ===========================================================================
// Render side (rclk)
// ===========================================================================

localparam [8:0] LINES = 9'd312;     // source lines (PAL layout)

reg [63:0] st_m, st;
reg [63:0] rtc_r;
reg [22:0] nz;
always @(posedge rclk) begin
    st_m  <= status;
    st    <= st_m;
    rtc_r <= rtc;      // lcd_clock resynchronizes it again
    nz    <= noise;    // free running noise source, any sample is good
end

// 660 x 375 render grid = 6600 x 1125 HDMI clocks / 10
reg [9:0] rh = 10'd0;      // 0..659
reg [8:0] rv = 9'd0;       // 0..374, one per three HDMI lines
reg       rsof = 1'b0;     // start of frame, for the HDMI side

// animation counters, scaled from the 50 Hz of the VGA output to 60 Hz
reg [15:0] anim = 16'd0;
reg  [4:0] afrac = 5'd0;   // 1/24 steps
reg  [9:0] vvc = 10'd0;
reg  [1:0] vvc_frac = 2'd0;

always @(posedge rclk) begin
    reg [5:0] t;
    reg [5:0] step;
    rsof <= (rh == 10'd659) && (rv == 9'd374);
    if (rh == 10'd659) begin
        rh <= 10'd0;
        if (rv == 9'd374) begin
            rv <= 9'd0;
            // Speed (status[26:25]): Normal 1, Slow 1/2, Very slow 1/4,
            // Fast 2 steps per 50 Hz frame -> 20/24, 10/24, 5/24, 40/24
            // per 60 Hz frame
            case (st[26:25])
                2'd1:    step = 6'd10;
                2'd2:    step = 6'd5;
                2'd3:    step = 6'd40;
                default: step = 6'd20;
            endcase
            t = {1'b0, afrac} + step;
            if (t >= 6'd48)      begin anim <= anim + 16'd2; afrac <= t - 6'd48; end
            else if (t >= 6'd24) begin anim <= anim + 16'd1; afrac <= t - 6'd24; end
            else                       afrac <= t[4:0];
            // classic background: 6, 3, 1.5, 12 per 50 Hz frame
            // -> 5, 2.5, 1.25, 10 per 60 Hz frame (in quarters)
            case (st[26:25])
                2'd1:    {vvc, vvc_frac} <= {vvc, vvc_frac} + 12'd10;
                2'd2:    {vvc, vvc_frac} <= {vvc, vvc_frac} + 12'd5;
                2'd3:    {vvc, vvc_frac} <= {vvc, vvc_frac} + 12'd40;
                default: {vvc, vvc_frac} <= {vvc, vvc_frac} + 12'd20;
            endcase
        end else begin
            rv <= rv + 9'd1;
        end
    end else begin
        rh <= rh + 10'd1;
    end
end

// The source line drawn during triplet rv is shown during triplet rv + 1:
// line s is drawn at rv = s + 23 and shown at HDMI lines 3 * (s + 24) ..
// 3 * (s + 24) + 2, i.e. lines 72..1007 (936 lines, centered).
wire [8:0] vcr = rv - 9'd23;          // wraps outside 0..311
wire       line_ok = (vcr < LINES);

// Blanking as in the VGA path (same OSD placement)
reg HBlank = 1'b1, VBlank = 1'b1;
always @(posedge rclk) begin
    if (rh == 10'd642) begin
        HBlank <= 1'b1;
        if (vcr == LINES - 9'd5) VBlank <= 1'b1;
    end
    if (rh == 10'd2) begin
        HBlank <= 1'b0;
        if (vcr == 9'd2) VBlank <= 1'b0;
    end
end

assign file_x   = rh;
assign file_row = LINES - 9'd1 - vcr;

wire [7:0] R_in, G_in, B_in;

menu_render #(.CLK_HZ(14_850_000)) menu_render (
    .clk(rclk),
    .hc(rh),
    .vc(vcr),
    .line_max(LINES),
    .anim(anim),
    .vvc(vvc),
    .noise(nz),
    .status(st),
    .rtc(rtc_r),
    .file_r(file_q[23:16]),
    .file_g(file_q[15:8]),
    .file_b(file_q[7:0]),
    .file_ok(file_ok),
    .R_in(R_in),
    .G_in(G_in),
    .B_in(B_in)
);

wire [7:0] R_osd, G_osd, B_osd;

osd #(
    .OSD_AUTO_CE(1'b0),
    .USE_BLANKS(1'b1),
    .OUT_COLOR_DEPTH(8),
    .BIG_OSD(BIG_OSD)
) osd (
    .clk_sys(rclk),
    .ce(1'b1),
    .SPI_SCK(SPI_SCK),
    .SPI_SS3(SPI_SS3),
    .SPI_DI(SPI_DI),
    .rotate(rotate),
    .R_in(R_in),
    .G_in(G_in),
    .B_in(B_in),
    .HBlank(HBlank),
    .VBlank(VBlank),
    .HSync(1'b0),
    .VSync(1'b0),
    .R_out(R_osd),
    .G_out(G_osd),
    .B_out(B_osd),
    .osd_x_offset(osd_x_offset),
    .osd_y_offset(osd_y_offset),
    .osd_color(osd_color),
    .osd_enable()
);

// ---- two-line buffer --------------------------------------------------------
(* ramstyle = "M9K, no_rw_check" *) reg [23:0] linebuf [0:2047];

reg [9:0] wx = 10'd0;
always @(posedge rclk) begin
    if (HBlank) wx <= 10'd0;
    else        wx <= wx + 10'd1;
    if (!HBlank && line_ok)
        linebuf[{vcr[0], wx}] <= VBlank ? 24'd0 : {R_osd, G_osd, B_osd};
end

// ===========================================================================
// HDMI side (hclk): CEA-861 1080p60
// ===========================================================================

localparam [11:0] H_ACT = 12'd1920, H_FP = 12'd88, H_SYNC = 12'd44, H_TOT = 12'd2200;
localparam [10:0] V_ACT = 11'd1080, V_FP = 11'd4,  V_SYNC = 11'd5,  V_TOT = 11'd1125;

reg        wide_m, wide_s;
reg        sof_d = 1'b0;
reg        started = 1'b0;
reg [11:0] hx = 12'd0;
reg [10:0] hy = 11'd0;
reg  [1:0] ysub = 2'd0;
reg  [8:0] tv = 9'd0;          // hy / 3

always @(posedge hclk) begin
    wide_m <= wide;
    wide_s <= wide_m;

    // rsof comes from rclk (same PLL, hclk / 10): a plain register path
    sof_d <= rsof;
    if (!locked) begin
        started <= 1'b0;
    end else if (!started) begin
        if (rsof & ~sof_d) begin           // render triplet 0 begins
            started <= 1'b1;
            hx      <= 12'd0;
            hy      <= 11'd0;
            ysub    <= 2'd0;
            tv      <= 9'd0;
        end
    end else begin
        if (hx == H_TOT - 12'd1) begin
            hx <= 12'd0;
            if (hy == V_TOT - 11'd1) begin
                hy   <= 11'd0;
                ysub <= 2'd0;
                tv   <= 9'd0;
            end else begin
                hy <= hy + 11'd1;
                if (ysub == 2'd2) begin
                    ysub <= 2'd0;
                    tv   <= tv + 9'd1;
                end else begin
                    ysub <= ysub + 2'd1;
                end
            end
        end else begin
            hx <= hx + 12'd1;
        end
    end
end

// image area: lines of triplets 24..335, columns depending on the aspect
wire        in_y    = (tv >= 9'd24) && (tv < 9'd336);
wire [11:0] x_start = wide_s ? 12'd0    : 12'd320;
wire [11:0] x_end   = wide_s ? 12'd1920 : 12'd1600;
wire  [1:0] x_rep   = wide_s ? 2'd2     : 2'd1;      // repeat - 1

// stage 1: source column for pixel hx
reg       in_x = 1'b0;
reg [9:0] xs = 10'd0;
reg [1:0] xsub = 2'd0;
always @(posedge hclk) begin
    if (hx == x_start) begin
        in_x <= 1'b1;
        xs   <= 10'd0;
        xsub <= 2'd0;
    end else if (hx == x_end) begin
        in_x <= 1'b0;
    end else if (in_x) begin
        if (xsub == x_rep) begin
            xsub <= 2'd0;
            xs   <= xs + 10'd1;
        end else begin
            xsub <= xsub + 2'd1;
        end
    end
end

// stage 2: line buffer address; stage 3: data; stage 4: outputs
reg [10:0] rd_addr;
reg        img1, img2;
reg [23:0] q;
always @(posedge hclk) begin
    rd_addr <= {tv[0], xs};            // line s = tv - 24 -> bank s[0] = tv[0]
    img1    <= in_x & in_y & started;
    q       <= linebuf[rd_addr];
    img2    <= img1;
end

// syncs and DE for pixel hx, delayed to match the 4 stages
wire de0 = (hx < H_ACT) && (hy < V_ACT);
wire hs0 = (hx >= H_ACT + H_FP) && (hx < H_ACT + H_FP + H_SYNC);
// VS edges aligned with the HS leading edge (progressive CEA timing)
wire vs_on  = (hy > V_ACT + V_FP) || ((hy == V_ACT + V_FP) && (hx >= H_ACT + H_FP));
wire vs_off = (hy > V_ACT + V_FP + V_SYNC) || ((hy == V_ACT + V_FP + V_SYNC) && (hx >= H_ACT + H_FP));
wire vs0 = vs_on && !vs_off;

reg [2:0] de_p, hs_p, vs_p;
always @(posedge hclk) begin
    de_p <= {de_p[1:0], de0 & started};
    hs_p <= {hs_p[1:0], hs0 & started};
    vs_p <= {vs_p[1:0], vs0 & started};

    HDMI_DE <= de_p[2];
    HDMI_HS <= hs_p[2];
    HDMI_VS <= vs_p[2];
    HDMI_R  <= img2 ? q[23:16] : 8'd0;
    HDMI_G  <= img2 ? q[15:8]  : 8'd0;
    HDMI_B  <= img2 ? q[7:0]   : 8'd0;
end

endmodule
