//===============================================================================
// FPGA DONKEY KONG ALTERA CYCLONE BLOCK RAM I/F
//
// Version : 4.00
//
// Copyright(c) 2003 - 2004 Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
// 2004- 8-24 added module (ram_1024_8_8).  K.Degawa
// 2005- 2- 9 It had modification for V4.00.  K.Degawa
//================================================================================

//------ RAM 1024 * 8bit -----------------------------------------
module  ram_1024_8_8(
//   A Port
I_CLKA,
I_ADDRA,
I_DA,
I_CEA,
I_WEA,
O_DA,
//   B Port
I_CLKB,
I_ADDRB,
I_DB,
I_CEB,
I_WEB,
O_DB

);

input  I_CLKA,I_CLKB;
input  [9:0]I_ADDRA,I_ADDRB;
input  [7:0]I_DA,I_DB;
input  I_CEA,I_CEB;
input  I_WEA,I_WEB;
output [7:0]O_DA,O_DB;

wire   [7:0]W_DOA,W_DOB;
assign O_DA = I_CEA ? W_DOA : 8'h00;
assign O_DB = I_CEB ? W_DOB : 8'h00;

cyc_ram_1024_8_8 ram_1024_8_8(

.clock_a(I_CLKA),
.address_a(I_ADDRA),
.data_a(I_DA),
.enable_a(I_CEA),	
.wren_a(I_WEA),
.q_a(W_DOA),

.clock_b(I_CLKB),
.address_b(I_ADDRB),
.data_b(I_DB),
.enable_b(I_CEB),
.wren_b(I_WEB),
.q_b(W_DOB)

);


endmodule

//------ RAM 1024 * 8bit -----------------------------------------
module  ram_1024_8(

I_CLK,
I_ADDR,
I_D,
I_CE,
I_WE,
O_D

);

input  I_CLK;
input  [9:0]I_ADDR;
input  [7:0]I_D;
input  I_CE;
input  I_WE;
output [7:0]O_D;

wire   [7:0]W_DO;
assign O_D = I_CE ? W_DO : 8'h00;

cyc_ram_1024_8 ram_1024_8(

.clock(I_CLK),
.address(I_ADDR),
.data(I_D),
.wren(I_WE),
.clken(I_CE),
.q(W_DO)

);


endmodule

//   dkong_vram.v used
module  ram_2N(

I_CLK,
I_ADDR,
I_D,
I_CE,
I_WE,
O_D

);

input  I_CLK;
input  [7:0]I_ADDR;
input  [3:0]I_D;
input  I_CE;
input  I_WE;
output [3:0]O_D;

cyc_ram_256_4 ram_256_4(

.clock(I_CLK),
.address(I_ADDR),
.data(I_D),
.wren(I_WE),
.enable(I_CE),
.q(O_D)

);


endmodule

//   dkong_obj.v used
module  ram_2EH7M(

I_CLKA,
I_ADDRA,
I_DA,
I_CEA,
I_WEA,
O_DA,
//   B Port
I_CLKB,
I_ADDRB,
I_DB,
I_CEB,
I_WEB,
O_DB

);

input  I_CLKA,I_CLKB;
input  [7:0]I_ADDRA;
input  [5:0]I_ADDRB;
input  [5:0]I_DA;
input  [8:0]I_DB;
input  I_CEA,I_CEB;
input  I_WEA,I_WEB;
output [5:0]O_DA;
output [8:0]O_DB;

wire   [7:0]W_DOA;
assign O_DA = W_DOA[5:0];

wire   [15:0]W_DOB;
assign O_DB = W_DOB[8:0]; 

cyc_ram_512_8_256_16 ram_2EH7M(

.clock_a(I_CLKA),
.address_a({1'b0,I_ADDRA}),
.data_a({2'b00,I_DA}),
.enable_a(I_CEA),	
.wren_a(I_WEA),
.q_a(W_DOA),

.clock_b(I_CLKB),
.address_b({2'b11,I_ADDRB}),
.data_b({7'b0000000,I_DB}),
.enable_b(I_CEB),
.wren_b(I_WEB),
.q_b(W_DOB)

);


endmodule

//   dkong_col_pal.v used
module  ram_2EF(
//   A Port
I_CLKA,
I_ADDRA,
I_DA,
I_CEA,
I_WEA,
O_DA,
//   B Port
I_CLKB,
I_ADDRB,
I_DB,
I_CEB,
I_WEB,
O_DB

);

input  I_CLKA,I_CLKB;
input  [7:0]I_ADDRA,I_ADDRB;
input  [7:0]I_DA,I_DB;
input  I_CEA,I_CEB;
input  I_WEA,I_WEB;
output [7:0]O_DA,O_DB;

cyc_ram_512_8_8 ram_512_8_8(

.clock_a(I_CLKA),
.address_a({1'b0,I_ADDRA}),
.data_a(I_DA),
.enable_a(I_CEA),	
.wren_a(I_WEA),
.q_a(O_DA),

.clock_b(I_CLKB),
.address_b({1'b1,I_ADDRB}),
.data_b(I_DB),
.enable_b(I_CEB),
.wren_b(I_WEB),
.q_b(O_DB)

);


endmodule

//  vga i/f
module  double_scan(
//   A Port
I_CLKA,
I_ADDRA,
I_DA,
I_CEA,
I_WEA,
O_DA,
//   B Port
I_CLKB,
I_ADDRB,
I_DB,
I_CEB,
I_WEB,
O_DB

);

input  I_CLKA,I_CLKB;
input  [8:0]I_ADDRA,I_ADDRB;
input  [7:0]I_DA,I_DB;
input  I_CEA,I_CEB;
input  I_WEA,I_WEB;
output [7:0]O_DA,O_DB;

cyc_ram_512_8_8 ram_512_8_8(

.clock_a(I_CLKA),
.address_a(I_ADDRA),
.data_a(I_DA),
.enable_a(I_CEA),	
.wren_a(I_WEA),
.q_a(O_DA),

.clock_b(I_CLKB),
.address_b(I_ADDRB),
.data_b(I_DB),
.enable_b(I_CEB),
.wren_b(I_WEB),
.q_b(O_DB)

);


endmodule

//  i8035_ip
module  ram_64_8(

I_CLK,
I_ADDR,
I_D,
I_CE,
I_WE,
O_D

);

input  I_CLK;
input  [5:0]I_ADDR;
input  [7:0]I_D;
input  I_CE;
input  I_WE;
output [7:0]O_D;

cyc_ram_64_8 ram_64_8(

.clock(I_CLK),
.address(I_ADDR),
.data(I_D),
.wren(I_WE),
.clken(I_CE),
.q(O_D)

);


endmodule

//  sound
module  ram_2048_8(

I_CLK,
I_ADDR,
I_D,
I_CE,
I_WE,
O_D

);

input  I_CLK;
input  [10:0]I_ADDR;
input  [7:0]I_D;
input  I_CE;
input  I_WE;
output [7:0]O_D;

cyc_ram_2048_8 ram_2048_8(

.clock(I_CLK),
.address(I_ADDR),
.data(I_D),
.wren(I_WE),
.clken(I_CE),
.q(O_D)

);


endmodule
