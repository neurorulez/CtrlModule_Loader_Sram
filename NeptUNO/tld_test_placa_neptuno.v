`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:   01:24:02 08/15/2016 
// Design Name: 
// Module Name:   tld_test_prod_v4 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module tld_test_placa_neptuno (
  input wire clk50mhz,
  //---------------------------
  input wire clkps2,
  input wire dataps2,
  //---------------------------
  inout wire mousedata,
  inout wire mouseclk,
  //---------------------------
  output wire testled1,
  //---------------------------
  output wire [20:0]sram_addr,
  inout wire  [7:0]sram_data,
  output wire sram_we_n,
  output wire sram_oe_n,
  output wire sram_lb_n,
  output wire sram_ub_n,

  output wire sd_cs_n,
  output wire sd_clk,
  output wire sd_mosi,
  input wire sd_miso,
  //---------------------------
  output wire [5:0] r,
  output wire [5:0] g,
  output wire [5:0] b,
  output wire hsync,
  output wire vsync,
  output wire audio_out_left,
  output wire audio_out_right,
  //--------------------------
  output wire stm_rst_n
  );

  assign stm_rst_n = 1'b0;
  assign sram_ub_n = 1'b1;
  assign sram_oe_n = 1'b0;
  assign sram_lb_n = 1'b0;
  
  wire clk100, clk100n, clk14, clk7;
  wire clocks_ready;
  
  wire mode, vga;

  wire [5:0] r_to_vga, g_to_vga, b_to_vga;
  wire hsync_to_vga, vsync_to_vga, csync_to_vga;

  wire memtest_init_fast, memtest_init_slow, memtest_progress, memtest_result;
  wire sdtest_init, sdtest_progress, sdtest_result;
  wire flashtest_init, flashtest_progress, flashtest_result;
  wire sdramtest_init, sdramtest_progress, sdramtest_result;
  wire hidetextwindow;

  wire [2:0] mousebutton;  // M R L
  wire mousetest_init;

  wire [15:0] flash_vendor_id;

   wire joy1up;
   wire joy1down;
   wire joy1left;
   wire joy1right;
   wire joy1fire1;
   wire joy1fire2;
   wire joy1start;
   wire joy2up;
   wire joy2down;
   wire joy2left;
   wire joy2right;
   wire joy2fire1;
   wire joy2fire2;
   wire joy2start;
	
	//assign joyP7_o = 1'b1;
	
	wire [11:0] joy1_o;
	wire [11:0] joy2_o;
	wire clk_joy;
	wire [63:0] RTC;
	
  relojes los_relojes (
   .inclk0(clk50mhz),
   .c0(clk100),
   .c1(clk100n),
   .c2(clk14),
   .c3(clk7),
   .locked(clocks_ready)
   );

	
  switch_mode teclas (
    .clk(clk7),
    .clkps2(clkps2),
    .dataps2(dataps2),
    .mode(mode),
    .vga(vga),
    .sdtest(sdtest_init),
    //.flashtest(flashtest_init),
    .mousetest(mousetest_init),
    .sdramtest(sdramtest_init),
	 .memtestf(memtest_init_fast),
	 .memtests(memtest_init_slow),
    //.serialtest(),
    .hidetextwindow(hidetextwindow)
  );

  updater mensajes (
    .clk(clk7),
    .mode(mode),
    .vga(vga),

	 // PARA 6 BOTONES
	 // joystick1 format -- MXYZ SA UDLR BC       joy1_o [11:0] -- MXYZ SACB RLDU	 
	 .joystick1(~{joy1_o[11], joy1_o[10],joy1_o[9],joy1_o[8],joy1_o[7],joy1_o[6],joy1_o[3],joy1_o[2],joy1_o[1],joy1_o[0],joy1_o[4],joy1_o[5]}),
	 // joystick2 format -- MXYZ SA UDLR BC       joy2_o [11:0] -- MXYZ SACB RLDU 
	 .joystick2(~{joy2_o[11], joy2_o[10],joy2_o[9],joy2_o[8],joy2_o[7],joy2_o[6],joy2_o[3],joy2_o[2],joy2_o[1],joy2_o[0],joy2_o[4],joy2_o[5]}),  
    .rtc({data1,data2,data3,data4,data5,data6,data7,data8}),
	 //.joystick1({joy1up,joy1down,joy1left,joy1right,joy1fire1,joy1fire2}),
    //.joystick2({joy2up,joy2down,joy2left,joy2right,joy2fire1,joy2fire2}),

    .memtest_progress(memtest_progress),
    .memtest_result(memtest_result),
    .sdtest_progress(sdtest_progress),
    .sdtest_result(sdtest_result),
    .flashtest_progress(flashtest_progress),
    .flashtest_result(flashtest_result),
    .flash_vendor_id(flash_vendor_id),
    .sdramtest_progress(sdramtest_progress),
    .sdramtest_result(sdramtest_result),
    .mousebutton(mousebutton),
    .hidetextwindow(hidetextwindow),
    
    .r(r_to_vga),
    .g(g_to_vga),
    .b(b_to_vga),
    .hsync(hsync_to_vga),
    .vsync(vsync_to_vga),
    .csync(csync_to_vga)
    );

  vga_scandoubler #(.CLKVIDEO(7000)) modo_vga (
    .clkvideo(clk7),
    .clkvga(clk14),
    .enable_scandoubling(vga),
    .disable_scaneffect(1'b1),
    .ri(r_to_vga),
    .gi(g_to_vga),
    .bi(b_to_vga),
    .hsync_ext_n(hsync_to_vga),
    .vsync_ext_n(vsync_to_vga),
    .csync_ext_n(csync_to_vga),
    .ro(r),
    .go(g),
    .bo(b),
    .hsync(hsync),
    .vsync(vsync)
  );

  wire [24:0]ioctl_addr;
  wire [7:0]ioctl_data;
  wire ioctl_wr;
  wire ioctl_dowload;
  
  data_io data_io
  (
		.clk(clk50mhz), 			
		.reset_n(clocks_ready), //pll_locked
		// SD card interface
		.spi_miso(sd_miso),
		.spi_mosi(sd_mosi),
		.spi_clk(sd_clk),
		.spi_cs(sd_cs_n),
		// Rom Download
		.ioctl_addr(ioctl_addr),
		.ioctl_data(ioctl_data),
		.ioctl_wr(ioctl_wr),
		.ioctl_download(ioctl_dowload),
 );


reg [7:0]data1,data2,data3,data4,data5,data6,data7,data8;
reg [2:0]cnt,cnt_r;
reg [20:0]sram_addr_read;
always @(posedge clk14) begin
if (!ioctl_dowload) begin
sram_addr_read <= 21'h2FFF8 + cnt;
cnt_r <= cnt;
	case(cnt_r)
   3'b000 : begin data1 <= sram_data; end
	3'b001 : begin data2 <= sram_data; end
	3'b010 : begin data3 <= sram_data; end
	3'b011 : begin data4 <= sram_data; end
	3'b100 : begin data5 <= sram_data; end
	3'b101 : begin data6 <= sram_data; end
	3'b110 : begin data7 <= sram_data; end
	3'b111 : begin data8 <= sram_data; end
	endcase
cnt <= cnt + 1;
end
end

//wire   [7:0]data1 = sram_data; //  ioctl_dowload ? "00000000" : sram_data;
assign sram_addr = ioctl_dowload ? ioctl_addr[20:0] : sram_addr_read; //21'h2FFFF;
assign sram_data = ioctl_dowload ? ioctl_data : 21'hZZZZZ; 
assign sram_we_n = ~ioctl_wr; //ioctl_dowload ? ~ioctl_wr : 1'b1;
assign testled1 = ~ioctl_dowload;
 
endmodule
