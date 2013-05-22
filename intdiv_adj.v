`timescale 1ns / 1ps

//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10

`define ON 1'b1
`define OFF 1'b0

`define NEGATIVE 1'b1
`define POSITIVE 1'b0

module intdiv_adj(xmsb, ymsb, sign_r1, sgn_rc0, sgn_rs0, padj, seladj);
  // IN
  input [1:0] sgn_rc0; //sd2
  input [1:0] sgn_rs0; //sd2
  input xmsb, ymsb, sign_r1;
  // OUT
  output padj;
  output seladj;

  wire [1:0] sgn_rc0;
  wire [1:0] sgn_rs0;
  wire xmsb, ymsb, sign_r1;

  wire sign_r0;
  intdiv_sgn sign_block(
		.sgn_cur({sgn_rc0[1], sgn_rc0[0]}),
		.sign_prec(sign_r1),
		.out(sign_r0)
		);

  reg padj, seladj;
  always @(xmsb or ymsb or sgn_rc0 or sgn_rs0 or sign_r0)
  begin
    if (xmsb == `POSITIVE) begin //divisor positive
	if (sign_r0 == `NEGATIVE) begin //final reminder negative
		seladj <= 1'b0;
		if (ymsb == `POSITIVE) padj <= `OFF;
		else padj <= `ON;
	end
	else begin //final reminder positive
		seladj <= 1'b1;
		padj <= `OFF;
	end
    end
    else begin  //divisor negative
	if (sgn_rs0 == `ZERO) begin
		seladj <= 1'b0;
		if (ymsb == `POSITIVE) padj <= `OFF;
		else padj <= `ON;
	end
	else if (sgn_rc0 != `ZERO && sign_r0 == `POSITIVE) begin
		seladj <= 1'b0;
		if (ymsb == `POSITIVE) padj <= `ON;
		else padj <= `OFF;
	end
	else
		seladj <= 1'b1;
		padj <= `OFF;
	end
    end
  end

endmodule


//test bench
module intdiv_adj_tb();
  reg xmsb_tb, ymsb_tb;
  reg sign_r1_tb;
  reg [1:0] sgn_rc0_tb;
  reg [1:0] sgn_rs0_tb;
  wire padj_tb;
  wire seladj_tb;

  intdiv_adj idadj(
	.xmsb(xmsb_tb),
	.ymsb(ymsb_tb),
	.sign_r1(sign_r1_tb),
	.sgn_rc0(sgn_rc0_tb),
	.sgn_rs0(sgn_rs0_tb),
	.padj(padj_tb),
	.seladj(seladj_tb)
	);

  integer i, j;

  initial
  begin
	xmsb_tb = `POSITIVE;
	sign_r1_tb = `POSITIVE;
	for(i=0; i<32; i=i+1)
	begin
	  #10;

	end
  $stop;
  end

  initial
  begin
	{ps_tb, tr_tb} = 2'b00;
	sign_in_tb = `ZERO;
        for(i = 0; i < 4; i = i+1)
        begin
		for(j = 0; j < 4; j = j+1)
		begin
			#100;
			{ps_tb, tr_tb} = {ps_tb, tr_tb}+1'b1;
		end
		sign_in_tb = sign_in_tb+1'b1;
	end

  end
endmodule
