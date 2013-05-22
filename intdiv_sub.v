`timescale 1ns / 1ps

//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10

module intdiv_sub(sub, min, sum, tr);
  // IN
  input [1:0] sub; //sd2
  input min;
  // OUT
  output sum;
  output tr;

  wire [1:0] sub;
  wire min;

  // TABLE II.a Takagi et al.
  assign tr = (sub[1] & sub[0]) | (~sub[1] & ~sub[0] & min);
  assign sum = (sub[1] & sub[0] & ~min) | (~sub[1] & ~sub[0] & min) | (~sub[1] & sub[0] & ~min) | (sub[1] & ~sub[0] & ~min);
endmodule

//test bench
module intdiv_sub_tb();
  reg sub1_tb, sub0_tb, min_tb;
  wire sum_tb, tr_tb;

  intdiv_sub ids(
	.sub({sub1_tb, sub0_tb}),
	.min(min_tb),
	.sum(sum_tb),
	.tr(tr_tb)
	);

  initial
  begin
	{sub1_tb, sub0_tb} = `ZERO;
	min_tb = 1'b0;
	#100;
	{sub1_tb, sub0_tb} = `POS1_1;
	#100;
	{sub1_tb, sub0_tb} = `NEG1;
	#100;
	{sub1_tb, sub0_tb} = `POS1_2;
	#100;
	min_tb = 1'b1;
	#100;
	{sub1_tb, sub0_tb} = `ZERO;
	#100;
	{sub1_tb, sub0_tb} = `POS1_1;
	#100;
	{sub1_tb, sub0_tb} = `NEG1;
	#100;
	{sub1_tb, sub0_tb} = `POS1_2;
	#100;
	$stop;
  end
endmodule
