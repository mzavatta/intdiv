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

`define BOUND (i+1)%STEPS
`define STG (i/STEPS)+1

module intdiv_intdiv(clock, reset, x, y, reg_z, reg_r);

  parameter N=4;
  parameter STAGESTOTAL=6;  //pipeline stages
  parameter STAGES=STAGESTOTAL-1; //length of input chain, from the total exclude output stage
  parameter STAGESBODY=STAGES-1; //division of the circuit body, excludes input and output stage
  //output stage is padjust, negconv stage
  parameter STEPS=N/STAGESBODY;

  // IN
  input [N-1:0] x;  //DIVIDEND
  input [N-1:0] y;  //DIVISOR
  input clock;
  input reset;
  // OUT
  output [N-1:0] reg_z;  //FINAL QUOTIENT
  output [N-1:0] reg_r;  //FINAL REMINDER

  reg [N-1:0] reg_z;  //FINAL QUOTIENT
  reg [N-1:0] reg_r;  //FINAL REMINDER
  wire [N-1:0] z;
  wire [N-1:0] r;

  wire [N-2:0] d[STAGES-1:0];

  //wire [1:0] rc[N-1:0][N-1:0]; //N iterations, N-1 bits wide numbers
  wire [1:0] rc[N-1:0][N-1:0];
  wire [1:0] rs[N-1:0];
  wire [1:0] rsd2[N-1:0];
  wire [1:0] rsd2re[N-1:0];
  wire [((N-1)*2)+1:0] rflat;

  reg [((N-1)*2)+1:0] reg_rflat;

  //rc contents to be copied in reg_rc at stage output
  //reg_rc to be used as stage input
  reg [1:0] reg_rc[STAGESBODY-1:0][N:0];
  //reg reg_ps[STAGESBODY-1:0][N-2:0];
  //reg reg_tr[STAGESBODY-1:0][N-2:0];

  //have to hold dividend and divisors for the S operands simultaneously
  reg [N-1:0] reg_x[STAGES-1:0];
  reg [N-1:0] reg_y[STAGES-1:0];
  //reg [N-2:0] reg_d[S-1:0];

  //to hold sign outputs
  reg [STAGESBODY-1:0] reg_sign;

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

  reg [N-1:0] reg_p[STAGESBODY-1:0];
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

	if (i==N-1) intdiv_ovf ovf(2'b00, 2'b00, d[STAGES-1][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);
	else if (`BOUND==0) intdiv_ovf ovf(reg_rc[`STG][N], reg_rc[`STG][N-1], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);
	else intdiv_ovf ovf(rc[i+1][N-1], rc[i+1][N-2], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);

	if (i!=0) begin
		if (i==N-1) begin
		   intdiv_sgn sgn(sprop[i][0], reg_x[STAGES-1][i], sign[i]);
		   intdiv_neg neg(reg_x[STAGES-1][i-1], sign[i], xneg[i-1]);
		   xnor cmpp(p[i], sign[i], reg_y[STAGES-1][N-1]);
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
		if (`BOUND==0) intdiv_adj adj(reg_x[`STG][N-1], reg_y[`STG][N-1], reg_sign[`STG], sprop[i][0], ssprop[0], padj, seladj);
		else intdiv_adj adj(reg_x[`STG][N-1], reg_y[`STG][N-1], sign[i+1], sprop[i][0], ssprop[0], padj, seladj); //last row, i=0
	end

	for (j=N-2; j>=0; j=j-1) begin: col
		if (i==N-1) begin //upper row
			xor cmpy(d[`STG][j], reg_y[`STG][N-1], reg_y[`STG][j]);
			if (j==0) begin
				intdiv_sub sub(d[`STG][j], {reg_x[`STG][N-1], 1'b0}, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], reg_y[`STG][N-1], sprop[i][j+1], rc[i][j], sprop[i][j]); //rightmost
			end
			else begin
				intdiv_sub sub(d[`STG][j], 2'b00, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
		else if (`BOUND==0) begin
			xor cmpy(d[`STG][j], reg_y[`STG][N-1], reg_y[`STG][j]);
			if (j==0) begin
			intdiv_sub sub(d[`STG][j], reg_rc[`STG][j], ps[i][j], tr[i][j]); //rec_rc because in its lsb it stores xneg
			intdiv_abs abs(ps[i][j], reg_y[`STG][N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
			intdiv_sub sub(d[`STG][j], reg_rc[`STG][j], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
		else begin
			if (j==0) begin //rightmost
			intdiv_sub sub(d[`STG][j], xneg[i], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], reg_y[`STG][N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
			intdiv_sub sub(d[`STG][j], rc[i+1][j-1], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
	end

	/*
	st = 2'b0;
	st = st-1;
  	if (st==0) begin st=STEPS-1; sg=sg-1; end
	*/
  end

  for (j=N-1; j>=0; j=j-1) begin: star
	if (j<N-1) intdiv_sub sub(d[1][j], rc[0][j], psl[j], trl[j]);
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
  assign z[0] = seladj;

  integer pp, cc, ss;

  always @(posedge clock)
  begin

  if (reset==1'b1) begin
	for (pp=0; pp<=STAGES-1; pp=pp+1)
        begin
	reg_y[pp] <= 0;
	reg_x[pp] <= 0;
	end
	for (pp=0; pp<=STAGESBODY-1; pp=pp+1)
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
	for (pp=0; pp<STAGES-1; pp=pp+1)
        begin
		reg_y[pp] <= reg_y[pp+1];
		reg_x[pp] <= reg_x[pp+1];
	end

	//load operands for padjuster
	reg_p[STAGESBODY-1][N-1:N-STEPS] <= p[N-1:N-STEPS];
	reg_padj <= padj;
	reg_seladj <= seladj;

	//load operands for negconv
	reg_rflat <= rflat;

	//compose outputs in their register
	reg_z[0] <= reg_seladj;
	reg_z[N-1:1] <= z[N-1:1];
	reg_r <= r;

	for (pp=0; pp<STAGESBODY; pp=pp+1)
	begin
		//store partial reminders performing a shift in indexes
		for(cc=N; cc>0; cc=cc-1) begin
			reg_rc[pp][cc] <= rc[pp*STEPS][cc-1];
		end
		if(pp!=0) reg_rc[pp][0] <= xneg[pp*STEPS-1];

		//store sign chain
		reg_sign[pp] <= sign[pp*STEPS];
	end

	for (pp=STAGESBODY-1; pp>=0; pp=pp-1)
	begin
		//store quotient digits
		//reg_p[pp][((pp+1)*STEPS)-1:pp*STEPS] <= p[((pp+1)*STEPS)-1:pp*STEPS];
		reg_p[pp][pp*STEPS+:STEPS] <= p[pp*STEPS+:STEPS];
	end

	/*
	//propagate partial quotients
	for (pp=0; pp<STAGESBODY-1; pp=pp+1)
	begin
		//reg_p[pp][N-1+:N-(STAGES-pp-1)*STEPS] <= reg_p[pp+1][N-1+:N-(STAGES-pp-1)*STEPS];
		for(ss=STAGESBODY-1; ss>=0; ss=ss-1) begin
		reg_p[pp][ss*STEPS+:STEPS] <= reg_p[pp+1][ss*STEPS+:STEPS];
		end
	end
	*/

	//propagate partial quotients
	for (pp=0; pp<STAGESBODY-1; pp=pp+1)
	begin
		//reg_p[pp][N-1+:N-(STAGES-pp-1)*STEPS] <= reg_p[pp+1][N-1+:N-(STAGES-pp-1)*STEPS];
		//for(ss=0; ss<STAGESBODY-1; ss=ss+1) begin
		//reg_p[pp][ss*STEPS+:STEPS] <= reg_p[pp+1][ss*STEPS+:STEPS];
		//end
		for (ss=0; ss<STAGESBODY-1-pp; ss=ss+1) begin
		reg_p[pp][(N-1)-ss*STEPS-:STEPS] <= reg_p[pp+1][(N-1)-ss*STEPS-:STEPS];
		end
	end
  end
  end

endmodule

//test bench
module intdiv_intdiv_tb();

  parameter N = 4;

  parameter PERIOD = 1000;

  parameter STAGESTOTAL = 6;

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
	.reg_z(z_tb),
	.reg_r(r_tb),
	.reset(reset_tb),
	.clock(CLKtb)
	);

  integer i, j, k;


  initial
  begin
	i=0;
	j=1;
	reset_tb=0;
  end

  always
  begin
	CLKtb=0;
	#(PERIOD/2);
	CLKtb=1;
	#(PERIOD/2);
  end

  always@(negedge CLKtb)
  begin
	/*for (k=0; k<STAGESTOTAL-1; k=k+1) begin
		x_tb[k+1] <= x_tb[k];
		y_tb[k+1] <= y_tb[k]; 
	end*/
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
			j=1;
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
  */
  
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
  /*
  x_tb = 5'd30;
  y_tb = 5'd7;
  #100;
  x_tb = -5'd120;
  y_tb = 5'd11;
  #100;
  */

  /*
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
