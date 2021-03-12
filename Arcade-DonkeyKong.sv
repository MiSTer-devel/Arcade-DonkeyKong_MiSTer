//============================================================================
//  Arcade: Donkey Kong
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================
module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	// Use framebuffer from DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of 16 bytes.
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

`ifdef USE_SDRAM
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,
`endif

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);



assign VGA_F1    = 0;
assign VGA_SCALER= 0;

assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2]|mod_pestplace)  ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2]|mod_pestplace)  ? 8'd3 : 8'd4) : 12'd0;

`include "build_id.v"
localparam CONF_STR = {
	"A.DKONG;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H1H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"H1O7,Flip Screen,Off,On;",
	"OOS,Analog Video H-Pos,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31;",
        "OTV,Analog Video V-Pos,0,1,2,3,4,5,6,7;",
	"-;",
	"DIP;",
	"-;",

	"R0,Reset;",
	"J1,Jump,Start 1P,Start 2P,Coin;",
	"jn,A,Start,Select,R;",

	"V,v",`BUILD_DATE
};

////////////////////   CLOCKS   ///////////////////

wire clk_sys,clk_49;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_49),
	.outclk_1(clk_sys),
	.locked(pll_locked)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;



wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;


hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask({mod_pestplace,direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),


	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);



reg [7:0] sw[8];
always @(posedge clk_sys) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

reg mod_dk = 0;
reg mod_dkjr = 0;
reg mod_dk3 = 0;
reg mod_radarscope=0;
reg mod_pestplace=0;


always @(posedge clk_sys) begin
	reg [7:0] mod = 0;
	if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;

	mod_dk <= (mod == 0);
	mod_dkjr <= (mod == 1);
	mod_dk3 <= (mod == 2);
	mod_radarscope <= (mod == 3);
	mod_pestplace   <= (mod == 4);
end





wire m_up_2     = joy[3];
wire m_down_2   = joy[2];
wire m_left_2   = joy[1];
wire m_right_2  = joy[0];
wire m_fire_2   = joy[4];

wire m_up     = joy[3];
wire m_down   = joy[2];
wire m_left   = joy[1];
wire m_right  = joy[0];
wire m_fire   = joy[4];

wire m_start1 =  joy[5] ;
wire m_start2 =  joy[6] ;
wire m_coin   =  joy[7];


wire hblank, vblank;
wire hs_n, vs_n;
wire [3:0] r,g,b;

reg ce_pix;
always @(posedge clk_49) begin
        reg [2:0] div;

        div <= div + 1'd1;
        ce_pix <= !div;
end

wire no_rotate = status[2] | direct_video | mod_pestplace;
wire rotate_ccw = 0;
screen_rotate screen_rotate (.*);


arcade_video #(256,12) arcade_video
(
	.*,

	.clk_video(clk_49),

	.RGB_in({r,g,b}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(~hs_n),
	.VSync(~vs_n),

	.fx(status[5:3])
);


wire [7:0] audio;
assign AUDIO_L = {audio,audio};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;

assign hblank = hbl[8];

reg  ce_vid;
wire clk_pix;
wire hbl0;
reg [8:0] hbl;
always @(posedge clk_sys) begin
	reg old_pix;
	old_pix <= clk_pix;
	ce_vid <= 0;
	if(~old_pix & clk_pix) begin
		ce_vid <= 1;
		hbl <= (hbl<<1)|hbl0;
	end
end

wire reset = RESET | status[0] | buttons[1]| ioctl_download;



wire [15:0] main_rom_a;
wire [7:0] main_rom_do;
wire [11:0] sub_rom_a;
wire [7:0] sub_rom_do;
wire [18:0] wav_rom_a;
wire [7:0] wav_rom_do;


dpram #(15,8) cpu_rom (
	.clock_a(clk_sys),
	.address_a(main_rom_a[14:0]),
	.q_a(main_rom_do),

	.clock_b(clk_sys),
	.address_b(ioctl_addr[14:0]),
	.wren_b(ioctl_wr && ioctl_download && (ioctl_addr < 'd32768) && !ioctl_index),
	.data_b(ioctl_dout)
	);
dpram #(12,8) snd_rom (
	.clock_a(clk_sys),
	.address_a(sub_rom_a[11:0]),
	.q_a(sub_rom_do),

	.clock_b(clk_sys),
	.address_b(ioctl_addr[11:0]),
	.wren_b(ioctl_wr && ioctl_download && (ioctl_addr < 'hF000 && ioctl_addr >= 'hE000) && !ioctl_index),
	.data_b(ioctl_dout)
	);
dpram #(16,8) wav_rom (
	.clock_a(clk_sys),
	.address_a(wav_rom_a[15:0]),
	.q_a(wav_rom_do),

	.clock_b(clk_sys),
	.address_b(ioctl_addr[15:0]),
	.wren_b(ioctl_wr && ioctl_download && (ioctl_addr >= 'hFF00) && !ioctl_index),
	.data_b(ioctl_dout)
	);





dkong_top dkong(
	.I_CLK_24576M(clk_sys),
	.I_RESETn(~reset),
	.I_U1(~m_up),
	.I_D1(~m_down),
	.I_L1(~m_left),
	.I_R1(~m_right),
	.I_J1(~m_fire),

	.I_U2(~m_up_2),
	.I_D2(~m_down_2),
	.I_L2(~m_left_2),
	.I_R2(~m_right_2),
	.I_J2(~m_fire_2),

	.I_S1(~m_start1),
	.I_S2(~m_start2),
	.I_C1(~m_coin),

	.I_DIP_SW(sw[0]),

	.I_DKJR(mod_dkjr|mod_pestplace|mod_dk3),
	.I_DK3B(mod_dk3),
	.I_RADARSCP(mod_radarscope),
	.I_PESTPLCE(mod_pestplace),

	.O_PIX(clk_pix),

	.flip_screen(status[7]),
	.H_OFFSET(status[28:24]),
	.V_OFFSET(status[31:29]),

	.O_SOUND_DAT(audio),
	.O_VGA_R(r),
	.O_VGA_G(g),
	.O_VGA_B(b),
	.O_H_BLANK(hbl0),
	.O_V_BLANK(vblank),
	.O_VGA_H_SYNCn(hs_n),
	.O_VGA_V_SYNCn(vs_n),

	.DL_ADDR(ioctl_addr[15:0]),
	.DL_WR(ioctl_wr && ioctl_addr[23:16] == 0 && !ioctl_index),
	.DL_DATA(ioctl_dout),
	.MAIN_CPU_A(main_rom_a),
	.MAIN_CPU_DO(main_rom_do),
	.SND_ROM_A(sub_rom_a),
	.SND_ROM_DO( sub_rom_do),
	.WAV_ROM_A(wav_rom_a),
	.WAV_ROM_DO( wav_rom_do)
	);

endmodule
