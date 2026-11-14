# Restricciones del menu para la SiDi128.
#
#   pll      (CLOCK_50): clk[0] 50 MHz clk_sys, clk[1] 25 MHz, clk[2] 12,5 MHz pixel VGA
#   pll_hdmi (CLOCK_27): clk[0] 148,5 MHz HDMI, clk[1] 14,85 MHz render HDMI
# Los dos PLL son asincronos entre si. Dentro de pll_hdmi los dos relojes son
# multiplos exactos (el render escribe y la parte HDMI lee el buffer de lineas)
# y se analizan como relacionados.

create_clock -name "CLOCK_50" -period 20.000 [get_ports {CLOCK_50}]
create_clock -name "CLOCK_27" -period 37.037 [get_ports {CLOCK_27}]
create_clock -name {SPI_SCK}  -period 41.666 -waveform { 20.8 41.666 } [get_ports {SPI_SCK}]

derive_pll_clocks -create_base_clocks

set hdmi_clk "pll_hdmi|altpll_component|auto_generated|pll1|clk[0]"
set rend_clk "pll_hdmi|altpll_component|auto_generated|pll1|clk[1]"
set sys_clk  "pll|altpll_component|auto_generated|pll1|clk[1]"

# Reloj de pixel hacia el IT6613: clk[0] invertido, sacado por un registro DDR
create_generated_clock -name hdmi_pclk -source [get_pins {pll_hdmi|altpll_component|auto_generated|pll1|clk[0]}] -invert [get_ports {HDMI_PCLK}]

derive_clock_uncertainty

set_clock_groups -asynchronous \
    -group [get_clocks {SPI_SCK}] \
    -group [get_clocks {pll|altpll_component|auto_generated|pll1|clk[*]}] \
    -group [get_clocks {pll_hdmi|altpll_component|auto_generated|pll1|clk[*] hdmi_pclk}]

set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {CONF_DATA0}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_DI}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SCK}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS2}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {SPI_SCK}]  1.000 [get_ports {SPI_SS3}]
set_output_delay -clock [get_clocks {SPI_SCK}] 1.000 [get_ports {SPI_DO}]

set_output_delay -clock [get_clocks $sys_clk] 1.000 [get_ports {VGA_*}]

# IT6613: setup 1,0 ns, hold 0,5 ns respecto al flanco de subida de PCLK
set_output_delay -clock [get_clocks {hdmi_pclk}] -max  1.0 [get_ports {HDMI_R[*] HDMI_G[*] HDMI_B[*] HDMI_HS HDMI_VS HDMI_DE}]
set_output_delay -clock [get_clocks {hdmi_pclk}] -min -0.5 [get_ports {HDMI_R[*] HDMI_G[*] HDMI_B[*] HDMI_HS HDMI_VS HDMI_DE}]

# Senales lentas o sin relacion de tiempo
set_false_path -to [get_ports {LED AUDIO_L AUDIO_R I2S_* HDMI_BCK HDMI_LRCK HDMI_SDATA HDMI_MCLK HDMI_RST HDMI_SDA HDMI_SCL}]
set_false_path -from [get_ports {HDMI_SDA HDMI_SCL AUDIO_IN}]
