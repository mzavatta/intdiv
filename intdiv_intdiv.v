`timescale 1ns / 1ps

/*
//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10
*/

`include "intdiv_sd2encoding.v"

`define ON 1'b1
`define OFF 1'b0

`define NEGATIVE 1'b1
`define POSITIVE 1'b0

module intdiv_intdiv(x, y, z, r);

  parameter N=32;

  // IN
  input [N-1:0] x;  //DIVIDEND
  input [N-1:0] y;  //DIVISOR
  // OUT
  output [N-1:0] z;  //FINAL QUOTIENT
  output [N-1:0] r;  //FINAL REMINDER

  wire [N-2:0] d;

  wire [1:0] rc[N-1:0][N-1:0]; //N iterations, N-1 bits wide numbers
  wire [1:0] rs[N-1:0];
  wire [1:0] rsd2[N-1:0];
  wire [1:0] rsd2re[N-1:0];
  wire [((N-1)*2)+1:0] rflat;

  wire [1:0] sprop[N-1:0][N-1:0];
  wire [1:0] ssprop[N-1:0];
  wire ps[N-1:0][N-2:0];
  wire tr[N-1:0][N-2:0];
  wire psl[N-1:0];
  wire trl[N-1:0];

  wire [1:0] xneg[N-2:0];
  wire [N-1:0] p;

  wire sign[N-1:0];

  wire padj, seladj;

  wire wrong[N-1:0];
  wire [1:0] lastovf;

  /* 
   * Signals are numbered with the same indexes of the elemets that generate them
   * Indexes decrease from left to right
   * An input that comes to the cell from the same row but previous coloumn will be (i,j+1)
   * Outputs of cells in position (i,j) will get (i,j) as indexes
   * (neg cells are a special case)
   */

  genvar i, j;
  generate

  for (i=N-1; i>=0; i=i-1) begin: row

	if (i==N-1) intdiv_ovf ovf(2'b00, 2'b00, d[N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);
	else intdiv_ovf ovf(rc[i+1][N-1], rc[i+1][N-2], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);

	if (i!=0) begin
		if (i==N-1) intdiv_sgn sgn(sprop[i][0], x[i], sign[i]);
		else intdiv_sgn sgn(sprop[i][0], sign[i+1], sign[i]);
		intdiv_neg neg(x[i-1], sign[i], xneg[i-1]);
		xnor cmpp(p[i], sign[i], y[N-1]);
	end
	else intdiv_adj adj(x[N-1], y[N-1], sign[i+1], sprop[i][0], ssprop[0], padj, seladj); //last row, i=0

	for (j=N-2; j>=0; j=j-1) begin: col
		if (i==N-1) begin //upper row
			xor cmpy(d[j], y[N-1], y[j]);
			if (j==0) begin
				intdiv_sub sub(d[j], {x[N-1], 1'b0}, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], y[N-1], sprop[i][j+1], rc[i][j], sprop[i][j]); //rightmost
			end
			else begin
				intdiv_sub sub(d[j], 2'b00, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
		else begin
			if (j==0) begin //rightmost
			intdiv_sub sub(d[j], xneg[i], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], y[N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
			intdiv_sub sub(d[j], rc[i+1][j-1], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
	end
  end

  for (j=N-1; j>=0; j=j-1) begin: star
	if (j<N-1) intdiv_sub sub(d[j], rc[0][j], psl[j], trl[j]);
	else intdiv_sub sub(1'b0, rc[0][j], psl[j], trl[j]);
	if (j==N-1) intdiv_abs abs(psl[j], trl[j-1], 2'b00, rs[j], ssprop[j]);
	else if (j==0) intdiv_abs abs(psl[j], y[N-1], ssprop[j+1], rs[j], ssprop[j]);
	else intdiv_abs abs(psl[j], trl[j-1], ssprop[j+1], rs[j], ssprop[j]);
  end

  for (j=N-1; j>=0; j=j-1) begin: select
	assign rsd2[j] = seladj ? rc[0][j] : rs[j];
  end

  for (j=N-1; j>=0; j=j-1) begin: flatten
	assign rflat[j*2] = rsd2[j][0];
	assign rflat[j*2+1] = rsd2[j][1];
  end


  endgenerate

  intdiv_negconv #(.WIDTH(N)) negconv(rflat, r, x[N-1]);	

  intdiv_padj #(.WIDTH(N-1)) 
	padjuster (
	.op(p[N-1:1]),
	.res(z[N-1:1]),
	.enable(padj)
	);
  assign z[0] = seladj;

endmodule

//test bench
module intdiv_intdiv_tb();

  parameter N = 32;

  reg signed [N-1:0] x_tb;
  reg signed [N-1:0] y_tb;
  wire signed [N-1:0] z_tb;
  wire signed [N-1:0] r_tb;

  reg signed [N-1:0] z_exp;
  reg signed [N-1:0] r_exp;
  reg alarm;

  intdiv_intdiv #(.N(N)) 
	intdiv (
	.x(x_tb),
	.y(y_tb),
	.z(z_tb),
	.r(r_tb)
	);

  integer i, j;

  initial
  begin
  /*
  //automated exhaustive self-checking
  alarm = 1'b0;
  x_tb = 5'd0;
  y_tb = 5'd0;
  for (i=0; i<(2**N); i=i+1) begin
	alarm = 1'b0;
	x_tb = i;
	for (j=1; j<(2**N); j=j+1) begin //excludes division by zero
		y_tb = j;
		#10;
		z_exp = x_tb/y_tb;
		r_exp = x_tb%y_tb;
	  	if (z_tb != z_exp || r_tb != r_exp) begin
			$display ("Error: expected values z=%d r=%d, got values %d %d", z_exp, r_exp, z_tb, r_tb);
			alarm = 1'b1;
		end
	  	#100;
	end
  end
  */
  x_tb = 5'd30;
  y_tb = 5'd7;
  #100;
  x_tb = -5'd120;
  y_tb = 5'd11;
  #100;
  $stop;
  end

endmodule
