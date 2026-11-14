`default_nettype none

// menu_render.sv - background, logo and LCD clock of the menu for one video
// output. Pure function of the pixel position (hc, vc) and the animation
// counters, so it can be instantiated more than once (VGA and HDMI on SiDi128).
// Shaeon (Carlos Palmero), 2026

module menu_render #(
    parameter CLK_HZ = 12_500_000
) (
    input  wire        clk,
    input  wire  [9:0] hc,
    input  wire  [8:0] vc,
    input  wire  [8:0] line_max,
    input  wire [15:0] anim,
    input  wire  [9:0] vvc,
    input  wire [22:0] noise,
    input  wire [63:0] status,
    input  wire [63:0] rtc,
    input  wire  [7:0] file_r,
    input  wire  [7:0] file_g,
    input  wire  [7:0] file_b,
    input  wire        file_ok,
    output wire  [7:0] R_in,
    output wire  [7:0] G_in,
    output wire  [7:0] B_in
);

wire [5:0] rnd_c = {noise[0],noise[1],noise[2],noise[2],noise[2],noise[2]};

///// Noise
wire [7:0] cos_out;
wire [7:0] cos_g = cos_out[7:1]+6'd32;
cos cos(vvc + {vc, 2'b00}, cos_out);

wire [7:0] comp_v = (cos_g >= rnd_c) ? cos_g - rnd_c : 8'd0;

///// Waterfall background
wire [7:0] wf_r, wf_g, wf_b;

waterfall_bg waterfall_bg (
    .clk(clk),
    .hc(hc),
    .vc(vc),
    .line_max(line_max),
    .frame(anim[9:0]),
    .noise(noise[7:0]),
    .r(wf_r),
    .g(wf_g),
    .b(wf_b)
);

///// Matrix background
wire [7:0] mx_r, mx_g, mx_b;

matrix_bg matrix_bg (
    .clk(clk),
    .hc(hc),
    .vc(vc),
    .frame(anim),
    .r(mx_r),
    .g(mx_g),
    .b(mx_b)
);

///// Sea background
wire [7:0] sea_r, sea_g, sea_b;

sea_bg sea_bg (
    .clk(clk),
    .hc(hc),
    .vc(vc),
    .line_max(line_max),
    .frame(anim),
    .r(sea_r),
    .g(sea_g),
    .b(sea_b)
);

///// Board logo (on the animated and classic backgrounds)
wire [1:0] logo_a;

wire [7:0] LOGO_R, LOGO_G, LOGO_B;

board_logo board_logo (
    .clk(clk),
    .hc(hc),
    .vc(vc),
    .line_max(line_max),
    .alpha(logo_a),
    .color_r(LOGO_R),
    .color_g(LOGO_G),
    .color_b(LOGO_B)
);

// Background type: 0 waterfall, 1 matrix, 2 sea, 3 classic, 4 file (MENU.ROM
// or a loaded BMP; classic if there is none)
wire [2:0] bg_sel   = status[24:22];
wire       animated = (bg_sel <= 3'd2);
wire       use_file = (bg_sel == 3'd4) && file_ok;
// the logo goes on every background except a picture file (it has its own)
wire       show_logo = !use_file && ~status[27];

reg [7:0] anim_r, anim_g, anim_b;
always @(*) begin
    case (bg_sel)
        3'd1:    {anim_r, anim_g, anim_b} = {mx_r,  mx_g,  mx_b};
        3'd2:    {anim_r, anim_g, anim_b} = {sea_r, sea_g, sea_b};
        default: {anim_r, anim_g, anim_b} = {wf_r,  wf_g,  wf_b};
    endcase
end

// logo blending: color from board_logo, 2-bit alpha
wire [1:0] la = show_logo ? logo_a : 2'd0;

function automatic [7:0] blend(input [7:0] bg, input [7:0] fg, input [1:0] a);
    reg [9:0] t;
    begin
        case (a)
            2'd3:    t = fg;
            2'd2:    t = (bg + fg) >> 1;
            2'd1:    t = (bg + bg + bg + fg) >> 2;
            default: t = bg;
        endcase
        blend = t[7:0];
    end
endfunction

wire [7:0] base_r = animated ? anim_r : use_file ? file_r : comp_v;
wire [7:0] base_g = animated ? anim_g : use_file ? file_g : comp_v;
wire [7:0] base_b = animated ? anim_b : use_file ? file_b : comp_v;

wire [7:0] bg_r = blend(base_r, LOGO_R, la);
wire [7:0] bg_g = blend(base_g, LOGO_G, la);
wire [7:0] bg_b = blend(base_b, LOGO_B, la);

///// LCD clock (only shown when the firmware sends the time from a USB RTC)
wire       clock_active;
wire [1:0] clock_a;
wire [7:0] clock_r, clock_g, clock_b;

lcd_clock #(.CLK_HZ(CLK_HZ)) lcd_clock (
    .clk(clk),
    .hc(hc),
    .vc(vc),
    .line_max(line_max),
    .rtc(rtc),
    .enable(~status[14]),
    .vpos(status[16:15]),
    .hpos(status[18:17]),
    .palette(status[21:19]),
    .size(status[28]),
    .datefmt(status[30:29]),
    .pointed(status[31]),
    .weekday(status[35:34]),
    .no_panel(status[32]),
    .no_shadow(status[33]),
    .active(clock_active),
    .alpha(clock_a),
    .r(clock_r),
    .g(clock_g),
    .b(clock_b)
);

// clock over the background: opaque, or the shadow of the unlit segments at
// 1/8 when there is no panel
function automatic [7:0] clock_mix(input [7:0] bg, input [7:0] fg, input [1:0] a);
    reg [10:0] t;
    begin
        case (a)
            2'd3:    t = fg;
            2'd1:    t = ({3'd0, bg} * 11'd7 + fg) >> 3;
            default: t = bg;
        endcase
        clock_mix = t[7:0];
    end
endfunction

assign R_in = clock_mix(bg_r, clock_r, clock_a);
assign G_in = clock_mix(bg_g, clock_g, clock_a);
assign B_in = clock_mix(bg_b, clock_b, clock_a);

endmodule
