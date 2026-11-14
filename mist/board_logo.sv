// board_logo.sv - "MiST" logo for the menu backgrounds
// Shaeon (Carlos Palmero), 2026
//
// "MiST" in bold sans, stored as a 93x22 2-bit alpha bitmap (generated
// with tools/gen_logo.py). Same place as the Calypso logo: bottom right corner,
// right margin 12 px, 17 lines from the bottom.

`default_nettype none

module board_logo (
    input  wire        clk,               // pixel clock
    input  wire  [9:0] hc,
    input  wire  [8:0] vc,
    input  wire  [8:0] line_max,
    output reg   [1:0] alpha,             // 0 transparent .. 3 opaque
    output wire  [7:0] color_r,           // logo color
    output wire  [7:0] color_g,
    output wire  [7:0] color_b
);

localparam int LW = 93;
localparam int LH = 22;
localparam int LX = 535;

assign color_r = 8'd40;
assign color_g = 8'd200;
assign color_b = 8'd60;

function automatic [2*LW-1:0] logo_row(input [4:0] row);
    case (row)
        5'd0: logo_row = 186'h00000000000000000000000000000000000000000000000;
        5'd1: logo_row = 186'h055554000005555000fff000006aaa95000555555555554;
        5'd2: logo_row = 186'h0ffffc00003ffff000fff0001bffffffe01fffffffffffc;
        5'd3: logo_row = 186'h0ffffe0000bffff000fff000bfffffffe01fffffffffffc;
        5'd4: logo_row = 186'h0fffff4001fffff000000001fff9556be00aaaafffeaaa8;
        5'd5: logo_row = 186'h0fffffc003fffff000aaa002ffd000000000000fff80000;
        5'd6: logo_row = 186'h0fffbfe00bfefff000fff002ffe400000000000fff80000;
        5'd7: logo_row = 186'h0fff2ff82ff8fff000fff001ffffe9400000000fff80000;
        5'd8: logo_row = 186'h0fff4ffc3ff1fff000fff0007ffffffe4000000fff80000;
        5'd9: logo_row = 186'h0fff43ffffd1fff000fff0000bfffffff000000fff80000;
        5'd10: logo_row = 186'h0fff41ffff41fff000fff0000016bffffc00000fff80000;
        5'd11: logo_row = 186'h0fff40bffe01fff000fff000000001bffd00000fff80000;
        5'd12: logo_row = 186'h0fff403ffc01fff000fff0004000003ffd00000fff80000;
        5'd13: logo_row = 186'h0fff401ff401fff000fff001f94001bffc00000fff80000;
        5'd14: logo_row = 186'h0fff40000001fff000fff001fffffffff400000fff80000;
        5'd15: logo_row = 186'h0fff40000001fff000fff001ffffffffd000000fff80000;
        5'd16: logo_row = 186'h0aaa40000000aaa000aaa0001afffff90000000aaa80000;
        5'd17: logo_row = 186'h00000000000000000000000000000000000000000000000;
        5'd18: logo_row = 186'h00000000000000000000000000000000000000000000000;
        5'd19: logo_row = 186'h00000000000000000000000000000000000000000000000;
        5'd20: logo_row = 186'h00000000000000000000000000000000000000000000000;
        5'd21: logo_row = 186'h00000000000000000000000000000000000000000000000;
        default: logo_row = '0;
    endcase
endfunction

wire [8:0] ly0 = line_max - 9'd38;     // first line of the logo

always @(posedge clk) begin
    reg [2*LW-1:0] bits;
    reg [9:0] x;
    reg [8:0] y;
    alpha <= 2'd0;
    if (hc >= LX && hc < LX + LW && vc >= ly0 && vc < ly0 + LH) begin
        x    = hc - LX[9:0];
        y    = vc - ly0;
        bits = logo_row(y[4:0]);
        alpha <= bits[2*(LW-1-x) +: 2];
    end
end

endmodule
