# Genera board_logo.sv: el nombre de la placa en negrita, alfa de 2 bits, con
# la relacion de aspecto de la pantalla (lineas 5/3 mas altas que los pixeles)
#
# Uso: python3 gen_logo.py TEXTO R G B salida.sv [fuente.ttf]
#   p. ej. python3 gen_logo.py SiDi 232 112 0 ../sidi/board_logo.sv
import sys
from PIL import Image, ImageDraw, ImageFont
TEXT = sys.argv[1]
COLOR = tuple(int(v) for v in sys.argv[2:5])
OUT = sys.argv[5]
FONT = sys.argv[6] if len(sys.argv) > 6 else "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
CAP_LINES = 16          # altura de las mayusculas en lineas (como "Calypso")
LH = 22                 # alto del bitmap (igual que el logo de Calypso)
TOP = 1                 # primera linea del texto dentro del bitmap
ASPECT = 5 / 3          # una linea es 5/3 de alto respecto a un pixel de ancho

f = ImageFont.truetype(FONT, 400)
im = Image.new("L", (2000, 600), 0)
ImageDraw.Draw(im).text((20, 20), TEXT, font=f, fill=255)
im = im.crop(im.getbbox())
w, h = im.size
tw = round(w * CAP_LINES * ASPECT / h)
small = im.resize((tw, CAP_LINES), Image.LANCZOS)
LW = tw + 2
bmp = Image.new("L", (LW, LH), 0)
bmp.paste(small, (1, TOP))
px = bmp.load()

def a2(v):
    return 3 if v >= 192 else 2 if v >= 112 else 1 if v >= 40 else 0

rows = []
for y in range(LH):
    bits = 0
    for x in range(LW):
        bits = (bits << 2) | a2(px[x, y])
    rows.append(bits)

LX = 640 - 12 - LW
nb = 2 * LW
hexw = (nb + 3) // 4
out = []
out.append("// board_logo.sv - \"%s\" logo for the menu backgrounds" % TEXT)
out.append("// Shaeon (Carlos Palmero), 2026")
out.append("//")
out.append("// \"%s\" in bold sans, stored as a %dx%d 2-bit alpha bitmap (generated" % (TEXT, LW, LH))
out.append("// with tools/gen_logo.py). Same place as the Calypso logo: bottom right corner,")
out.append("// right margin 12 px, 17 lines from the bottom.")
out.append("")
out.append("`default_nettype none")
out.append("")
out.append("module board_logo (")
out.append("    input  wire        clk,               // pixel clock")
out.append("    input  wire  [9:0] hc,")
out.append("    input  wire  [8:0] vc,")
out.append("    input  wire  [8:0] line_max,")
out.append("    output reg   [1:0] alpha,             // 0 transparent .. 3 opaque")
out.append("    output wire  [7:0] color_r,           // logo color")
out.append("    output wire  [7:0] color_g,")
out.append("    output wire  [7:0] color_b")
out.append(");")
out.append("")
out.append("localparam int LW = %d;" % LW)
out.append("localparam int LH = %d;" % LH)
out.append("localparam int LX = %d;" % LX)
out.append("")
out.append("assign color_r = 8'd%d;" % COLOR[0])
out.append("assign color_g = 8'd%d;" % COLOR[1])
out.append("assign color_b = 8'd%d;" % COLOR[2])
out.append("")
out.append("function automatic [2*LW-1:0] logo_row(input [4:0] row);")
out.append("    case (row)")
for y, r in enumerate(rows):
    out.append("        5'd%d: logo_row = %d'h%0*x;" % (y, nb, hexw, r))
out.append("        default: logo_row = '0;")
out.append("    endcase")
out.append("endfunction")
out.append("")
out.append("wire [8:0] ly0 = line_max - 9'd38;     // first line of the logo")
out.append("")
out.append("always @(posedge clk) begin")
out.append("    reg [2*LW-1:0] bits;")
out.append("    reg [9:0] x;")
out.append("    reg [8:0] y;")
out.append("    alpha <= 2'd0;")
out.append("    if (hc >= LX && hc < LX + LW && vc >= ly0 && vc < ly0 + LH) begin")
out.append("        x    = hc - LX[9:0];")
out.append("        y    = vc - ly0;")
out.append("        bits = logo_row(y[4:0]);")
out.append("        alpha <= bits[2*(LW-1-x) +: 2];")
out.append("    end")
out.append("end")
out.append("")
out.append("endmodule")
open(OUT, "w").write("\n".join(out) + "\n")
print("LW", LW, "LX", LX)
# preview a escala (aplicando aspecto)
prev = Image.new("RGB", (LW, LH), (40, 60, 120))
pp = prev.load()
for y in range(LH):
    for x in range(LW):
        a = a2(px[x, y])
        bg = pp[x, y]; fg = COLOR
        pp[x, y] = tuple((bg[i] * (3 - a) + fg[i] * a) // 3 for i in range(3))
prev.resize((LW * 6, round(LH * 6 * ASPECT)), Image.NEAREST).save(OUT.replace(".sv", "_preview.png"))
