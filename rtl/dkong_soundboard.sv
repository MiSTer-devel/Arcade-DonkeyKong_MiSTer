module dkong_soundboard(
	input         W_CLK_24576M,
	input         W_CLK_24M,
	input         W_RESETn, // TODO: check async
	input         I_DKJR,   /// 1 = Emulate Donkey Kong JR, 3 or PestPlace (async not a problem)
	input         W_W0_WE,
	input         W_W1_WE,
	input         W_CNF_EN,
	input   [6:0] W_6H_Q,  // TODO: check async
	input         W_5H_Q0,
	input   [1:0] W_4H_Q,
	input   [4:0] W_3D_Q,
	output reg [15:0] O_SOUND_DAT,
	output        O_SACK,
	output [11:0] ROM_A,
	input   [7:0] ROM_D,
	output [18:0] WAV_ROM_A,
	input   [7:0] WAV_ROM_DO
);

wire   [7:0]W_D_S_DAT;

wire    [7:0]I8035_DBI;
wire    [7:0]I8035_DBO;
wire    [7:0]I8035_PAI;
wire    [7:0]I8035_PBI;
wire    [7:0]I8035_PBO;
wire    I8035_ALE;
wire    I8035_RDn;
wire    I8035_PSENn;
reg     I8035_CLK_EN;
wire    I8035_INTn;
wire    I8035_T0;
wire    I8035_T1;
wire    I8035_RSTn;

// emulate 6 MHz crystal oscillor
reg [1:0] cnt;
always @(posedge W_CLK_24M) begin
	cnt <= cnt + 1'd1;
	I8035_CLK_EN <= cnt == 0;
end

I8035IP SOUND_CPU
(
	.I_CLK(W_CLK_24M),
	.I_CLK_EN(I8035_CLK_EN),
	.I_RSTn(I8035_RSTn),
	.I_INTn(I8035_INTn),
	.I_EA(1'b1),
	.O_PSENn(I8035_PSENn),
	.O_RDn(I8035_RDn),
	.O_WRn(),
	.O_ALE(I8035_ALE),
	.O_PROGn(),
	.I_T0(I8035_T0),
	.O_T0(),
	.I_T1(I8035_T1),
	.I_DB(I8035_DBO),
	.O_DB(I8035_DBI),
	.I_P1(8'h00),
	.O_P1(I8035_PAI),
	.I_P2(I8035_PBO),
	.O_P2(I8035_PBI)
);
assign O_SACK = I8035_PBI[4]; // TODO: check async.
//-------------------------------------------------

dkong_sound Digtal_sound
(
	.I_CLK(W_CLK_24M),
	.I_RST(W_RESETn),
	.I_DKJR(I_DKJR),
	.I8035_DBI(I8035_DBI),
	.I8035_DBO(I8035_DBO),
	.I8035_PAI(I8035_PAI),
	.I8035_PBI(I8035_PBI),
	.I8035_PBO(I8035_PBO),
	.I8035_ALE(I8035_ALE),
	.I8035_RDn(I8035_RDn),
	.I8035_PSENn(I8035_PSENn),
	.I8035_RSTn(I8035_RSTn),
	.I8035_INTn(I8035_INTn),
	.I8035_T0(I8035_T0),
	.I8035_T1(I8035_T1),
	.I_SOUND_DAT(I_DKJR ? ~W_3D_Q : {1'b1, W_3D_Q[3:0]}),
	.I_SOUND_CNT(I_DKJR ? {W_4H_Q[1],W_6H_Q[6:3],W_5H_Q0} : {2'b11,W_6H_Q[5:3],W_5H_Q0}),
	.O_SOUND_DAT(W_D_S_DAT),
	.ROM_A(ROM_A),
	.ROM_D(ROM_D)
);

//----    DAC  I/F     ------------------------

localparam CLOCK_RATE = 24000000;
localparam SAMPLE_RATE = 48000;
localparam [8:0] clocks_per_sample = 24000000 / 48000;

// Wav sound recored at 11025 Hz rate, 8 bit unsigned
dkong_wav_sound #(
	.CLOCK_RATE(CLOCK_RATE)
) Analog_sound (
	.I_CLK(W_CLK_24M),
	.I_RSTn(W_RESETn),
	.I_SW(I_DKJR ? 2'b00 : W_6H_Q[2:1]),
	.O_ROM_AB(WAV_ROM_A)
);

reg[8:0] audio_clk_counter;
reg audio_clk_en;
always@(posedge W_CLK_24M, negedge W_RESETn) begin
	if(!W_RESETn)begin
		audio_clk_en <= 0;
		audio_clk_counter <= 0;
	end else begin
		if(audio_clk_counter != (clocks_per_sample - 9'd1))begin
			audio_clk_en <= 0;
			audio_clk_counter <= audio_clk_counter + 9'd1;
		end else begin
			audio_clk_en <= 1;
			audio_clk_counter <= 0;
		end
	end
end

wire signed[15:0] walk_out;
dk_walk #(.CLOCK_RATE(CLOCK_RATE),.SAMPLE_RATE(SAMPLE_RATE)) walk (
	.clk(W_CLK_24M),
	.I_RSTn(W_RESETn),
	.audio_clk_en(audio_clk_en),
	.walk_en(~W_6H_Q[0]),
	.out(walk_out)
);

// All this is async, that is a bit tricky:
//  SOUND MIXER (WAV + DIG ) -----------------------
wire[14:0] sound_mix = ({1'b0, I_DKJR ? 15'd0 : WAV_ROM_DO, 6'b0} + {1'b0, (W_D_S_DAT >> 1) + (W_D_S_DAT >> 3), 6'b0});
wire signed[15:0] sound_mix_16_bit = sound_mix - 2**14 + walk_out;


always@(posedge W_CLK_24M) begin
	// There is small, but not negligble chance that this will not
	// synchronize with the audio out enable.
	if (audio_clk_en) begin
		O_SOUND_DAT <= sound_mix;
	end
end

endmodule
