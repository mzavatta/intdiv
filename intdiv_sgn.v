`timescale 1ns / 1ps

//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10

module intdiv_sgn(sgn_cur, sign_prec, out);
  // IN
  input [1:0] sgn_cur; //sd2
  input sign_prec;
  // OUT
  output out;

  wire [1:0] sgn_cur;
  wire sign_prec;

  
  assign out = (sign_prec & ~sgn_cur[1] & sgn_cur[0]) |
		(sign_prec & sgn_cur[1] & ~sgn_cur[0]) |
		(~sign_prec & sgn_cur[1] & sgn_cur[0]) |
		(~sgn_cur[1] & ~sgn_cur[0]);
endmodule
