// board_logo.sv - "SiDi128" logo for the menu backgrounds
// Shaeon (Carlos Palmero), 2026
//
// "SiDi128" in bold sans, stored as a 146x22 2-bit alpha bitmap (generated
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

localparam int LW = 146;
localparam int LH = 22;
localparam int LX = 482;

assign color_r = 8'd232;
assign color_g = 8'd112;
assign color_b = 8'd0;

function automatic [2*LW-1:0] logo_row(input [4:0] row);
    case (row)
        5'd0: logo_row = 292'h0000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd1: logo_row = 292'h0016aaa950000fff40055555550000000bff80000155540000005aaaa500000006aaa9400;
        5'd2: logo_row = 292'h01fffffffd000fff400ffffffff900000bff8002fffffd00000bffffffe00001bffffff40;
        5'd3: logo_row = 292'h0bfffffffd000bff400bffffffffe4000bff8003fffffd00000ffffffffc000bfffffffe0;
        5'd4: logo_row = 292'h2fff5556bd000000000bffeaaffffd0000000002ea7ffd00000fa401bffe000fff801fff4;
        5'd5: logo_row = 292'h3ffc000000000aaa000bff8000bfff8006aa4000003ffd00000400002fff001fff000bff8;
        5'd6: logo_row = 292'h3ffe000000000fff400bff80000fffd00bff8000003ffd00000000001fff000fff400fff0;
        5'd7: logo_row = 292'h2ffffa9400000fff400bff800007ffe00bff8000003ffd00000000003ffe0002ffeabffd0;
        5'd8: logo_row = 292'h0bffffffe4000fff400bff800003fff00bff8000003ffd0000000001fff800006fffff900;
        5'd9: logo_row = 292'h01bffffffe000fff400bff800003fff00bff8000003ffd000000001bffd00002fffffff80;
        5'd10: logo_row = 292'h0005abffff400fff400bff800003ffe00bff8000003ffd00000000bffe00000fff801fff4;
        5'd11: logo_row = 292'h0000001fffc00fff400bff80000bffd00bff8000003ffd0000000bffe000002ffe0007ffc;
        5'd12: logo_row = 292'h10000007ffc00fff400bff80006fff800bff8000003ffd000000bffe0000002ffd0003ffc;
        5'd13: logo_row = 292'h3e94001fff800fff400bffd55bfffe000bff8000003ffd000007fff41555002fff000bffc;
        5'd14: logo_row = 292'h3fffffffff000fff400bfffffffff8000bff8002ffffffffc00fffffffff400fffeabfff4;
        5'd15: logo_row = 292'h2ffffffff8000fff400ffffffffe40000bff8002ffffffffc00fffffffff4002fffffffd0;
        5'd16: logo_row = 292'h05affffe90000aaa400aaaaaaa50000006aa4002aaaaaaaa800aaaaaaaaa40006bfffe900;
        5'd17: logo_row = 292'h0000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd18: logo_row = 292'h0000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd19: logo_row = 292'h0000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd20: logo_row = 292'h0000000000000000000000000000000000000000000000000000000000000000000000000;
        5'd21: logo_row = 292'h0000000000000000000000000000000000000000000000000000000000000000000000000;
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
