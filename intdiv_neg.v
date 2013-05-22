`timescale 1ns / 1ps

//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10

module intdiv_neg(xbit, sign, y);
  // IN
  input xbit;
  input sign;
  // OUT
  output [1:0] y; //sd2

  wire xbit;
  wire sign;

  assign y[1] = (xbit & sign);
  assign y[0] = xbit;
endmodule
