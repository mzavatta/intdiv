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

module intdiv_intdiv(x, y, z/*,r*/);

  parameter N=5;

  // IN
  input [N-1:0] x;
  input [N-1:0] y;
  // OUT
  output [N-1:0] z;

  wire [N-2:0] d;

  wire [1:0] rc[N-1:0][N-1:0]; //N iterations, N-1 bits wide numbers
  wire [1:0] rs[N-1:0];
  wire [1:0] r[N-1:0];
  wire [1:0] radj[N-1:0];

  wire [1:0] sprop[N-1:0][N-1:0];
  wire [1:0] ssprop[N-1:0];
  wire ps[N-1:0][N-2:0];
  wire tr[N-1:0][N-2:0];
  wire psl[N-2:0];
  wire trl[N-2:0];

  wire [1:0] xneg[N-2:0];
  wire [N-1:0] p;

  wire sign[N-1:0];

  wire padj, seladj;

  wire [1:0] fakeovfout[N-1:0];
  wire wrong[N-1:0];
  wire [1:0] lastovf;
  wire lastovfs;

  /* any row i includes:
   * if first row: cmp, abs, neg, sgn, cmp
   * if last one: sub, abs, adj
   * if any other: sub, abs, neg, sgn, cmp
   * 
   * Signals are numbered with the same indexes of the elemets that generate them
   * Indexes decrease from left to right
   * An input that comes to the cell from the same row but previous coloumn will be (i,j+1)
   * Outputs of cells in position (i,j) will get (i,j) as indexes
   * (neg cells are a special case)
   */

  genvar i, j;
  generate

  for (i=N-1; i>=0; i=i-1) begin: row

	//intdiv_abs ovf(1'b0, 1'b0, 2'b00, fakeovfout[i], sprop[i][N-1]); //tr[N-2], fakeovfout[i+1], rc[i+1][j-1]
	//module intdiv_ovf(minm, minl, tr, res, sign_out, wrong);
	if (i==N-1) intdiv_ovf ovf(2'b00, 2'b00, d[N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);
	else intdiv_ovf ovf(rc[i+1][N-1], rc[i+1][N-2], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);

	if (i!=0) begin
		if (i==N-1) intdiv_sgn sgn(sprop[i][0], x[i], sign[i]);
		else intdiv_sgn sgn(sprop[i][0], sign[i+1], sign[i]);
		intdiv_neg neg(x[i-1], sign[i], xneg[i-1]);
		xnor cmpp(p[i], sign[i], y[N-1]); //positive numbers version working with xnor
	end
	else intdiv_adj adj(x[N-1], y[N-1], sign[i+1], sprop[i][0], ssprop[0], padj, seladj); //last row, i=0

	for (j=N-2; j>=0; j=j-1) begin: col
		if (i==N-1) begin //upper row
			xor cmpy(d[j], y[N-1], y[j]);
			if (j==0) begin
				intdiv_sub sub(d[j], {1'b0, x[N-1]}, ps[i][j], tr[i][j]);
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

  assign lastovf = rc[0][N-1];
  for (j=N-1; j>=0; j=j-1) begin: star
	if (j<N-1) intdiv_sub sub(d[j], rc[0][j], psl[j], trl[j]);
	if (j==N-1) intdiv_abs abs(lastovf[0], trl[j-1], 2'b00, rs[j], ssprop[j]);
	else if (j==0) intdiv_abs abs(psl[j], y[N-1], ssprop[j+1], rs[j], ssprop[j]);
	else intdiv_abs abs(psl[j], trl[j-1], ssprop[j+1], rs[j], ssprop[j]);
  end

  for (j=N-1; j>=0; j=j-1) begin: mux
	assign r[j] = seladj ? rc[0][j] : rs[j];
	//module intdiv_sdcmp(op, res, enable);
	intdiv_sdcmp negconv(r[j], radj[j], x[N-1]);	
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
  x_tb = 5'b00111;
  y_tb = 5'b00001;
  #100;
  x_tb = 5'b01110;
  y_tb = 5'b00101;
  #100;
  x_tb = 5'b01110;
  y_tb = 5'b01001;
  #100;
  x_tb = 5'b01010;
  y_tb = 5'b00111;
  #100;
  x_tb = 5'b01100;
  y_tb = 5'b00011;
  #100;
  x_tb = 5'b00011;
  y_tb = 5'b01110;
  #100;
  x_tb = 5'b00100;
  y_tb = 5'b01010;
  #100;
  x_tb = 5'b00110;
  y_tb = 5'b01111;
  #100;
  x_tb = 5'b01111;
  y_tb = 5'b01111;
  #100;
  x_tb = 5'b00000;
  y_tb = 5'b01111;
  #100;
  x_tb = 5'b01111;
  y_tb = 5'b00000;
  #100;
  x_tb = 5'b11011;
  y_tb = 5'b00011;
  #100;
  x_tb = 5'b11001;
  y_tb = 5'b00011;
  #100;
  x_tb = 5'b10001;
  y_tb = 5'b01111;
  #100;
  x_tb = 5'b11001;
  y_tb = 5'b11100;
  #100;
  x_tb = 5'b11111;
  y_tb = 5'b00001;
  #100;
  x_tb = 5'b00001;
  y_tb = 5'b11111;
  #100;
  x_tb = 5'b00001;
  y_tb = 5'b10001;
  #100;
  x_tb = 5'b00101;
  y_tb = 5'b10001;
  #100;
  x_tb = 5'b10101;
  y_tb = 5'b10001;
  #100;
  $stop;
  end

endmodule
