`timescale 1ns / 1ps

/*
//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10
*/

`include "intdiv_sd2encoding.v"

module intdiv_abs(ps, tr, sign_in, res, sign_out);
  // IN
  input ps, tr; //standard binary
  input [1:0] sign_in; //sd2
  // OUT
  output [1:0] res;  //sd2
  output [1:0] sign_out;  //sd2

  wire ps, tr;
  wire [1:0] sign_in;
  reg [1:0] res;
  reg [1:0] sign_out;

  wire [1:0] int; //sd2 encoded, intermediate sum to be inverted if sign_in is negative

  // TABLE II.b Takagi et al. is simple concatenation if (p,n)=p-n encoding is used
  // though specifying it this way makes it encoding-dependent
  assign int = {ps, tr};

  // Absolute value and sign detection/propagation
  always @(int or sign_in)
  begin
  case ({sign_in, int})
	{`NEG1, `NEG1}:	begin
			res <= `POS1;
			sign_out <= sign_in;
			end
	{`NEG1, `ZERO_1}: begin
			res <= `ZERO_1;
			sign_out <= sign_in;
			end
	{`NEG1, `ZERO_2}: begin
			res <= `ZERO_1;
			sign_out <= sign_in;
			end
	{`NEG1, `POS1}: begin
			res <= `NEG1;
			sign_out <= sign_in;
			end
	{`ZERO_1, `NEG1}: begin
			res <= `POS1;
			sign_out <= `NEG1;
			end
	{`ZERO_2, `NEG1}: begin
			res <= `POS1;
			sign_out <= `NEG1;
			end
	{`ZERO_1, `POS1}: begin
			res <= `POS1;
			sign_out <= `POS1;
			end
	{`ZERO_2, `POS1}: begin
			res <= `POS1;
			sign_out <= `POS1;
			end
	{`POS1, `NEG1}: begin
			res <= `NEG1;
			sign_out <= sign_in;
			end
	{`POS1, `ZERO_1}: begin
			res <= `ZERO_1;
			sign_out <= sign_in;
			end
	{`POS1, `ZERO_2}: begin
			res <= `ZERO_1;
			sign_out <= sign_in;
			end
	{`POS1, `POS1}: begin
			res <= `POS1;
			sign_out <= sign_in;
			end
	default: begin
		  res <= `ZERO_1;
		  sign_out <= `ZERO_1;
		  end
  endcase
  end  

  /*
  // TABLE II.b Takagi et al.
  assign int[1] = ~ps & tr;
  assign int[0] = (~ps & tr) | (ps & ~tr);
  ..using a procedural block..
  always @(ps or tr)
  begin
	if (ps==1'b0 && tr==1'b1)
		int <= `NEG1;
	else if (ps==1'b1 && tr==1'b0)
		int <= `POS1_1;
	else
		int <= `ZERO;
  end
  */

  /*
  always @(int or sign_in)
  begin
  case ({sign_in, int})
	{`NEG1, `NEG1}:	begin
			res <= `POS1_1;
			sign_out <= sign_in;
			end//1
	{`NEG1, `ZERO}: begin
			res <= `ZERO;
			sign_out <= sign_in;
			end//2
	{`NEG1, `POS1_1}: begin
			res <= `NEG1;
			sign_out <= sign_in;
			end//3
	{`NEG1, `POS1_2}: begin
			res <= `NEG1;
			sign_out <= sign_in;
			end//4
	{`ZERO, `NEG1}: begin
			res <= `POS1_1;
			sign_out <= `NEG1;
			end//5
	{`ZERO, `ZERO}: begin
			res <= `ZERO;
			sign_out <= `ZERO;
			end//6
	{`ZERO, `POS1_1}: begin
			res <= `POS1_1;
			sign_out <= `POS1_1;
			end//7
	{`ZERO, `POS1_2}: begin
			res <= `POS1_1;
			sign_out <= `POS1_1;
			end//8
	{`POS1_1, `NEG1}: begin
			res <= `NEG1;
			sign_out <= sign_in;
			end//9
	{`POS1_2, `NEG1}: begin
			res <= `NEG1;
			sign_out <= sign_in;
			end//10
	{`POS1_1, `ZERO}: begin
			res <= `ZERO;
			sign_out <= sign_in;
			end//11
	{`POS1_2, `ZERO}: begin
			res <= `ZERO;
			sign_out <= sign_in;
			end//12
	{`POS1_1, `POS1_1}: begin
			res <= `POS1_1;
			sign_out <= sign_in;
			end//13
	{`POS1_1, `POS1_2}: begin
			res <= `POS1_1;
			sign_out <= sign_in;
			end//14
	{`POS1_2, `POS1_1}: begin
			res <= `POS1_1;
			sign_out <= sign_in;
			end//15
	{`POS1_2, `POS1_2}: begin
			res <= `POS1_1;
			sign_out <= sign_in;
			end//16
	default: begin
		  res <= `ZERO;
		  sign_out <= sign_in;
		  end
  endcase
  end
  */
endmodule

//test bench
module intdiv_abs_tb();
  reg ps_tb, tr_tb;
  reg [1:0] sign_in_tb;
  wire [1:0] res_tb;
  wire [1:0] sign_out_tb;

  intdiv_abs idabs(
	.ps(ps_tb),
	.tr(tr_tb),
	.sign_in(sign_in_tb),
	.res(res_tb),
	.sign_out(sign_out_tb)
	);

  integer i, j;

  initial
  begin
	{ps_tb, tr_tb} = 2'b00;
	sign_in_tb = `ZERO_1;
        for(i = 0; i < 4; i = i+1)
        begin
		for(j = 0; j < 4; j = j+1)
		begin
			#100;
			{ps_tb, tr_tb} = {ps_tb, tr_tb}+1'b1;
		end
		sign_in_tb = sign_in_tb+1'b1;
	end
	$stop;
  end
endmodule
