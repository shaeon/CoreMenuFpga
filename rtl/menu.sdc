# Restricciones del menu para MiST y SiDi (Poseidon: poseidon/menu_poseidon.sdc). El reloj de la SDRAM es clk[0] del
# PLL (50 MHz, sin desfase, como en el core menu de MiST).

create_clock -name "CLOCK_27" -period 37.037 [get_ports {CLOCK_27}]
create_clock -name {SPI_SCK}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {SPI_SCK}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

set_clock_groups -asynchronous \
    -group [get_clocks {SPI_SCK}] \
    -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*]}]

set sdram_clk "pll|altpll_component|auto_generated|pll1|clk[0]"
set sys_clk   "pll|altpll_component|auto_generated|pll1|clk[1]"

set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {CONF_DATA0}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_DI}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SCK}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS2}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS3}]

set_input_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {SDRAM_CLK}] -max 6.6 [get_ports SDRAM_DQ[*]]
set_input_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {SDRAM_CLK}] -min 3.5 [get_ports SDRAM_DQ[*]]

set_output_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {SDRAM_CLK}] -max 1.5 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
set_output_delay -clock [get_clocks $sdram_clk] -reference_pin [get_ports {SDRAM_CLK}] -min -0.8 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]

set_output_delay -clock [get_clocks {SPI_SCK}] 1.000 [get_ports {SPI_DO}]
set_output_delay -clock [get_clocks $sys_clk]  1.000 [get_ports {VGA_*}]
