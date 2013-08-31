`timescale 1ns / 1ps

/*
//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10
*/

`include "intdiv_sd2encoding.v"

module intdiv_ovf(minm, minl, tr, res, sign_out, wrong);
  // IN
  input tr; //standard binary
  input [1:0] minm; //sd2  most significant operand (leftmost)
  input [1:0] minl; //sd2  least significant operand (rightmost)
  // OUT
  output [1:0] res;  //sd2
  output [1:0] sign_out;  //sd2
  output wrong;

  reg [1:0] res;
  reg [1:0] sign_out;
  reg wrong;
  wire [1:0] minm;
  wire [1:0] minl;
  wire tr;

  wire psm, trm, psl, trl;
  wire [1:0] flag; //sd2
  wire [1:0] int; //sd2

  intdiv_sub subm(
	.sub(1'b0),
	.min(minm),
	.sum(psm),
	.tr(trm)
	);

  intdiv_sub subl(
	.sub(1'b0),
	.min(minl),
	.sum(psl),
	.tr(trl)
	);

  /*
  // TABLE II.b Takagi et al.
  assign flag[1] = ~psm & trl;
  assign flag[0] = (~psm & trl) | (psm & ~trl);
  assign int[1] = ~psl & tr;
  assign int[0] = (~psl & tr) | (psl & ~tr);
  */

  // TABLE II.b Takagi et al. with (p,n) encoding
  assign flag = {psm, trl};
  assign int = {psl, tr};


  always @(int or flag)
  begin
  case ({flag, int})
	{`NEG1, `POS1}: begin
			res <= `POS1;
			sign_out <= `NEG1;
		  	wrong <= 1'b0;
			end//1
	{`ZERO_1, `NEG1}: begin
			res <= `POS1;
			sign_out <= `NEG1;
		  	wrong <= 1'b0;
			end//3
	{`ZERO_2, `NEG1}: begin
			res <= `POS1;
			sign_out <= `NEG1;
		  	wrong <= 1'b0;
			end//3
	{`ZERO_1, `ZERO_1}: begin
			res <= `ZERO_1;
			sign_out <= `ZERO_1;
		  	wrong <= 1'b0;
			end//4
	{`ZERO_1, `ZERO_2}: begin
			res <= `ZERO_1;
			sign_out <= `ZERO_1;
		  	wrong <= 1'b0;
			end//4
	{`ZERO_2, `ZERO_1}: begin
			res <= `ZERO_1;
			sign_out <= `ZERO_1;
		  	wrong <= 1'b0;
			end//4
	{`ZERO_2, `ZERO_2}: begin
			res <= `ZERO_1;
			sign_out <= `ZERO_1;
		  	wrong <= 1'b0;
			end//4
	{`ZERO_1, `POS1}: begin
			res <= `POS1;
			sign_out <= `POS1;
		  	wrong <= 1'b0;
			end//5
	{`ZERO_2, `POS1}: begin
			res <= `POS1;
			sign_out <= `POS1;
		  	wrong <= 1'b0;
			end//5
	{`POS1, `NEG1}: begin
			res <= `POS1;
			sign_out <= `POS1;
		  	wrong <= 1'b0;
			end//7
	default: begin
		  res <= `ZERO_1;
		  sign_out <= `ZERO_1;
		  wrong <= 1'bx;
		  end
  endcase
  end


  /*
  always @(int or flag)
  begin
  case ({flag, int})
	{`NEG1, `POS1_1}: begin
			res <= `POS1_1;
			sign_out <= `NEG1;
		  	wrong <= 1'b0;
			end//1
	{`NEG1, `POS1_2}: begin
			res <= `POS1_1;
			sign_out <= `NEG1;
		  	wrong <= 1'b0;
			end//2
	{`ZERO, `NEG1}: begin
			res <= `POS1_1;
			sign_out <= `NEG1;
		  	wrong <= 1'b0;
			end//3
	{`ZERO, `ZERO}: begin
			res <= `ZERO;
			sign_out <= `ZERO;
		  	wrong <= 1'b0;
			end//4
	{`ZERO, `POS1_1}: begin
			res <= `POS1_1;
			sign_out <= `POS1_1;
		  	wrong <= 1'b0;
			end//5
	{`ZERO, `POS1_2}: begin
			res <= `POS1_1;
			sign_out <= `POS1_1;
		  	wrong <= 1'b0;
			end//6
	{`POS1_1, `NEG1}: begin
			res <= `POS1_1;
			sign_out <= `POS1_1;
		  	wrong <= 1'b0;
			end//7
	{`POS1_2, `NEG1}: begin
			res <= `POS1_1;
			sign_out <= `POS1_1;
		  	wrong <= 1'b0;
			end//8
	default: begin
		  res <= `ZERO;
		  sign_out <= `ZERO;
		  wrong <= 1'b1;
		  end
  endcase
  end
  */

endmodule

//test bench
module intdiv_ovf_tb();
  reg tr_tb;
  reg [1:0] minm_tb;
  reg [1:0] minl_tb;
  wire [1:0] res_tb;
  wire [1:0] sign_out_tb;
  wire wrong_tb;

  //module intdiv_ovf(minm, minl, tr, res, sign_out, wrong);
  intdiv_ovf idovf(
	.minm(minm_tb),
	.minl(minl_tb),
	.tr(tr_tb),
	.res(res_tb),
	.sign_out(sign_out_tb),
	.wrong(wrong_tb)
	);

  integer i, j;

  initial
  begin
	tr_tb = 1'b0;
	minm_tb = `ZERO_1;
	minl_tb = `ZERO_1;
	#100;
	tr_tb = 1'b1;
	minm_tb = `POS1;
	#100;
	tr_tb = 1'b0;
	#100;
	/*
        for(i = 0; i < 4; i = i+1)
        begin
		for(j = 0; j < 4; j = j+1)
		begin
			#100;
			{ps_tb, tr_tb} = {ps_tb, tr_tb}+1'b1;
		end
		sign_in_tb = sign_in_tb+1'b1;
	end
	*/
	$stop;
  end
endmodule
