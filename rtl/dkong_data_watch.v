//===============================================================================
// FPGA DONKEY KONG  CPU DATA WATCH
//
// Version : 1.00
//
// Copyright(c) 2005  Katsumi Degawa , All rights reserved
//
// Important !
//
// This program is freeware for non-commercial use. 
// An author does no guarantee about this program.
// You can use this under your own risk.
//
//================================================================================



module dkong_data_watch(

I_CPU_CLK,
I_CPU_MREQn,
I_CPU_WRn,
I_CPU_ADDR,
I_CPU_D,

O_DAT

);

input  I_CPU_CLK;
input  I_CPU_MREQn;
input  I_CPU_WRn;
input  [14:0]I_CPU_ADDR;
input  [7:0]I_CPU_D;

output [1:0]O_DAT;

reg    [1:0]d_watch;
assign O_DAT = d_watch;

always@(negedge I_CPU_CLK)
begin
  if(~(I_CPU_MREQn | I_CPU_WRn))begin
    if(I_CPU_ADDR== 15'h600A)begin    //  ON GAME
      if(I_CPU_D >= 8'h0B && I_CPU_D <= 8'h0D) 
        d_watch[0] <= 1;
      else
        d_watch[0] <= 0;
    end
    if(I_CPU_ADDR== 15'h639E)begin
      if(I_CPU_D == 8'h00)             //  MARIO DIED..
        d_watch[1] <= 0;
      else
        d_watch[1] <= 1;
    end
  end
end

endmodule