// board_logo.sv - "Poseidon" logo for the menu backgrounds
// Shaeon (Carlos Palmero), 2026
//
// "Poseidon" in bold sans, stored as a 169x22 2-bit alpha bitmap (generated
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

localparam int LW = 169;
localparam int LH = 22;
localparam int LX = 459;

assign color_r = 8'd0;
assign color_g = 8'd170;
assign color_b = 8'd255;

function automatic [2*LW-1:0] logo_row(input [4:0] row);
    case (row)
        5'd0: logo_row = 338'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd1: logo_row = 338'h05555555400000000000000000000000000000000000000bff4000000007ffc0000000000000000000000;
        5'd2: logo_row = 338'h0ffffffff90000000000000000000000000000000000000bff4000000007ffc0000000000000000000000;
        5'd3: logo_row = 338'h0fffffffffd000000000000000000000000000000000000bff4000000007ffc0000000000000000000000;
        5'd4: logo_row = 338'h0fffaaaffff0000000000000000000000000000000000000000000000007ffc0000000000000000000000;
        5'd5: logo_row = 338'h0fff8001fff80006affa5000006bffaa400005affa400006aa40002bfa43ffc00006bffa400006aa46bf8;
        5'd6: logo_row = 338'h0fff8000fff8007ffffffd0007ffffffd0007ffffff8000bff4002fffff7ffc000bffffff9000bffafffc;
        5'd7: logo_row = 338'h0fff8001fff802fffebfff801fffaaafd002fffaafff400bff400fffffffffc007fffebfff400bffffffc;
        5'd8: logo_row = 338'h0fff956bfff00bffd007ffe02ffc0000400bff8003ffc00bff402fff401fffc00fff800bffd00bffe40bc;
        5'd9: logo_row = 338'h0fffffffffd01fff4001fff01ffea540000fff5556ffe00bff403ffd000bffc01fff0002ffe00bffc003c;
        5'd10: logo_row = 338'h0ffffffff9001fff0000fff40bfffffe401ffffffffff00bff407ffc0007ffc02ffe0001fff00bff4003c;
        5'd11: logo_row = 338'h0fff955540001fff0000fff401bfffffe01fffffffffe00bff407ffc0007ffc02ffe0001fff00bff4003c;
        5'd12: logo_row = 338'h0fff800000001fff0001fff0000156fff41fff000000000bff403ffd0007ffc02fff0002fff00bff4003c;
        5'd13: logo_row = 338'h0fff800000000fffc007ffe00400007ff80bff800001800bff402fff401fffc00fff8007ffd00bff4003c;
        5'd14: logo_row = 338'h0fff8000000003fffabfff801feaaafff403fffaaabfc00bff400ffffaffffc007fffabfff800bff4003c;
        5'd15: logo_row = 338'h0fff8000000000bffffffd001fffffffd000bfffffffc00bff4002fffffbffc000bffffffd000bff4003c;
        5'd16: logo_row = 338'h0aaa400000000006ffff900006bffff9000006ffffe9000aaa40006ffe42aa800006fffe90000aaa40028;
        5'd17: logo_row = 338'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd18: logo_row = 338'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd19: logo_row = 338'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd20: logo_row = 338'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd21: logo_row = 338'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
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
