//============================================================================
// 
//  Port to MiSTer.
//  Copyright (C) 2018 Sorgelig
//
//  Arkanoid for MiSTer
//  Copyright (C) 2018, 2020 Ace, Enforcer, Ash Evans (aka ElectronAsh/OzOnE)
//  and Kitrinx (aka Rysha)
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the 
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
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
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

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

	//SDRAM interface with lower latency
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

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	output		USER_OSD,
	output  [1:0] USER_MODE,
	input	[7:0] USER_IN,
	output	[7:0] USER_OUT,
	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;

wire         CLK_JOY = CLK_50M;         //Assign clock between 40-50Mhz
wire   [2:0] JOY_FLAG  = {status[62],status[63],status[61]}; //Assign 3 bits of status o (63:61)
wire         JOY_CLK, JOY_LOAD, JOY_SPLIT, JOY_MDSEL;
wire   [5:0] JOY_MDIN  = JOY_FLAG[2] ? {USER_IN[6],USER_IN[3],USER_IN[5],USER_IN[7],USER_IN[1],USER_IN[2]} : '1;
wire         JOY_DATA  = JOY_FLAG[1] ? USER_IN[5] : '1;
assign       USER_OUT  = JOY_FLAG[2] ? {3'b111,JOY_SPLIT,3'b111,JOY_MDSEL} : JOY_FLAG[1] ? {6'b111111,JOY_CLK,JOY_LOAD} : '1;
assign       USER_MODE = JOY_FLAG[2:1] ;
assign       USER_OSD  = joydb_1[10] & joydb_1[6];

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign FB_FORCE_BLANK = 0;
assign HDMI_FREEZE = 0;

wire [15:0] audio;
assign AUDIO_L = audio;
assign AUDIO_R = audio;
assign AUDIO_S = 1;
assign AUDIO_MIX = 0;

assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;

///////////////////////////////////////////////////

wire [1:0] ar = status[14:13];

assign VIDEO_ARX = status[12] ? ((!ar) ? 12'd64 : (ar - 1'd1)) : ((!ar) ? 12'd55 : (ar - 1'd1));
assign VIDEO_ARY = status[12] ? ((!ar) ? 12'd55 : 12'd0) : ((!ar) ? 12'd64 : 12'd0);

`include "build_id.v"
parameter CONF_STR = {
	"A.ARKANOID;;",
	"ODE,Aspect Ratio,Original,Full screen,[ARC1],[ARC2];",
	"OC,Orientation,Vert,Horz;",
	"OFH,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"OK,Pad Control,Kbd/Joy/Mouse,Spinner;",
	"OIJ,Spinner Resolution,High,Medium,Low;",
	"O1,SNAC Spinner,Disable,Enable;",
	"-;",
	"oUV,UserIO         ,Off,DB9MD,DB15 ;",
	"oT,UserIO Players, 1 Player,2 Players;",
	"-;",
	"DIP;",
	"OB,Sound chip,YM2149,AY-3-8910;",
	"OA,Volume boost,Off,On;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Fast,Start P1,Coin,Start P2;",
	"jn,A,B,Start,R,Select;",
	"V,v",`BUILD_DATE
};

///////////////////////////////////////////////////

wire        forced_scandoubler;
wire  [1:0] buttons;
wire [63:0] status;
wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;

wire [31:0] joystick_0_USB, joystick_1_USB;
wire [31:0] joy = joystick_0 | joystick_1;
wire [15:0] joystick_analog_0, joystick_analog_1;
wire  [7:0] joya = joystick_analog_0[7:0] ? joystick_analog_0[7:0] : joystick_analog_1[7:0];

wire [21:0] gamma_bus;
wire        direct_video;

wire  [8:0] sp0, sp1;

// S2 CO S1 F2 F1 U D L R * Experimental. It does not work correctly with joysticks. Try with Spinner and report.
wire [31:0] joystick_0 = joydb_1ena ? {joydb_1[9],joydb_1[11]|(joydb_1[10]&joydb_1[5]),joydb_1[10],joydb_1[5:0]} : joystick_0_USB;
wire [31:0] joystick_1 = joydb_2ena ? {joydb_2[10],joydb_2[11]|(joydb_2[10]&joydb_2[5]),joydb_2[9],joydb_2[5:0]} : joydb_1ena ? joystick_0_USB : joystick_1_USB;

wire [15:0] joydb_1 = JOY_FLAG[2] ? JOYDB9MD_1 : JOY_FLAG[1] ? JOYDB15_1 : '0;
wire [15:0] joydb_2 = JOY_FLAG[2] ? JOYDB9MD_2 : JOY_FLAG[1] ? JOYDB15_2 : '0;
wire        joydb_1ena = |JOY_FLAG[2:1]              ;
wire        joydb_2ena = |JOY_FLAG[2:1] & JOY_FLAG[0];

//----BA 9876543210
//----MS ZYXCBAUDLR
reg [15:0] JOYDB9MD_1,JOYDB9MD_2;
joy_db9md joy_db9md
(
  .clk       ( CLK_JOY    ), //40-50MHz
  .joy_split ( JOY_SPLIT  ),
  .joy_mdsel ( JOY_MDSEL  ),
  .joy_in    ( JOY_MDIN   ),
  .joystick1 ( JOYDB9MD_1 ),
  .joystick2 ( JOYDB9MD_2 )	  
);

//----BA 9876543210
//----LS FEDCBAUDLR
reg [15:0] JOYDB15_1,JOYDB15_2;
joy_db15 joy_db15
(
  .clk       ( CLK_JOY   ), //48MHz
  .JOY_CLK   ( JOY_CLK   ),
  .JOY_DATA  ( JOY_DATA  ),
  .JOY_LOAD  ( JOY_LOAD  ),
  .joystick1 ( JOYDB15_1 ),
  .joystick2 ( JOYDB15_2 )	  
);


hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(CLK_12M),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	
	.forced_scandoubler(forced_scandoubler),

	.buttons(buttons),
	.status(status),
	.status_menumask({use_io,direct_video}),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joystick_0_USB),
	.joystick_1(joystick_1_USB),
	.joystick_analog_0(joystick_analog_0),
	.joystick_analog_1(joystick_analog_1),
	.spinner_0(sp0),
	.spinner_1(sp1),
	.joy_raw(joydb_1[5:0]),
	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse)
);

////////////////////   CLOCKS   ///////////////////

wire CLK_12M;
wire CLK_48M;

pll pll
(
	.refclk(CLK_50M),
	.outclk_0(CLK_12M),
	.outclk_1(CLK_48M)
);

wire reset = RESET | status[0] | buttons[1];

////////////////////   Mouse controls by Enforcer   ///////////////////

reg [1:0] spinner_encoder = 2'b11; //spinner encoder is a standard AB type encoder.  as it spins with will use the pattern 00, 01, 11, 10 and repeat.  when it spins the other way the pattern is reversed.

wire [11:0] spres = 12'd2<<(status[19:18] - !m_fast + 1'd1);
reg use_io = 0; // 1 - use encoder on USER_IN[1:0] pins

always @(posedge CLK_12M) begin
	reg [15:0] spin_counter;
	reg        old_state;
	reg  [1:0] old_io;
	reg [11:0] position = 0;
	reg        ce_6m;
	reg [11:0] div_4k;
	reg        use_sp = 0;
	reg  [1:0] old_emu_sp = 0;
	reg  [1:0] new_emu_sp = 0;
	reg  [1:0] old_sp = 0;
	reg  [1:0] new_sp = 0;

	new_emu_sp <= {m_right,m_left};
	new_sp <= {sp1[8],sp0[8]};

	ce_6m <= ~ce_6m;
	if(ce_6m) begin
	
		old_sp <= new_sp;
		if(new_sp ^ old_sp) use_sp <= 1;
		if(new_emu_sp) use_sp <= 0;

		div_4k <= div_4k + 1'd1;
		if(div_4k == 1499) div_4k <= 0;

		if(position != 0) begin //we need to drive position to 0 still;
			if(!div_4k) begin
				case({position[11] , spinner_encoder})
					{1'b1, 2'b00}: spinner_encoder <= 2'b01;
					{1'b1, 2'b01}: spinner_encoder <= 2'b11;
					{1'b1, 2'b11}: spinner_encoder <= 2'b10;
					{1'b1, 2'b10}: spinner_encoder <= 2'b00;
					{1'b0, 2'b00}: spinner_encoder <= 2'b10;
					{1'b0, 2'b10}: spinner_encoder <= 2'b11;
					{1'b0, 2'b11}: spinner_encoder <= 2'b01;
					{1'b0, 2'b01}: spinner_encoder <= 2'b00;
				endcase
				
				if(position[11]) position <= position + 1'b1;
				else position <= position - 1'b1;
			end
		end

		old_state <= ps2_mouse[24];
		if(old_state != ps2_mouse[24]) begin
			use_io <= 0;
			if(!(^position[11:10])) position <= position + {{4{ps2_mouse[4]}}, ps2_mouse[15:8]};
		end

		if(use_sp) begin
			if(old_sp[0] ^ new_sp[0]) begin
				use_io <= 0;
				position <= position + ($signed(sp0[7:0])*$signed(spres));
			end
			if(old_sp[1] ^ new_sp[1]) begin
				use_io <= 0;
				position <= position + ($signed(sp1[7:0])*$signed(spres));
			end
		end
		else if(status[20]) begin
			old_emu_sp <= new_emu_sp;
			//USB Spinner using left/right pulses
			if (~old_emu_sp[1] & new_emu_sp[1]) begin
				use_io <= 0;
				position <= spres;
			end
			if (~old_emu_sp[0] & new_emu_sp[0]) begin
				use_io <= 0;
				position <= -spres;
			end
		end
		else if (joya) begin
			//Analog X - variable speed depending on angle
			use_io <= 0;
			if (spin_counter == 'd48000) begin// roughly 8ms to emulate 125hz standard mouse poll rate
				position <= joya[7:4] ? {{8{joya[7]}}, joya[7:4]} : 12'd1; //joya[7] ? -aspd : aspd;
				spin_counter <= 0;
			end else begin
				spin_counter <= spin_counter + 1'b1;
			end
		end
		else if (m_left | m_right) begin // 0.167us per cycle
			// DPAD left/right
			use_io <= 0;
			if (spin_counter == 'd48000) begin// roughly 8ms to emulate 125hz standard mouse poll rate
				position <= m_right ? (m_fast ? 12'd9 : 12'd4) : (m_fast ? -12'd9 : -12'd4);
				spin_counter <= 0;
			end else begin
				spin_counter <= spin_counter + 1'b1;
			end
		end else begin
			spin_counter <= 0;
		end
	end

	if (~|JOY_FLAG[2:1]) old_io <= USER_IN[1:0];
	if(old_io != USER_IN[1:0]) use_io <= 1;
	if(!status[1]) use_io <= 0;
end

//Process to downgrade encoder pulses from 600 to 300 (Arkanoid Encoder original dps)
//We use a 600 pulses AB Digital encoder

reg [1:0] raw_encoder = 2'b11;
wire encA = USER_IN[0];
wire encB = USER_IN[1];
always @(posedge CLK_12M) begin
	reg encAr;

	encAr <= encA;
	if(encAr != encA) begin 
		case({encA ^ encB, raw_encoder}) //If encoder moves, generate the signal depends of direction. 
			{1'b1, 2'b00}: raw_encoder <= 2'b01;
			{1'b1, 2'b01}: raw_encoder <= 2'b11;
			{1'b1, 2'b11}: raw_encoder <= 2'b10;
			{1'b1, 2'b10}: raw_encoder <= 2'b00;
			{1'b0, 2'b00}: raw_encoder <= 2'b10;
			{1'b0, 2'b10}: raw_encoder <= 2'b11;
			{1'b0, 2'b11}: raw_encoder <= 2'b01;
			{1'b0, 2'b01}: raw_encoder <= 2'b00;
		endcase
	end
end

///////////////////         Keyboard           //////////////////

reg btn_fire  = 0;
reg btn_left  = 0;
reg btn_right = 0;
reg btn_fast  = 0;
reg btn_coin1 = 0;
reg btn_coin2 = 0;
reg btn_service  = 0;
reg btn_1p_start = 0;
reg btn_2p_start = 0;

wire pressed = ps2_key[9];
wire [7:0] code = ps2_key[7:0];
always @(posedge CLK_12M) begin
	reg old_state;
	old_state <= ps2_key[10];
	if(old_state != ps2_key[10]) begin
		case(code)
			'h16: btn_1p_start <= pressed; // 1
			'h1E: btn_2p_start <= pressed; // 2
			'h2E: btn_coin1    <= pressed; // 5
			'h36: btn_coin2    <= pressed; // 6
			'h46: btn_service  <= pressed; // 9

			'h11: btn_fast     <= pressed; // alt
			'h6B: btn_left     <= pressed; // left
			'h74: btn_right    <= pressed; // right
			'h29: btn_fire     <= pressed; // space						
		endcase
	end
end

//////////////////  Arcade Buttons/Interfaces   ///////////////////////////

wire m_fire   = btn_fire     | joy[4] | |ps2_mouse[1:0] | (use_io & ~USER_IN[3]);
wire m_fast   = btn_fast     | joy[5];
wire m_start1 = btn_1p_start | joy[6];
wire m_start2 = btn_2p_start | joy[8];
wire m_coin1  = btn_coin1    | joy[7];
wire m_coin2  = btn_coin2;
wire m_left   = btn_left     | joy[1];
wire m_right  = btn_right    | joy[0];

reg [7:0] dip_sw[8];	// Active-LOW
always @(posedge CLK_12M) begin
	if(ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3])
		dip_sw[ioctl_addr[2:0]] <= ioctl_dout;
end
/*DIP switches are in reverse order when compared to this table (sourced from MAME Arkanoid driver):
+-----------------------------+--------------------------------+
|FACTORY DEFAULT = *          |  1   2   3   4   5   6   7   8 |
+----------+------------------+----+---------------------------+
|CABINET   | COCKTAIL         | OFF|                           |
|          |*UPRIGHT          | ON |                           |
+----------+------------------+----+---------------------------+
|COINS     |*1 COIN  1 CREDIT |    |OFF|                       |
|          | 1 COIN  2 CREDITS|    |ON |                       |
+----------+------------------+----+---+---+                   |
|LIVES     |*3                |        |OFF|                   |
|          | 5                |        |ON |                   |
+----------+------------------+--------+---+---+               |
|BONUS     |*20000 / 60000    |            |OFF|               |
|1ST/EVERY | 20000 ONLY       |            |ON |               |
+----------+------------------+------------+---+---+           |
|DIFFICULTY|*EASY             |                |OFF|           |
|          | HARD             |                |ON |           |
+----------+------------------+----------------+---+---+       |
|GAME MODE |*GAME             |                    |OFF|       |
|          | TEST             |                    |ON |       |
+----------+------------------+--------------------+---+---+   |
|SCREEN    |*NORMAL           |                        |OFF|   |
|          | INVERT           |                        |ON |   |
+----------+------------------+------------------------+---+---+
|CONTINUE  | WITHOUT          |                            |OFF|
|          |*WITH             |                            |ON |
+----------+------------------+----------------------------+---+
*/

///////////////                 Video                  ////////////////

wire hblank, vblank;
wire hs, vs;
wire [3:0] r,g,b;

reg ce_pix;
always @(posedge CLK_48M) begin
	reg [2:0] div;
	
	div <= div + 1'd1;
	ce_pix <= !div;
end

wire rotate_ccw = 0;
wire no_rotate = status[12] | direct_video;
screen_rotate screen_rotate(.*);

arcade_video #(256,12) arcade_video
(
	.*,

	.clk_video(CLK_48M),

	.RGB_in({r,g,b}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(~vs),

	.fx(status[17:15])
);

//Instantiate Arkanoid top-level module
Arkanoid Arkanoid_inst
(
	.reset(~reset),                                   //input reset

	.clk_12m(CLK_12M),                                //input clk_12m

	.spinner(use_io ? raw_encoder : spinner_encoder), //input [1:0] spinner
	
	.coin1(m_coin1),                                  //input coin1
	.coin2(m_coin2),                                  //input coin2
	
	.btn_shot(~m_fire),                               //input btn_shot
	.btn_service(~btn_service),                       //input btn_service
	
	.tilt(1),                                         //input tilt
	
	.btn_1p_start(~m_start1),                         //input btn_1p_start
	.btn_2p_start(~m_start2),                         //input btn_2p_start

	.dip_sw(~dip_sw[0]),                              //input [7:0] dip_sw
	
	.sound(audio),                                    //output [15:0] sound
	
	.video_hsync(hs),                                 //output video_hsync
	.video_vsync(vs),                                 //output video_vsync
	.video_vblank(vblank),                            //output video_vblank
	.video_hblank(hblank),                            //output video_hblank
	
	.video_r(r),                                      //output [3:0] video_r
	.video_g(g),                                      //output [3:0] video_g
	.video_b(b),                                      //output [3:0] video_b
	
	.ym2149_clk_div(status[11]),                      //Easter egg - controls the YM2149 clock divider for bootlegs with overclocked AY-3-8910s (default on)
	.vol_boost(status[10]),                           //Audio volume boost option

	.ioctl_addr(ioctl_addr),
	.ioctl_wr(ioctl_wr && !ioctl_index),
	.ioctl_data(ioctl_dout)
);

endmodule

