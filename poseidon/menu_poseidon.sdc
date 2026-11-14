# Restricciones del menu para la Poseidon (50 MHz de entrada).
#
# SDRAM_CLK sale de un registro DDR del pin (sdramclk_ddr en menu_top.sv) que
# da clk_ram (clk[0], 50 MHz) invertido, adelantado medio periodo, como en el
# port del NewBrain para Poseidon. Si TimeQuest se queja de las rutas de la
# SDRAM, los retardos de abajo son lo primero que hay que ajustar.

create_clock -name "CLOCK_50" -period 20.000 [get_ports {CLOCK_50}]
create_clock -name {SPI_SCK}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {SPI_SCK}]

# Automatically constrain PLL and other generated clocks
derive_pll_clocks -create_base_clocks

create_generated_clock -name sdram_clk -source [get_pins {pll|altpll_component|auto_generated|pll1|clk[0]}] -invert [get_ports {SDRAM_CLK}]

# Automatically calculate clock uncertainty to jitter and other effects.
derive_clock_uncertainty

set_clock_groups -asynchronous \
    -group [get_clocks {SPI_SCK}] \
    -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*] sdram_clk}]

set sys_clk "pll|altpll_component|auto_generated|pll1|clk[1]"

set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {CONF_DATA0}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_DI}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SCK}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS2}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS3}]

# SDRAM: retardos contra sdram_clk (los del NewBrain para Poseidon)
set_input_delay -clock [get_clocks {sdram_clk}] -max 6.4 [get_ports SDRAM_DQ[*]]
set_input_delay -clock [get_clocks {sdram_clk}] -min 3.2 [get_ports SDRAM_DQ[*]]

set_output_delay -clock [get_clocks {sdram_clk}] -max 1.5 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]
set_output_delay -clock [get_clocks {sdram_clk}] -min -0.8 [get_ports {SDRAM_D* SDRAM_A* SDRAM_BA* SDRAM_n* SDRAM_CKE}]

set_output_delay -clock [get_clocks {SPI_SCK}] 1.000 [get_ports {SPI_DO}]
set_output_delay -clock [get_clocks $sys_clk]  1.000 [get_ports {VGA_*}]
