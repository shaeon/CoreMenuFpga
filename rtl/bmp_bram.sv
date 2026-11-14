`default_nettype none

// bmp_bram.sv - background picture (MENU.ROM / BMP) kept in block RAM
// Shaeon (Carlos Palmero), 2026
//
// Used on SiDi128 instead of the SDRAM, so that both video outputs (VGA and
// HDMI, each with its own timing) can read the picture at the same time.
// The 640x312x32 BMP is stored at half horizontal resolution and RGB666
// (320x312x18 bits), the same detail the SDRAM version shows (it reads one
// pixel every two).
//
// Port A (clk_sys): writes during the download and reads for the VGA output.
// Port B (clk_b):   reads for the HDMI output.
// Rows are counted as in the BMP: row 0 is the bottom line.

module bmp_bram (
    input  wire        clk_sys,
    input  wire        ioctl_downl,
    input  wire        ioctl_wr,
    input  wire [26:0] ioctl_addr,
    input  wire  [7:0] ioctl_dout,
    input  wire [23:0] data_start,     // offset of the pixel data in the file

    input  wire  [9:0] a_x,            // VGA: x 0..639
    input  wire  [8:0] a_row,          // VGA: BMP row
    output wire [23:0] a_q,

    input  wire        clk_b,
    input  wire  [9:0] b_x,            // HDMI: x 0..639
    input  wire  [8:0] b_row,          // HDMI: BMP row
    output wire [23:0] b_q
);

localparam int W = 320;
localparam int H = 312;

(* ramstyle = "M9K, no_rw_check" *) reg [17:0] ram [0:W*H-1];

// ---- capture of the download --------------------------------------------
reg        wr_last;
reg  [1:0] comp;
reg  [9:0] col;
reg  [8:0] row;
reg [16:0] row_base;
reg  [7:0] b_byte, g_byte;
reg        we;
reg [16:0] waddr;
reg [17:0] wdata;

always @(posedge clk_sys) begin
    wr_last <= ioctl_wr;
    we      <= 1'b0;
    if (!ioctl_downl) begin
        comp     <= 2'd0;
        col      <= 10'd0;
        row      <= 9'd0;
        row_base <= 17'd0;
    end else if (~wr_last & ioctl_wr && ioctl_addr > 27'd13 &&
                 ioctl_addr[23:0] >= data_start) begin
        case (comp)
            2'd0: b_byte <= ioctl_dout;
            2'd1: g_byte <= ioctl_dout;
            2'd2: if (!col[0] && row < H) begin
                      we    <= 1'b1;
                      waddr <= row_base + {8'd0, col[9:1]};
                      wdata <= {ioctl_dout[7:2], g_byte[7:2], b_byte[7:2]};
                  end
            default: ;
        endcase
        comp <= comp + 2'd1;
        if (comp == 2'd3) begin
            if (col == 10'd639) begin
                col      <= 10'd0;
                row      <= row + 9'd1;
                row_base <= row_base + W[16:0];
            end else begin
                col <= col + 10'd1;
            end
        end
    end
end

// ---- addresses ------------------------------------------------------------
function automatic [16:0] pix_addr(input [8:0] r, input [9:0] x);
    pix_addr = {r, 8'd0} + {2'd0, r, 6'd0} + {8'd0, x[9:1]};   // r*320 + x/2
endfunction

reg [16:0] a_addr, b_addr;
always @(posedge clk_sys) a_addr <= pix_addr(a_row, a_x);
always @(posedge clk_b)   b_addr <= pix_addr(b_row, b_x);

// ---- RAM ------------------------------------------------------------------
reg [17:0] qa, qb;
wire [16:0] porta_addr = we ? waddr : a_addr;

always @(posedge clk_sys) begin
    if (we) ram[porta_addr] <= wdata;
    qa <= ram[porta_addr];
end

always @(posedge clk_b) qb <= ram[b_addr];

// extra output register: the RAM is ~200 M9K blocks and its output mux is
// slow, keep it away from the video mixing logic
reg [17:0] qa_r, qb_r;
always @(posedge clk_sys) qa_r <= qa;
always @(posedge clk_b)   qb_r <= qb;

assign a_q = {qa_r[17:12], qa_r[17:16], qa_r[11:6], qa_r[11:10], qa_r[5:0], qa_r[5:4]};
assign b_q = {qb_r[17:12], qb_r[17:16], qb_r[11:6], qb_r[11:10], qb_r[5:0], qb_r[5:4]};

endmodule
