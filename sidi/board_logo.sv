// board_logo.sv - "SiDi" logo for the menu backgrounds
// Shaeon (Carlos Palmero), 2026
//
// "SiDi" in bold sans, stored as a 74x22 2-bit alpha bitmap (generated
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

localparam int LW = 74;
localparam int LH = 22;
localparam int LX = 554;

assign color_r = 8'd232;
assign color_g = 8'd112;
assign color_b = 8'd0;

function automatic [2*LW-1:0] logo_row(input [4:0] row);
    case (row)
        5'd0: logo_row = 148'h0000000000000000000000000000000000000;
        5'd1: logo_row = 148'h0016aaa950000bff400555555500000003ffc;
        5'd2: logo_row = 148'h01fffffffd000bff400bfffffffa400003ffc;
        5'd3: logo_row = 148'h0bfffffffd000bff400bfffffffff40003ffc;
        5'd4: logo_row = 148'h2fff5556bd000000000bffeaaffffe0000000;
        5'd5: logo_row = 148'h3ffc0000000006aa400bffc0007fffc002aa8;
        5'd6: logo_row = 148'h3ffe000000000bff800bffc0000bffe003ffc;
        5'd7: logo_row = 148'h2ffffa9400000bff400bffc00003fff003ffc;
        5'd8: logo_row = 148'h0bffffffe4000bff400bffc00002fff403ffc;
        5'd9: logo_row = 148'h01bffffffe000bff400bffc00002fff403ffc;
        5'd10: logo_row = 148'h00056bffff800bff400bffc00002fff003ffc;
        5'd11: logo_row = 148'h0000001fffc00bff400bffc00007ffe003ffc;
        5'd12: logo_row = 148'h10000007ffc00bff400bffc0002fffd003ffc;
        5'd13: logo_row = 148'h3e94001fff800bff400bffd55affff4003ffc;
        5'd14: logo_row = 148'h3fffffffff400bff400bfffffffff80003ffc;
        5'd15: logo_row = 148'h2ffffffff9000bff800bffffffff900003ffc;
        5'd16: logo_row = 148'h05affffe90000aaa4006aaaaaa50000002aa8;
        5'd17: logo_row = 148'h0000000000000000000000000000000000000;
        5'd18: logo_row = 148'h0000000000000000000000000000000000000;
        5'd19: logo_row = 148'h0000000000000000000000000000000000000;
        5'd20: logo_row = 148'h0000000000000000000000000000000000000;
        5'd21: logo_row = 148'h0000000000000000000000000000000000000;
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
