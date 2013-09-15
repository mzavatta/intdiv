`timescale 1ns / 1ps

/*
//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10
*/

`include "intdiv_sd2encoding.v"
/*
`include "intdiv_neg.v"
`include "intdiv_negconv.v"
`include "intdiv_abs.v"
`include "intdiv_ovf.v"
`include "intdiv_padj.v"
`include "intdiv_adj.v"
`include "intdiv_sgn.v"
`include "intdiv_sub.v"
*/


`define ON 1'b1
`define OFF 1'b0

`define NEGATIVE 1'b1
`define POSITIVE 1'b0

`define BOUND ((i+1)%STEPS)
`define STG ((i/STEPS)+1)

module intdiv_intdiv(clock, reset, x, y, z, r);

  parameter N=16;
  parameter STAGES=4;
  parameter STEPS=N/STAGES;

  // IN
  input [N-1:0] x;  //DIVIDEND
  input [N-1:0] y;  //DIVISOR
  input clock;
  input reset;
  // OUT
  output [N-1:0] z;  //FINAL QUOTIENT
  output [N-1:0] r;  //FINAL REMINDER

  wire [N-1:0] z;
  wire [N-1:0] r;

  //N iterations, N-1 bits wide numbers
  wire [1:0] rc[N-1:0][N-1:0];
  wire [1:0] rs[N-1:0];
  wire [1:0] rsd2[N-1:0];
  wire [1:0] rsd2re[N-1:0];
  wire [((N-1)*2)+1:0] rflat;

  reg [((N-1)*2)+1:0] reg_rflat;

  //rc contents to be copied in reg_rc at stage output
  //reg_rc to be used as stage input
  reg [1:0] reg_rc[STAGES-1:0][N:0];

  //have to hold dividend and divisors for the S operands simultaneously
  reg [N-1:0] reg_x[STAGES-1:0];
  reg [N-1:0] reg_y[STAGES-1:0];
  wire [N-2:0] d;
  reg [N-2:0] reg_d[STAGES-1:0];

  //to hold sign outputs
  reg [STAGES-1:0] reg_sign;

  //to hold adj cell output
  reg reg_padj;
  reg reg_seladj;

  wire [1:0] sprop[N-1:0][N-1:0];
  wire [1:0] ssprop[N-1:0];
  wire ps[N-1:0][N-2:0];
  wire tr[N-1:0][N-2:0];
  wire psl[N-1:0];
  wire trl[N-1:0];

  wire [1:0] xneg[N-2:0];
  wire [N-1:0] p; 

  reg [N-1:0] reg_p[STAGES-1:0];
  //as many as the pipeline stages in order to hold the partially computed quotient
  //p[0] needs to be fed to the adjuster at every clock cycle

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

	if (i==N-1) intdiv_ovf ovf(2'b00, 2'b00, d[N-2], rc[i][N-1], sprop[i][N-1], wrong[i]); //first row
	else if (`BOUND==0) intdiv_ovf ovf(reg_rc[`STG][N], reg_rc[`STG][N-1], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]); //bound row
	else intdiv_ovf ovf(rc[i+1][N-1], rc[i+1][N-2], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);

	if (i!=0) begin
		if (i==N-1) begin //first row
		   intdiv_sgn sgn(sprop[i][0], x[i], sign[i]);
		   intdiv_neg neg(x[i-1], sign[i], xneg[i-1]);
		   xnor cmpp(p[i], sign[i], y[N-1]);
		end
		else if (i>=N-STEPS) begin //first stage rows
		   intdiv_sgn sgn(sprop[i][0], sign[i+1], sign[i]);
		   intdiv_neg neg(x[i-1], sign[i], xneg[i-1]);
		   xnor cmpp(p[i], sign[i], y[N-1]);
		end
		else if (`BOUND==0) begin
		   intdiv_sgn sgn(sprop[i][0], reg_sign[`STG], sign[i]);
		   intdiv_neg neg(reg_x[`STG][i-1], sign[i], xneg[i-1]);
		   xnor cmpp(p[i], sign[i], reg_y[`STG][N-1]);
		end
		else begin
		   intdiv_sgn sgn(sprop[i][0], sign[i+1], sign[i]);
		   intdiv_neg neg(reg_x[`STG][i-1], sign[i], xneg[i-1]);
		   xnor cmpp(p[i], sign[i], reg_y[`STG][N-1]);
		end
	end
	else begin
		//I think this branch is never taken!
		if (`BOUND==0) intdiv_adj adj(reg_x[`STG][N-1], reg_y[`STG][N-1], reg_sign[`STG], sprop[i][0], ssprop[0], padj, seladj);
		else intdiv_adj adj(reg_x[`STG][N-1], reg_y[`STG][N-1], sign[i+1], sprop[i][0], ssprop[0], padj, seladj); //last row, i=0
	end

	for (j=N-2; j>=0; j=j-1) begin: col
		if (i==N-1) begin //first row
			xor cmpy(d[j], y[N-1], y[j]);
			if (j==0) begin //rightmost
				intdiv_sub sub(d[j], {x[N-1], 1'b0}, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], y[N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
				intdiv_sub sub(d[j], 2'b00, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
		else if (i>=N-STEPS) begin //first stage rows
			if (j==0) begin
			intdiv_sub sub(d[j], xneg[i], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], y[N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
			intdiv_sub sub(d[j], rc[i+1][j-1], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
		else if (`BOUND==0) begin
			if (j==0) begin
			intdiv_sub sub(reg_d[`STG][j], reg_rc[`STG][j], ps[i][j], tr[i][j]); //rec_rc because in its lsb it stores xneg
			intdiv_abs abs(ps[i][j], reg_y[`STG][N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
			intdiv_sub sub(reg_d[`STG][j], reg_rc[`STG][j], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
		else begin
			if (j==0) begin //rightmost
			intdiv_sub sub(reg_d[`STG][j], xneg[i], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], reg_y[`STG][N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
			intdiv_sub sub(reg_d[`STG][j], rc[i+1][j-1], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
	end
  end

  for (j=N-1; j>=0; j=j-1) begin: star
	if (j<N-1) intdiv_sub sub(reg_d[1][j], rc[0][j], psl[j], trl[j]);
	else intdiv_sub sub(1'b0, rc[0][j], psl[j], trl[j]);
	if (j==N-1) intdiv_abs abs(psl[j], trl[j-1], 2'b00, rs[j], ssprop[j]);
	else if (j==0) intdiv_abs abs(psl[j], reg_y[1][N-1], ssprop[j+1], rs[j], ssprop[j]);
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

  intdiv_negconv #(.WIDTH(N)) negconv(reg_rflat, r, reg_x[0][N-1]);	

  intdiv_padj #(.WIDTH(N-1)) 
	padjuster (
	.op(reg_p[0][N-1:1]),
	.res(z[N-1:1]),
	.enable(reg_padj)
	);
  assign z[0] = reg_seladj;

  integer pp, cc, ss;

  always @(posedge clock)
  begin

  if (reset==1'b1) begin
	for (pp=0; pp<=STAGES-1; pp=pp+1)
        begin
	reg_y[pp] <= 0;
	reg_x[pp] <= 0;
	end
	for (pp=0; pp<=STAGES-1; pp=pp+1)
	begin
		for (cc=0; cc<=N; cc=cc+1) begin 
			reg_rc[pp][cc] <= 0;
		end
		reg_sign[pp] <= 0;
	end
  end
  else begin

	//load and propagate inputs
	reg_y[STAGES-1] <= y;
	reg_x[STAGES-1] <= x;
	reg_d[STAGES-1] <= d;
	for (pp=0; pp<STAGES-1; pp=pp+1)
        begin
		reg_y[pp] <= reg_y[pp+1];
		reg_x[pp] <= reg_x[pp+1];
		reg_d[pp] <= reg_d[pp+1];
	end

	//load operands for padjuster
	reg_padj <= padj;
	reg_seladj <= seladj;

	//load operands for negconv
	reg_rflat <= rflat;

	for (pp=0; pp<STAGES; pp=pp+1)
	begin
		//store partial reminders performing an horizontal shift left in indexes
		for(cc=N; cc>0; cc=cc-1) begin
			reg_rc[pp][cc] <= rc[pp*STEPS][cc-1];
		end
		if(pp!=0) reg_rc[pp][0] <= xneg[pp*STEPS-1];

		//store sign chain
		reg_sign[pp] <= sign[pp*STEPS];
	end

	//store quotient digits
	for (pp=STAGES-1; pp>=0; pp=pp-1)
	begin
		reg_p[pp][pp*STEPS+:STEPS] <= p[pp*STEPS+:STEPS];
	end

	//propagate partial quotients
	for (pp=0; pp<STAGES-1; pp=pp+1)
	begin
		for (ss=0; ss<STAGES-1-pp; ss=ss+1) begin
		reg_p[pp][(N-1)-ss*STEPS-:STEPS] <= reg_p[pp+1][(N-1)-ss*STEPS-:STEPS];
		end
	end
  end
  end

endmodule

//test bench
module intdiv_intdiv_tb();

  parameter N = 16;

  parameter PERIOD = 1000;

  parameter STAGESTOTAL = 4;

  reg signed [N-1:0] x_tb;
  reg signed [N-1:0] y_tb;
  wire signed [N-1:0] z_tb;
  wire signed [N-1:0] r_tb;

  reg signed [N-1:0] z_exp[STAGESTOTAL-1:0];
  reg signed [N-1:0] r_exp[STAGESTOTAL-1:0];
  reg alarm;

  reg CLKtb;
  reg reset_tb;

  intdiv_intdiv #(.N(N)) 
	intdiv (
	.x(x_tb),
	.y(y_tb),
	.z(z_tb),
	.r(r_tb),
	.reset(reset_tb),
	.clock(CLKtb)
	);

  integer i, j, k;
  
  //automated exhaustive self-checking
  

  always
  begin
	CLKtb=0;
	#(PERIOD/2);
	CLKtb=1;
	#(PERIOD/2);
  end

  initial
  begin
	i=0;
	j=1;
	reset_tb=0;
  end
  always@(negedge CLKtb)
  begin
	for (k=0; k<STAGESTOTAL-1; k=k+1) begin
		z_exp[k+1] <= z_exp[k];
		r_exp[k+1] <= r_exp[k];
	end
	if (i<(2**N)) begin
		x_tb = i;
		if (j<(2**N)) begin
			y_tb = j;
			z_exp[0] = x_tb/y_tb;
			r_exp[0] = x_tb%y_tb;
			j=j+1;			
		end
		else begin
			j=1;  //avoid division by 0
			i=i+1;
		end
	end
	else $stop;
  end
  always@(negedge CLKtb)
  begin
	if (z_tb != z_exp[STAGESTOTAL-1] || r_tb != r_exp[STAGESTOTAL-1]) begin
	   $display ("Error: expected values z=%d r=%d, got values %d %d", z_exp[STAGESTOTAL-1], r_exp[STAGESTOTAL-1], z_tb, r_tb);
	   alarm = 1'b1;
	end
	else alarm = 1'b0;
  end
  
  /*
  initial
  begin
  reset_tb = 1;
  #2000;
  reset_tb = 0;
  x_tb = 5'd7;
  y_tb = 5'd3;
  #PERIOD;
  x_tb = 5'd10;
  y_tb = 5'd4;
  #PERIOD;
  x_tb = -5'd13;
  y_tb = 5'd4;
  #PERIOD;
  x_tb = -5'd120;
  y_tb = 5'd11;
  #10000;
  $stop;
  end
  */
  

endmodule

