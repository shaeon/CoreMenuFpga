`default_nettype none

// MiST, SiDi and Poseidon port of the Calypso menu core (teiram/calypso-ports, menu)
// Shaeon (Carlos Palmero), 2026
//
// Common top for these boards. Each board folder (mist/, sidi/, poseidon/) has its own
// project, pins, PLL, macros and board_logo.sv.

// Board options derived from the .qsf macros
`ifdef POSEIDON
`define MENU_CLK50
`endif
`ifdef SIDI128
`define MENU_CLK50
`define BMP_BRAM
`define SIGMA_DELTA_AUDIO
`endif
`ifndef I2S_AUDIO
`define SIGMA_DELTA_AUDIO
`endif

module menu_top(
`ifdef MENU_CLK50
    input CLOCK_50,
`endif
`ifndef POSEIDON
    input CLOCK_27,
`endif

    output [VGA_BITS-1:0] VGA_R,
    output [VGA_BITS-1:0] VGA_G,
    output [VGA_BITS-1:0] VGA_B,
    output VGA_HS,
    output VGA_VS,

    input SPI_SCK,
    inout SPI_DO,
    input SPI_DI,
    input SPI_SS2,
    input SPI_SS3,
    input CONF_DATA0,

`ifndef NO_DIRECT_UPLOAD
    input SPI_SS4,
`endif

`ifdef I2S_AUDIO
    output I2S_BCK,
    output I2S_LRCK,
    output I2S_DATA,
`endif
`ifdef SIGMA_DELTA_AUDIO
    output AUDIO_L,
    output AUDIO_R,
`endif
`ifdef USE_HDMI
    output       HDMI_RST,
    output [7:0] HDMI_R,
    output [7:0] HDMI_G,
    output [7:0] HDMI_B,
    output       HDMI_HS,
    output       HDMI_VS,
    output       HDMI_DE,
    output       HDMI_PCLK,
    inout        HDMI_SDA,
    inout        HDMI_SCL,
    output       HDMI_MCLK,
    output       HDMI_BCK,
    output       HDMI_LRCK,
    output       HDMI_SDATA,
`endif
`ifdef USE_AUDIO_IN
    input AUDIO_IN,
`endif

`ifndef BMP_BRAM
    output [12:0] SDRAM_A,
    inout [15:0] SDRAM_DQ,
    output SDRAM_DQML,
    output SDRAM_DQMH,
    output SDRAM_nWE,
    output SDRAM_nCAS,
    output SDRAM_nRAS,
    output SDRAM_nCS,
    output [1:0] SDRAM_BA,
    output SDRAM_CLK,
    output SDRAM_CKE,
`endif

    output LED
);

`ifdef NO_DIRECT_UPLOAD
localparam bit DIRECT_UPLOAD = 0;
wire SPI_SS4 = 1;
`else
localparam bit DIRECT_UPLOAD = 1;
`endif

`ifdef USE_QSPI
localparam bit QSPI = 1;
assign QDAT = 4'hZ;
`else
localparam bit QSPI = 0;
`endif

`ifdef VGA_8BIT
localparam VGA_BITS = 8;
`else
localparam VGA_BITS = 6;
`endif

`ifdef USE_HDMI
localparam bit HDMI = 1;
`else
localparam bit HDMI = 0;
`endif

`ifdef USE_HDMI
localparam HDMI_OPT = "Oa,HDMI 1080p,4:3,Wide;";
`else
localparam HDMI_OPT = "";
`endif

`ifdef BIG_OSD
localparam bit BIG_OSD = 1;
localparam SEP = "-;";
`else
localparam bit BIG_OSD = 0;
localparam SEP = "";
`endif

`include "build_id.v"

localparam CONF_STR = {
    "MENU;;",
    "F1,BMP,Change background;",
    "O1,Video mode,PAL,NTSC;",
    "O23,Rotate,Off,Left,Right;",
    "O4,KITT Mode,Off,On;",
    HDMI_OPT,
    "O57,OSD HPos,0,-64,-48,-32,-16,+16,+32,+48;",
    "O8A,OSD VPos,0,-64,-48,-32,-16,+16,+32,+48;",
    "OBD,OSD Color,Black,Blue,Green,Cyan,Red,Magenta,Yellow,White;",
    "P2,Background;",
    "P2OMO,Type,Waterfall,Matrix,Sea,Classic,File;",
    "P2OPQ,Speed,Normal,Slow,Very slow,Fast;",
    "P2OR,Logo,On,Off;",
    "P1,Clock;",
    "P1OE,Clock,On,Off;",
    "P1OS,Size,1x,2x;",
    "P1OV,Segments,Flat,Pointed;",
    "P1OW,Panel,On,Off;",
    "P1OX,Shadow,On,Off;",
    "P1OFG,Vertical,Bottom,Top,Center;",
    "P1OHI,Horizontal,Center,Left,Right;",
    "P1OTU,Date,DD-MM-YYYY,MM-DD-YYYY,YYYY-MM-DD;",
    "P1OYZ,Weekday,Off,English,Spanish;",
    "P1OJL,Color,Green LCD,Gray LCD,Blue,Amber,Game Boy,Red LED,VFD,Inverted;",
    "V,",`BUILD_VERSION,"-",`BUILD_DATE
};
// 27 MHz in (Poseidon and SiDi128: 50 MHz), SDRAM at 50 MHz as in the MiST menu core
// (clk_ram 50 MHz, clk_x2 25 MHz, clk_pix 12.5 MHz; clk_sys = clk_ram)
wire clk_x2, clk_pix, clk_ram, pll_locked;
pll pll(
`ifdef MENU_CLK50
    .inclk0(CLOCK_50),
`else
    .inclk0(CLOCK_27),
`endif
    .c0(clk_ram),
    .c1(clk_x2),
    .c2(clk_pix),
    .locked(pll_locked)
);
wire clk_sys = clk_ram;

reg signed [10:0] osd_x_offset = 11'd0;
reg signed [10:0] osd_y_offset = 11'd0;
reg [2:0] osd_color = 3'd2;

always @(posedge clk_x2) begin
    case (status[7:5])
        3'd0: osd_x_offset <= 11'd0;
        3'd1, 3'd2, 3'd3, 3'd4: osd_x_offset <= {4'b1111, status[7:5], 4'd0};
        3'd5, 3'd6, 3'd7: osd_x_offset <= {5'd0, status[6:5], 4'd0};
    endcase
    case (status[10:8])
        3'd0: osd_y_offset <= 11'd0;
        3'd1, 3'd2, 3'd3, 3'd4: osd_y_offset <= {4'b1111, status[10:8], 4'd0};
        3'd5, 3'd6, 3'd7: osd_y_offset <= {5'd0, status[9:8], 4'd0};
    endcase
    osd_color = status[13:11];
end

`ifdef USE_HDMI
wire       i2c_start, i2c_read, i2c_ack, i2c_end;
wire [6:0] i2c_addr;
wire [7:0] i2c_subaddr, i2c_dout, i2c_din;
`endif

wire scandoubler_disable;
wire ypbpr;
wire no_csync;
wire [63:0] status;
wire [63:0] rtc;

user_io #(
    .STRLEN($size(CONF_STR)>>3),
    .FEATURES(32'd1 | (BIG_OSD << 13) | (HDMI << 14)),
    .HDMI_HICLK(HDMI),          // the HDMI output is 1080p (148.5 MHz)
    .ROM_DIRECT_UPLOAD(DIRECT_UPLOAD))
    user_io(
    .clk_sys(clk_x2),
    .conf_str(CONF_STR),

    .SPI_CLK(SPI_SCK),
    .SPI_SS_IO(CONF_DATA0),
    .SPI_MISO(SPI_DO),
    .SPI_MOSI(SPI_DI),
    .status(status),
    .rtc(rtc),

    .scandoubler_disable(scandoubler_disable),
    .ypbpr(ypbpr),
`ifdef USE_HDMI
    .i2c_start(i2c_start),
    .i2c_read(i2c_read),
    .i2c_addr(i2c_addr),
    .i2c_subaddr(i2c_subaddr),
    .i2c_dout(i2c_dout),
    .i2c_din(i2c_din),
    .i2c_ack(i2c_ack),
    .i2c_end(i2c_end),
`endif
    .no_csync(no_csync)
);

wire ntsc = status[1];
wire [1:0] rotate = status[3:2];

wire [8:0] line_max = ntsc ? 9'd262 : 9'd312;

wire ioctl_downl;
wire ioctl_upl;
wire [7:0] ioctl_index;
wire ioctl_wr;
wire [26:0] ioctl_addr;
wire [7:0] ioctl_din;
wire [7:0] ioctl_dout;

data_io #(.ROM_DIRECT_UPLOAD(DIRECT_UPLOAD))
    data_io(
    .clk_sys(clk_sys),
    .SPI_SCK(SPI_SCK),
    .SPI_SS2(SPI_SS2),
    .SPI_SS4(SPI_SS4),
    .SPI_DI(SPI_DI),
    .SPI_DO(SPI_DO),
    .ioctl_download(ioctl_downl),
    .ioctl_upload(ioctl_upl),
    .ioctl_index(ioctl_index),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_din(ioctl_din),
    .ioctl_dout(ioctl_dout)
);

reg [19:0] ce_counter;
reg [7:0] zylon = 8'b00000001;
reg led_dir = 1'b0;
// single LED on MiST, SiDi and Poseidon: in KITT mode it flashes when the light reaches
// either end
assign LED = status[4] ? ~(zylon[0] | zylon[7]) : ~ioctl_downl;

always @(posedge clk_pix) begin
    reg last_status;
    last_status <= status[4];
    if (~last_status & status[4]) begin 
        ce_counter <= 1'b0;
        zylon = 8'b00000001;
        led_dir <= 1'b0;
    end
    ce_counter <= ce_counter + 20'd1;
    if (ce_counter == 20'd745000) begin
        ce_counter <= 20'd0;
        if (zylon == 8'd0) begin
            led_dir <= ~led_dir;
            zylon <= led_dir ? 8'b10000000 : 8'b00000001;
        end
        else begin
            zylon <= led_dir ?  {zylon[6:0], 1'b0} : {1'b0, zylon[7:1]};
        end
    end
end

kitt audio(
    .address(kitt_audio_addr),
    .clock(clk_pix),
    .q(kitt_audio_data)
);


reg [14:0] kitt_audio_addr = 15'd0;
reg [9:0] audio_cnt = 10'd0;
wire [7:0] kitt_audio_data;

always @(posedge clk_pix) begin
    reg last_status;
    last_status <= status[4];
    if (~last_status & status[4]) begin
        audio_cnt <= 10'd0;
        kitt_audio_addr <= 15'd0;
    end
    audio_cnt <= audio_cnt + 10'd1;
    if (audio_cnt == 10'd519) begin
        audio_cnt <= 10'd0;
        kitt_audio_addr <= kitt_audio_addr + 15'd1;
        if (kitt_audio_addr == 15'd28215) kitt_audio_addr <= 15'd0;
    end
end

// KITT sound: I2S DAC (Poseidon, SiDi128, also to the HDMI transmitter) and/or
// sigma-delta outputs (MiST, SiDi, SiDi128)
wire [7:0] kitt_audio = status[4] ? kitt_audio_data : 8'h00;   // signed

`ifdef I2S_AUDIO
i2s i2s (
    .reset(1'b0),
    .clk(clk_pix),
    .clk_rate(32'd12_500_000),

    .sclk(I2S_BCK),
    .lrclk(I2S_LRCK),
    .sdata(I2S_DATA),

    .left_chan({kitt_audio[7], kitt_audio, 7'd0}),
    .right_chan({kitt_audio[7], kitt_audio, 7'd0})
);
`endif

`ifdef SIGMA_DELTA_AUDIO
dac #(.C_bits(8)) dac_l (
    .clk_i(clk_ram),
    .res_n_i(pll_locked),
    .dac_i(kitt_audio ^ 8'h80),
    .dac_o(AUDIO_L)
);

assign AUDIO_R = AUDIO_L;
`endif

`ifdef USE_HDMI
// HDMI audio: the same I2S stream (48 kHz, 16 bit, signed), MCLK generated
// by the transmitter
assign HDMI_MCLK  = 1'b0;
assign HDMI_BCK   = I2S_BCK;
assign HDMI_LRCK  = I2S_LRCK;
assign HDMI_SDATA = I2S_DATA;
`endif


reg  [23:0] bmp_data_start;
wire [22:0] downl_addr = ioctl_addr[22:0] - bmp_data_start[22:0];
reg bmp_loaded = 0;
reg port1_req;

always @(posedge clk_sys) begin
    reg ioctl_wr_last = 0;
    reg ioctl_downl_last = 0;

    ioctl_wr_last <= ioctl_wr;
    ioctl_downl_last <= ioctl_downl;

    if (ioctl_downl) begin
        if (~ioctl_wr_last & ioctl_wr) begin
            if (ioctl_addr == 10) bmp_data_start[7:0] <= ioctl_dout;
            else if (ioctl_addr == 11) bmp_data_start[15:8] <= ioctl_dout;
            else if (ioctl_addr == 12) bmp_data_start[23:16] <= ioctl_dout;
            port1_req <= ~port1_req;
        end
    end
    if (ioctl_downl_last & ~ioctl_downl) bmp_loaded <= 1;
end

wire [7:0] file_r, file_g, file_b;

`ifdef BMP_BRAM
// SiDi128: picture in block RAM, shared by the VGA and HDMI outputs
wire  [9:0] hdmi_file_x;
wire  [8:0] hdmi_file_row;
wire [23:0] hdmi_file_q;
wire        clk_hrend;

bmp_bram bmp_bram (
    .clk_sys(clk_sys),
    .ioctl_downl(ioctl_downl),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .data_start(bmp_data_start),
    .a_x(hc),
    .a_row(line_max - 9'd1 - vc),
    .a_q({file_r, file_g, file_b}),
    .clk_b(clk_hrend),
    .b_x(hdmi_file_x),
    .b_row(hdmi_file_row),
    .b_q(hdmi_file_q)
);
`else
wire [31:0] cpu_q;
assign {file_r, file_g, file_b} = cpu_q[23:0];
reg [22:0] cpu1_addr;

// max is ((312 - 1) * 512) + 639) * 4 = 639484 . 20 bits
always @(posedge clk_ram) begin
    cpu1_addr <= (((line_max - 1'd1 - vc) * 640) + hc) << 2;
end

`ifdef POSEIDON
// Poseidon: the SDRAM clock is clk_ram inverted, driven by a DDR register in
// the pin (altddio_out: 0 on the high level, 1 on the low level). It goes out
// through the same kind of output register as the commands and the data,
// with matched delays, half a period ahead (10 ns at 50 MHz). This is what
// the board routing needs (see the NewBrain port for Poseidon).
altddio_out #(
    .extend_oe_disable("OFF"),
    .intended_device_family("Cyclone IV GX"),
    .invert_output("OFF"),
    .lpm_hint("UNUSED"),
    .lpm_type("altddio_out"),
    .oe_reg("UNREGISTERED"),
    .power_up_high("OFF"),
    .width(1)
) sdramclk_ddr (
    .datain_h(1'b0),
    .datain_l(1'b1),
    .outclock(clk_ram),
    .dataout(SDRAM_CLK),
    .aclr(1'b0),
    .aset(1'b0),
    .oe(1'b1),
    .outclocken(1'b1),
    .sclr(1'b0),
    .sset(1'b0)
);
`else
assign SDRAM_CLK = clk_ram;
`endif
assign SDRAM_CKE = 1;

`ifdef POSEIDON
localparam SDRAM_CLK_INV = 1;
`else
localparam SDRAM_CLK_INV = 0;
`endif

sdram #(.MHZ(50), .CLK_INV(SDRAM_CLK_INV)) sdram(
    .SDRAM_DQ(SDRAM_DQ),
    .SDRAM_A(SDRAM_A),
    .SDRAM_DQML(SDRAM_DQML),
    .SDRAM_DQMH(SDRAM_DQMH),
    .SDRAM_BA(SDRAM_BA),
    .SDRAM_nCS(SDRAM_nCS),
    .SDRAM_nWE(SDRAM_nWE),
    .SDRAM_nRAS(SDRAM_nRAS),
    .SDRAM_nCAS(SDRAM_nCAS),

    .init_n(pll_locked),
    .clk( clk_ram),
    .clkref(),

    .port1_req(port1_req),
    .port1_ack(),
    .port1_a({1'b0, downl_addr[22:1]}),
    .port1_ds({downl_addr[0], ~downl_addr[0]}),
    .port1_we(ioctl_downl),
    .port1_d({ioctl_dout, ioctl_dout}),
    .port1_q(),

    .cpu1_addr({1'b0, cpu1_addr[22:2]}),
    .cpu1_q(cpu_q),
    .cpu1_oe(~ioctl_downl)
);

`endif

//______________________________________________________________________________
//
// Video 
//

reg[9:0] hc;
reg[8:0] vc;
reg[9:0] vvc;
reg[1:0] vvc_frac;   // fractional part, for the speed of the classic background
reg[15:0] frame_cnt;
reg[17:0] anim_acc;     // animation counter with 2 fractional bits
wire[15:0] anim = anim_acc[17:2];

reg [22:0] rnd_reg;

wire [22:0] rnd;
lfsr random(rnd);

always @(posedge clk_pix) begin
    if(hc == 799) begin
        hc <= 0;
        if(vc == line_max - 1) begin
            vc <= 0;
            // classic background: 6 per frame at Normal speed
            case (status[26:25])
                2'd1:    {vvc, vvc_frac} <= {vvc, vvc_frac} + 12'd12;   // 3
                2'd2:    {vvc, vvc_frac} <= {vvc, vvc_frac} + 12'd6;    // 1.5
                2'd3:    {vvc, vvc_frac} <= {vvc, vvc_frac} + 12'd48;   // 12
                default: {vvc, vvc_frac} <= {vvc, vvc_frac} + 12'd24;   // 6
            endcase
            frame_cnt <= frame_cnt + 1'd1;
            // Speed: Normal 1, Slow 1/2, Very slow 1/4, Fast 2 steps per frame
            case (status[26:25])
                2'd1:    anim_acc <= anim_acc + 18'd2;
                2'd2:    anim_acc <= anim_acc + 18'd1;
                2'd3:    anim_acc <= anim_acc + 18'd8;
                default: anim_acc <= anim_acc + 18'd4;
            endcase
        end else begin
            vc <= vc + 1'd1;
        end
    end else begin
        hc <= hc + 1'd1;
    end
    
    rnd_reg <= rnd;
end

reg HBlank;
reg HSync, HSync_VGA;
reg VBlank;
reg VSync;

always @(posedge clk_pix) begin
   if (hc == 640+2) begin
       HBlank <= 1;
       if (vc == line_max - 5) VBlank <= 1;
   end
   if (hc == 2) begin
       HBlank <= 0;
       if (vc == 2) VBlank <= 0;
   end

   if (hc == 655) begin
       HSync <= 1;
       HSync_VGA <= 1;
   end
   if (hc == 655+64) HSync <= 0;
   if (hc == 655+96) HSync_VGA <= 0;

   if(vc == line_max-3 && hc == 655) VSync <= 1;
        else if (vc == 0 && hc == 751) VSync <= 0;

end

///// Background, logo and clock (common to all boards)
wire [7:0] R_in, G_in, B_in;

menu_render #(.CLK_HZ(12_500_000)) menu_render (
    .clk(clk_pix),
    .hc(hc),
    .vc(vc),
    .line_max(line_max),
    .anim(anim),
    .vvc(vvc),
    .noise(rnd_reg),
    .status(status),
    .rtc(rtc),
    .file_r(file_r),
    .file_g(file_g),
    .file_b(file_b),
    .file_ok(bmp_loaded),
    .R_in(R_in),
    .G_in(G_in),
    .B_in(B_in)
);

mist_video #(
    .COLOR_DEPTH(8),
    .SD_HCNT_WIDTH(10),
    .OSD_AUTO_CE(0),
    .OUT_COLOR_DEPTH(VGA_BITS),
    .USE_BLANKS(1),
    .BIG_OSD(BIG_OSD)
) mist_video (
    .clk_sys(clk_x2),
    .SPI_SCK(SPI_SCK),
    .SPI_SS3(SPI_SS3),
    .SPI_DI(SPI_DI),
    .R(R_in),
    .G(G_in),
    .B(B_in),
    .HBlank(HBlank),
    .VBlank(VBlank),
    .HSync(scandoubler_disable ? ~HSync : ~HSync_VGA),
    .VSync(~VSync),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_VS(VGA_VS),
    .VGA_HS(VGA_HS),
    .ce_divider(1'b1),
    .rotate({rotate[0], |rotate}),
    .blend(1'b0),
    .scandoubler_disable(scandoubler_disable),
    .scanlines(2'b00),
    .ypbpr(ypbpr),
    .osd_color(osd_color),
    .osd_x_offset(osd_x_offset),
    .osd_y_offset(osd_y_offset),
    .no_csync(no_csync)
);


`ifdef USE_HDMI
//______________________________________________________________________________
//
// HDMI (SiDi128): standard 1080p60, see hdmi_1080p.sv
//

wire clk_hdmi, hdmi_locked;

pll_hdmi pll_hdmi (
    .inclk0(CLOCK_27),
    .c0(clk_hdmi),      // 148.5 MHz
    .c1(clk_hrend),     // 14.85 MHz
    .locked(hdmi_locked)
);

assign HDMI_RST = 1'b1;

hdmi_1080p #(.BIG_OSD(BIG_OSD)) hdmi_1080p (
    .hclk(clk_hdmi),
    .rclk(clk_hrend),
    .locked(hdmi_locked),
    .status(status),
    .rtc(rtc),
    .noise(rnd),
    .wide(status[36]),
    .SPI_SCK(SPI_SCK),
    .SPI_SS3(SPI_SS3),
    .SPI_DI(SPI_DI),
    .rotate({rotate[0], |rotate}),
    .osd_x_offset(osd_x_offset),
    .osd_y_offset(osd_y_offset),
    .osd_color(osd_color),
    .file_x(hdmi_file_x),
    .file_row(hdmi_file_row),
    .file_q(hdmi_file_q),
    .file_ok(bmp_loaded),
    .HDMI_R(HDMI_R),
    .HDMI_G(HDMI_G),
    .HDMI_B(HDMI_B),
    .HDMI_HS(HDMI_HS),
    .HDMI_VS(HDMI_VS),
    .HDMI_DE(HDMI_DE)
);

// Pixel clock to the IT6613, inverted and driven by a DDR register in the pin:
// it latches the data on its rising edge (firmware default), which is then
// in the middle of each pixel (3.4 ns of setup and hold).
altddio_out #(
    .extend_oe_disable("OFF"),
    .intended_device_family("Cyclone 10 LP"),
    .invert_output("OFF"),
    .lpm_hint("UNUSED"),
    .lpm_type("altddio_out"),
    .oe_reg("UNREGISTERED"),
    .power_up_high("OFF"),
    .width(1)
) hdmi_pclk_ddr (
    .datain_h(1'b0),
    .datain_l(1'b1),
    .outclock(clk_hdmi),
    .dataout(HDMI_PCLK),
    .aclr(1'b0),
    .aset(1'b0),
    .oe(1'b1),
    .outclocken(1'b1),
    .sclr(1'b0),
    .sset(1'b0)
);

// I2C to the IT6613: the firmware sends the registers through user_io
i2c_master #(.CLK_Freq(25_000_000), .I2C_Freq(100_000)) i2c_master (
    .CLK         (clk_x2),
    .I2C_START   (i2c_start),
    .I2C_READ    (i2c_read),
    .I2C_ADDR    (i2c_addr),
    .I2C_SUBADDR (i2c_subaddr),
    .I2C_WDATA   (i2c_dout),
    .I2C_RDATA   (i2c_din),
    .I2C_END     (i2c_end),
    .I2C_ACK     (i2c_ack),
    .I2C_SCL     (HDMI_SCL),
    .I2C_SDA     (HDMI_SDA)
);
`endif

endmodule
