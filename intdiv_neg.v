`timescale 1ns / 1ps

/*
//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10
*/

`include "intdiv_sd2encoding.v"

module intdiv_neg(xbit, sign, y);
  // IN
  input xbit;
  input sign;
  // OUT
  output [1:0] y; //sd2

  reg [1:0] y;
  always @(xbit or sign)
  begin
     case ({xbit, sign})
	{1'b1, 1'b0}: begin y <= `POS1; end
	{1'b1, 1'b1}: begin y <= `NEG1; end
	default: begin y <= `ZERO_1; end
     endcase
  end

endmodule

/*
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
*/
