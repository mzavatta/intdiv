`timescale 1ns / 1ps

//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10

`define ON 1'b1
`define OFF 1'b0

`define NEGATIVE 1'b1
`define POSITIVE 1'b0

module intdiv_intdiv(x, y, z/*, r*/);

  parameter N=5;

  // IN
  input [N-1:0] x;
  input [N-1:0] y;
  // OUT
  output [N-1:0] z;

  /*
  genvar i, j;
  generate for (i=-1; i<=WIDTH-2; i=i+1) begin: row
	for (j=0; j<=WIDTH-2; j=j+1) begin: col

		xor cmpy(out[j], i0[j], i1[j]);
	end
  end
  endgenerate
  */

  wire [N-2:0] d;

  wire [1:0] rc[N-1:0][N-2:0]; //N iterations, N-1 bits wide numbers
  wire [1:0] rs[N-2:0];

  wire [1:0] sprop[N-1:0][N-1:0];
  wire [1:0] ssprop[N-1:0];
  wire ps[N-2:0][N-2:0];
  wire tr[N-2:0][N-2:0];
  wire psl[N-2:0];
  wire trl[N-2:0];

  wire [1:0] xneg[N-2:0];
  wire [N-1:0] p;

  wire sign[N-1:0];

  wire padj, seladj;

  wire [1:0] fakeovfout[N-1:0];
  wire fakeovfsout;

  /* any row i has:
   * if first row: cmp, abs, neg, sgn, cmp
   * if last one: sub, abs, adj
   * if any other: sub, abs, neg, sgn, cmp
   * 
   * Items are numbered with the same indexes of the elemets that generate them
   * Indexes decrease from left to right
   * An input that comes from the same row but different coloumn, will be i,j+1
   * Outputs of cells in position i,j will get i,j as indexes
   * (neg cell is a special case)
   */

  genvar i, j;
  generate

  for (i=N-1; i>=0; i=i-1) begin: row

	intdiv_abs ovf(1'b0, 1'b0, 2'b00, fakeovfout[i], sprop[i][N-1]);  //(ps, tr, sign_in, res, sign_out)

	if (i!=0) begin
		if (i==N-1) intdiv_sgn sgn(sprop[i][0], x[i], sign[i]); //(sgn_cur, sign_prec, out);
		else intdiv_sgn sgn(sprop[i][0], sign[i+1], sign[i]);
		intdiv_neg neg(x[i-1], sign[i], xneg[i-1]); //(xbit, sign, y);
		xor cmpp(p[i], sign[i], y[N-1]);
	end
	else intdiv_adj adj(x[N-1], y[N-1], sign[i+1], sprop[i][0], ssprop[0], padj, seladj); //last row, i=0

	for (j=N-2; j>=0; j=j-1) begin: col
		if (i==N-1) begin //upper row
			xor cmpy(d[j], y[N-1], y[j]);
			if (j==0) intdiv_abs abs(d[j], y[N-1], sprop[i][j+1], rc[i][j], sprop[i][j]); //rightmost 
			else intdiv_abs abs(d[j], d[j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
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
		//xor cmpy(out[j], i0[j], i1[j]);
	end
  end

  for (j=N-1; j>=0; j=j-1) begin: star
	if (j<N-1) intdiv_sub sub(d[j], rc[0][j], psl[j], trl[j]);
	if (j==N-1) intdiv_abs abs(1'b0, trl[j-1], 2'b00, fakeovfsout, ssprop[j]);
	else if (j==0) intdiv_abs abs(psl[j], y[N-1], ssprop[j+1], rs[j], ssprop[j]);
	else intdiv_abs abs(psl[j], trl[j-1], ssprop[j+1], rs[j], ssprop[j]);
  end

  endgenerate

  
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

  parameter N = 5;
  reg [N-1:0] x_tb;
  reg [N-1:0] y_tb;
  wire [N-1:0] z_tb;

  intdiv_intdiv #(.N(N)) 
	intdiv (
	.x(x_tb),
	.y(y_tb),
	.z(z_tb)
	);

  initial
  begin
  x_tb = 5'b00111;
  y_tb = 5'b00011;
  #100;
  x_tb = 5'b00111;
  y_tb = 5'b00010;
  #100;
  x_tb = 5'b01000;
  y_tb = 5'b00010;
  #100;
  x_tb = 5'b00111;
  y_tb = 5'b00001;
  #100;
  $stop;
  end

endmodule
