/***************************************************************
 Z80_IP INTERFACE < Fz80c >
***************************************************************/
module Z80IP(

ADRS,
DINP,
DOUT,
BUSWO,
RESET_N,
INT_N,
NMI_N,
WAIT_N,
M1_N,
MREQ_N,
IORQ_N,
RD_N,
WR_N,
RFSH_N,
HALT_N,
CLK2X,
CLK

);

// I/O assign
output [15:0] ADRS;
input  [7:0] DINP;
output [7:0] DOUT;
input  RESET_N,INT_N,NMI_N,WAIT_N,CLK2X,CLK;
output M1_N,MREQ_N,IORQ_N,RD_N,WR_N,RFSH_N,HALT_N,BUSWO;

// Z80IP interface
fz80c z80core(
  // Inputs
.reset_n(RESET_N),
.clk(CLK),
.wait_n(WAIT_N),
.int_n(INT_N),
.nmi_n(NMI_N),
.busrq_n(1'b1),
.di(DINP),
 // Outputs
.m1_n(M1_N),
.mreq_n(MREQ_N),
.iorq_n(IORQ_N),
.rd_n(RD_N),
.wr_n(WR_N),
.rfsh_n(RFSH_N),
.halt_n(HALT_N),
.busak_n(),
.A(ADRS),
.At(),
.do(DOUT),
.dt()

);


endmodule
