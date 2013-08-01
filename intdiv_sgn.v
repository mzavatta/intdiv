`timescale 1ns / 1ps

/*
//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10
*/

`include "intdiv_sd2encoding.v"

`define NEGATIVE 1'b1
`define POSITIVE 1'b0

module intdiv_sgn(sgn_cur, sign_prec, out);
  // IN
  input [1:0] sgn_cur; //sd2
  input sign_prec;
  // OUT
  output out;

  wire [1:0] sgn_cur;
  wire sign_prec;

  // (p,n) encoding
  assign out = (sign_prec & sgn_cur[1] & ~sgn_cur[0]) |  //- + = -
		(~sign_prec & ~sgn_cur[1] & sgn_cur[0]);  //+ - = -
		// | (~sgn_cur[1] & ~sgn_cur[0]);


  /* original encoding
  assign out = (sign_prec & ~sgn_cur[1] & sgn_cur[0]) |
		(sign_prec & sgn_cur[1] & ~sgn_cur[0]) |
		(~sign_prec & sgn_cur[1] & sgn_cur[0]);
		// | (~sgn_cur[1] & ~sgn_cur[0]);
  */

endmodule

module intdiv_sgn_tb();
  reg sign_prec_tb;
  reg [1:0] sgn_cur_tb;
  wire out_tb;

  intdiv_sgn idsgn(
	.sgn_cur(sgn_cur_tb),
	.sign_prec(sign_prec_tb),
	.out(out_tb)
	);

  integer i;

  initial
  begin
	sign_prec_tb = `POSITIVE;
	sgn_cur_tb = `ZERO_1;
	#100;
	for(i=0; i<8; i=i+1)
	begin
	  #10;
	  {sgn_cur_tb, sign_prec_tb} = {sgn_cur_tb, sign_prec_tb}+1'b1;
	end
  end	

endmodule
