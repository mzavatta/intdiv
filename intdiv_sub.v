`timescale 1ns / 1ps

//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10

module intdiv_sub(sub, min, sum, tr);
  // IN
  input [1:0] min; //sd2
  input sub;
  // OUT
  output sum;
  output tr;

  wire [1:0] min;
  wire sub;

  // TABLE II.a Takagi et al.
  assign tr = (min[1] & min[0]) | (~min[1] & ~min[0] & sub);
  assign sum = (min[1] & min[0] & ~sub) | (~min[1] & ~min[0] & sub) | (~min[1] & min[0] & ~sub) | (min[1] & ~min[0] & ~sub);
endmodule

//test bench
//FIXME: rework tb minuend and subtrahend
module intdiv_sub_tb();
  reg min1_tb, min0_tb, sub_tb;
  wire sum_tb, tr_tb;

  intdiv_sub ids(
	.sub({min1_tb, min0_tb}),
	.min(sub_tb),
	.sum(sum_tb),
	.tr(tr_tb)
	);

  initial
  begin
	{min1_tb, min0_tb} = `ZERO;
	sub_tb = 1'b0;
	#100;
	{min1_tb, min0_tb} = `POS1_1;
	#100;
	{min1_tb, min0_tb} = `NEG1;
	#100;
	{min1_tb, min0_tb} = `POS1_2;
	#100;
	sub_tb = 1'b1;
	#100;
	{min1_tb, min0_tb} = `ZERO;
	#100;
	{min1_tb, min0_tb} = `POS1_1;
	#100;
	{min1_tb, min0_tb} = `NEG1;
	#100;
	{min1_tb, min0_tb} = `POS1_2;
	#100;
	$stop;
  end
endmodule
