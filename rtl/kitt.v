// kitt.v - ROM with the KITT sound (8 bit samples, kitt.mif)
//
// Inferred ROM instead of the altsyncram megafunction, so the same file
// builds in Quartus 13 (MiST, Cyclone III) and newer versions (SiDi,
// Cyclone IV E). Same behaviour as the 1-port ROM it replaces: address and
// output registered, the data comes out two clocks after the address.

module kitt (
    input  wire [14:0] address,
    input  wire        clock,
    output reg   [7:0] q
);

(* ram_init_file = "../rtl/kitt.mif" *) reg [7:0] rom [0:28215];

reg [14:0] addr_r;

always @(posedge clock) begin
    addr_r <= address;
    q      <= rom[addr_r];
end

endmodule
