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

module intdiv_intdiv(x, y, z, r);

  parameter WIDTH=4;

  // IN
  input [WIDTH-1:0] x;
  input [WIDTH-1:0] y;
  // OUT
  output [WIDTH-1:0] z;
  output [WIDTH-1:0] z;


  genvar i, j;
  generate for (i=-1; i<=WIDTH-2; i=i+1) begin: row
	for (j=0; j<=WIDTH-2; j=j+1) begin: col

		xor cmpy(out[j], i0[j], i1[j]);
	end
  end
  endgenerate



(ps, tr, sign_in, res, sign_out);
  genvar i, j;
  generate for (i=WIDTH-1; i>=0; i=i-1) begin: row
	intdiv_abs ovf();
	intdiv_sgn sgn();
	intdiv_neg neg();
	xor cmpp();
	for (j=WIDTH-2; j>=0; j=j-1) begin: col
		if (i==WIDTH-1) begin
			if (j==0) intdiv_abs abs(d[j], y[N-1], sprop[i][j+1], rc[i][j], sprop[i][j]); //rightmost 
			else intdiv_abs abs(d[j], d[j-1], sprop[i][j+1], rc[i][j], sprop[i][j+1]);
		end
		else begin
			if (j==0) begin //rightmost
			intdiv_sub sub(d[j], );  //(sub, min, sum, tr)
			intdiv_abs abs(ps[i][j], y[N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
			intdiv_sub sub(d[j], );
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
		//xor cmpy(out[j], i0[j], i1[j]);
	end
  end
  endgenerate


  wire d0, d1, d2;
  xor cmp13(d2, y[2], y[3]);
  xor cmp12(d1, y[1], y[3]);
  xor cmp11(d0, y[0], y[3]);

	(ps, tr, sign_in, res, sign_out);
  wire [1:0] sprop13, [1:0] sprop12, [1:0] sprop11, [1:0] sprop10;
  wire [1:0] rc12, [1:0] rc11, [1:0] rc10;
  intdiv_abs ovf1(d2, .., .., .., sprop13);
  intdiv_abs abs13(d1, d2, sprop13, rc12, sprop12);
  intdiv_abs abs12(d0, d1, sprop12, rc11, sprop11);
  intdiv_abs abs11(y[3], d0, sprop11, rc10, sprop10);

  wire ps10, ps11, ps12, ps13;
  wire tr10, tr11, tr12, tr13;
  wire 
  intdiv_sub sub11(d0, ..); intdiv_sub(sub, min, sum, tr);
  intdiv_sub sub11(d1, rc10,  ..);

endmodule
