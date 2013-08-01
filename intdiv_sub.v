`timescale 1ns / 1ps

`include "intdiv_sd2encoding.v"

/*
//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10
*/

module intdiv_sub(sub, min, sum, tr);
  // IN
  input [1:0] min; //sd2
  input sub;
  // OUT
  output sum;
  output tr;

  wire [1:0] min;
  wire sub;

  // assuming (p,n)=p-n encoding
  assign {tr, sum} = min[1] - min[0] - sub;

  // assuming (p,n)=p-n encoding
  /*
  reg sum, tr;
  always @(min or sub)
  begin
  case ({min, sub})
	{`NEG1, 1'b0}:	 begin {tr, sum} <= 2'b11; end
	{`NEG1, 1'b1}:	 begin {tr, sum} <= 2'b10; end
	{`ZERO_1, 1'b1}: begin {tr, sum} <= 2'b11; end
	{`ZERO_2, 1'b1}: begin {tr, sum} <= 2'b11; end
	{`POS1, 1'b0}:	 begin {tr, sum} <= 2'b01; end
        default: 	 begin {tr, sum} <= 2'b00; end
  endcase
  end
  */

  /* assuming original encoding
  // TABLE II.a Takagi et al.
  assign tr = (min[1] & min[0]) | (~min[1] & ~min[0] & sub);
  assign sum = (min[1] & min[0] & ~sub) | (~min[1] & ~min[0] & sub) | (~min[1] & min[0] & ~sub) | (min[1] & ~min[0] & ~sub);
  */

endmodule

//test bench
module intdiv_sub_tb();
  reg min1_tb, min0_tb, sub_tb;
  wire sum_tb, tr_tb;

  intdiv_sub ids(
	.sub(sub_tb),
	.min({min1_tb, min0_tb}),
	.sum(sum_tb),
	.tr(tr_tb)
	);

  initial
  begin
	{min1_tb, min0_tb} = `ZERO_1;
	sub_tb = 1'b0;
	#100;
	{min1_tb, min0_tb} = `POS1;
	#100;
	{min1_tb, min0_tb} = `NEG1;
	#100;
	{min1_tb, min0_tb} = `POS1;
	#100;
	sub_tb = 1'b1;
	#100;
	{min1_tb, min0_tb} = `ZERO_1;
	#100;
	{min1_tb, min0_tb} = `POS1;
	#100;
	{min1_tb, min0_tb} = `NEG1;
	#100;
	{min1_tb, min0_tb} = `POS1;
	#100;
	$stop;
  end
endmodule
