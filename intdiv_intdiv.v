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

//`define BOUND (i+1)%STEPS
`define BOUND ( (( jj-1+ ((ii%(NPROPS/4))*4) ) %NPROPS)  )
//`define STG (ii+((jj-1)/NPROPS))
`define STG (  (ii/(NPROPS/4))  +       (( jj-1+ ((ii%(NPROPS/4))*4) ) /NPROPS)         )
`define BOUNDLINE ((ii-1)%(NPROPS/4)) //OVF or SGN after next to the bound
`define BOUNDONLINE ((ii)%(NPROPS/4)) //OVF or SGN on the bound

module intdiv_intdiv(clock, reset, x, y, reg_z, reg_r);

  parameter N=4; //operands width
  parameter NPROPS=4; //propagations to be done in each stage
  parameter STAGESBODY=((5*N)/NPROPS); //total stages in the body
  parameter STAGES=STAGESBODY+2; //accounts for load operands and output stage
  parameter STAGESOUT=(STAGESBODY-((N/NPROPS)-1)); //cycles from the first produced quotient digit to the last
  parameter QSTEPS=(NPROPS/4); //quotient digits produced in one generic stage
  parameter INITQSTEPS=(QSTEPS-((N/NPROPS)-1)); //quotient digits produced in the first stage
  parameter ENDQSTEPS=((N-INITQSTEPS)%QSTEPS); //quotient digits produced in the last stage
  parameter REMSTAGES=(((N-1)/NPROPS)+1+1) //they are 1, NPROPS, NPROPS... NPROPS-1 bits wide

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

  wire [N-2:0] d;

  //wire [1:0] rc[N-1:0][N-1:0]; //N iterations, N-1 bits wide numbers
  wire [1:0] rc[N-1:0][N-1:0];
  wire [1:0] rs[N-1:0];
  wire [1:0] rsd2[N-1:0];
  wire [1:0] rsd2re[N-1:0];
  wire [((N-1)*2)+1:0] rflat;

  reg [((N-1)*2)+1:0] reg_rflat;

  //have to hold dividend and divisors for the S operands simultaneously
  reg [N-1:0] reg_x[STAGES-1:0];
  reg [N-1:0] reg_y[STAGES-1:0];
  reg [N-2:0] reg_d[STAGES-1:0];

  wire [1:0] sprop[N-1:0][N-1:0];
  wire [1:0] ssprop[N-1:0];
  wire ps[N-1:0][N-2:0];
  wire tr[N-1:0][N-2:0];
  wire psl[N-1:0];
  wire trl[N-1:0];

  //elements at stage boundaries input from these regs instead of the wires
  reg [1:0] reg_rc[N-1:0][N:0]; //additional width to account for shift and xneg entry
  reg [1:0] reg_sprop[N-1:0][N-1:0];
  reg [1:0] reg_ssprop[N-1:0];
  reg reg_ps[N-1:0][N-2:0];
  reg reg_tr[N-1:0][N-2:0];
  reg reg_psl[N-1:0];
  reg reg_trl[N-1:0];

  wire [1:0] xneg[N-2:0];
  wire [N-1:0] p; 

  reg [N-1:0] reg_p[STAGESOUT-1:0];
  //as many as the pipeline stages in order to hold the partially computed quotient
  //p[0] needs to be fed to the adjuster at every clock cycle

  reg [1:0] reg_rc[REMSTAGES-1:0][N-1:0];
  reg [1:0] reg_rs[REMSTAGES-1:0][N-1:0];

  wire sign[N-1:0];
  //to hold sign outputs
  reg reg_sign[N-1:0];
  reg reg_sign_pause;

  wire padj, seladj;
  //to hold adj cell output
  reg reg_padj;
  reg reg_seladj;

  wire wrong[N-1:0];

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
	localparam integer ii = N-1-i;

	localparam integer jj = N;
	if (i!=0) begin
		if (i==N-1) begin
		   intdiv_sgn sgn(sprop[i][0], reg_x[`STG][i], sign[i]);
		   intdiv_neg neg(reg_x[`STG][i-1], sign[i], xneg[i-1]);
		   xnor cmpp(p[i], sign[i], reg_y[`STG][N-1]);
		end
		else if (`BOUNDLINE==0) begin
		   intdiv_sgn sgn(sprop[i][0], reg_sign[i+1], sign[i]);
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
	   if (N==4) begin
		if (NPROPS==4) intdiv_adj adj(reg_x[`STG+1][N-1], reg_y[`STG+1][N-1], reg_sign_pause, reg_sprop[i][0], ssprop[0], padj, seladj);
		else intdiv_adj adj(reg_x[`STG+1][N-1], reg_y[`STG+1][N-1], reg_sign[i+1], reg_sprop[i][0], ssprop[0], padj, seladj);
	   end
	   else begin
		if (`BOUNDLINE==0)
		intdiv_adj adj(reg_x[`STG][N-1], reg_y[`STG][N-1], reg_sign[i+1], sprop[i][0], ssprop[0], padj, seladj);
		else 
		intdiv_adj adj(reg_x[`STG][N-1], reg_y[`STG][N-1], sign[i+1], sprop[i][0], ssprop[0], padj, seladj); //last row, i=0
	  end
	end

	for (j=N-1; j>=0; j=j-1) begin: col
	   localparam integer jj = N-1-j;

	   if (jj==0) begin
		if (i==N-1) intdiv_ovf ovf(2'b00, 2'b00, d[N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);
		else if (i==N-2) intdiv_ovf ovf(rc[i+1][N-1], rc[i+1][N-2], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);
		else if (`BOUNDLINE==0) intdiv_ovf ovf(reg_rc[i+1][N-1], rc[i+1][N-2], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);
		else intdiv_ovf ovf(rc[i+1][N-1], rc[i+1][N-2], tr[i][N-2], rc[i][N-1], sprop[i][N-1], wrong[i]);
	   end
	   else begin
		if (i==N-1) begin //upper row
			xor cmpy(d[j], reg_y[0][N-1], reg_y[0][j]);
			if (j==0) begin
				intdiv_sub sub(reg_d[`STG][j], {reg_x[`STG][N-1], 1'b0}, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], reg_y[`STG][N-1], sprop[i][j+1], rc[i][j], sprop[i][j]); //rightmost
			end
			else if (`BOUND==0) begin //grab sign from reg
				intdiv_sub sub(reg_d[`STG][j], 2'b00, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], tr[i][j-1], reg_sprop[i][j+1], rc[i][j], sprop[i][j]);
			end/*
			else if (jj>NPROPS) begin //can write also `STG>0 //grab d from proper register 
				intdiv_sub sub(reg_d[`STG][j], 2'b00, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end*/
			else begin
				intdiv_sub sub(reg_d[`STG][j], 2'b00, ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
		else begin
			if (j==0) begin //rightmost
			   if (`BOUND-2==0) begin //have to take xneg from reg_rc
				intdiv_sub sub(reg_d[`STG][j], reg_rc[i+1][j], ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], reg_y[`STG][N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			   end
			   else begin //have to take xneg from wire
				intdiv_sub sub(reg_d[`STG][j], xneg[i], ps[i][j], tr[i][j]);
				intdiv_abs abs(ps[i][j], reg_y[`STG][N-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			   end
			end
			else if (`BOUND==0) begin
			intdiv_sub sub(reg_d[`STG-1][j], rc[i+1][j-1], ps[i][j], tr[i][j]);
			intdiv_abs abs(reg_ps[i][j], reg_tr[i][j-1], reg_sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else if (`BOUND-1==0) begin
			intdiv_sub sub(reg_d[`STG-1][j], rc[i+1][j-1], ps[i][j], tr[i][j]);
			intdiv_abs abs(reg_ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else if (`BOUND-2==0) begin
			intdiv_sub sub(reg_d[`STG][j], reg_rc[i+1][j], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
			else begin
			intdiv_sub sub(reg_d[`STG][j], rc[i+1][j-1], ps[i][j], tr[i][j]);
			intdiv_abs abs(ps[i][j], tr[i][j-1], sprop[i][j+1], rc[i][j], sprop[i][j]);
			end
		end
	   end
	end
  end

  for (j=N-1; j>=0; j=j-1) begin: star
    localparam integer ii = N;
    localparam integer jj = N-1-j;
	//if (j<N-1) intdiv_sub sub(d[1][j], rc[0][j], psl[j], trl[j]);
	//else intdiv_sub sub(1'b0, rc[0][j], psl[j], trl[j]);
	if (j==N-1) begin 
	   intdiv_abs abs(psl[j], trl[j-1], 2'b00, rs[j], ssprop[j]);
	   if (`BOUNDONLINE==0) intdiv_sub sub(1'b0, reg_rc[0][j], psl[j], trl[j]);
	   else intdiv_sub sub(1'b0, rc[0][j], psl[j], trl[j]);
	end
	else if (j==0) begin
	   if (`BOUND-2==0) intdiv_sub sub(reg_d[`STG][j], reg_rc[0][j], psl[j], trl[j]);
	   else intdiv_sub sub(reg_d[`STG][j], rc[0][j], psl[j], trl[j]);
	   intdiv_abs abs(psl[j], reg_y[`STG][N-1], ssprop[j+1], rs[j], ssprop[j]);
	end
	else if (`BOUND==0) begin
	   intdiv_sub sub(reg_d[`STG-1][j], rc[0][j], psl[j], trl[j]);
	   intdiv_abs abs(reg_psl[j], reg_trl[j-1], reg_ssprop[j+1], rs[j], ssprop[j]);
	end
	else if (`BOUND-1==0) begin
	   intdiv_sub sub(reg_d[`STG-1][j], rc[0][j], psl[j], trl[j]);
	   intdiv_abs abs(reg_psl[j], trl[j-1], ssprop[j+1], rs[j], ssprop[j]);
	end
	else if (`BOUND-2==0) begin
	   intdiv_sub sub(reg_d[`STG][j], reg_rc[0][j], psl[j], trl[j]);
	   intdiv_abs abs(psl[j], trl[j-1], ssprop[j+1], rs[j], ssprop[j]);
	end
	else begin
	   intdiv_sub sub(reg_d[1][j], rc[0][j], psl[j], trl[j]);
	   intdiv_abs abs(psl[j], trl[j-1], ssprop[j+1], rs[j], ssprop[j]);
	end
  end

  for (j=N-1; j>=0; j=j-1) begin: select
	assign rsd2[j] = seladj ? reg_rc[0][j] : reg_rs[j];
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

/*  if (reset==1'b1) begin
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
  else begin */

	//load and propagate inputs
	/*
	reg_y[STAGES-1] <= y;
	reg_x[STAGES-1] <= x;
	reg_d[STAGES-1] <= d;
	for (pp=0; pp<STAGES-1; pp=pp+1)
        begin
		reg_y[pp] <= reg_y[pp+1];
		reg_x[pp] <= reg_x[pp+1];
		reg_d[pp] <= reg_d[pp+1];
	end */
	reg_y[0] <= y;
	reg_x[0] <= x;
	reg_d[0] <= d;
	for (pp=0; pp<STAGES-1; pp=pp+1)
        begin
		reg_y[pp+1] <= reg_y[pp];
		reg_x[pp+1] <= reg_x[pp];
		reg_d[pp+1] <= reg_d[pp];
	end

	//load operands for padjuster
	//reg_p[STAGESBODY-1][N-1:N-QSTEPS] <= p[N-1:N-QSTEPS];
	reg_padj <= padj;
	reg_seladj <= seladj;

	//load operands for negconv
	reg_rflat <= rflat;

	//compose outputs in their register
	reg_z[0] <= reg_seladj;
	reg_z[N-1:1] <= z[N-1:1];
	reg_r <= r;

	for (pp=0; pp<N; pp=pp+1)
	begin
		//store partial reminders performing a shift in indexes
		for(cc=N; cc>0; cc=cc-1) begin
			if (pp==0) reg_rc[pp][cc-1] <= rc[pp][cc-1]; //no shift in star row
			else reg_rc[pp][cc] <= rc[pp][cc-1];
		end
		if(pp!=0) reg_rc[pp][0] <= xneg[pp-1];

		//store sign chain
		reg_sign[pp] <= sign[pp]; 
	end

	if (N==4 && NPROPS==4)
		reg_sign_pause <= reg_sign[1];

	for (pp=0; pp<N; pp=pp+1)
	begin
		for(cc=N-1; cc>=0; cc=cc-1) begin
			reg_sprop[pp][cc] <= sprop[pp][cc];
			if (cc<N-1) begin
				reg_ps[pp][cc] <= ps[pp][cc];
				reg_tr[pp][cc] <= tr[pp][cc];
			end
		end
	end

	//store star row
	for (pp=0; pp<N; pp=pp+1) begin
		reg_ssprop[pp] <= ssprop[pp];
		reg_psl[pp] <= psl[pp];
		reg_trl[pp] <= trl[pp];
	end

	//store quotient digits
	/*
	for (pp=STAGESBODY-1; pp>=0; pp=pp-1)
	begin

		reg_p[pp][pp*STEPS+:STEPS] <= p[pp*STEPS+:STEPS];
	end
	*/
	reg_p[STAGESOUT-1][N-1-:INITQSTEPS] <= p[N-1-:INITQSTEPS]; //store first
	reg_p[0][0+:1] <= p[0+:1];  //store last
	for (pp=0; pp<STAGESOUT-2; pp=pp+1) //store intermediate segments
	begin
		reg_p[STAGESOUT-2-pp][N-1-INITQSTEPS-(pp*QSTEPS)-:QSTEPS] <= p[N-1-INITQSTEPS-(pp*QSTEPS)+:QSTEPS];
	end

	//propagate partial quotients
	//propagate first row
	for (pp=0; pp<STAGESOUT-1; pp=pp+1)
		 reg_p[pp][N-1-:INITQSTEPS] <= reg_p[pp+1][N-1-:INITQSTEPS];
	for (pp=0; pp<STAGESOUT-2; pp=pp+1) //propagate intermediate rows
	begin
		for (ss=0; ss<STAGESOUT-2-pp; ss=ss+1) begin
		reg_p[pp][(N-1)-INITQSTEPS-ss*QSTEPS-:QSTEPS] <= reg_p[pp+1][(N-1)-INITQSTEPS-ss*QSTEPS-:QSTEPS];
		end
	end
	//last row does not need prop

	//store final quotients
	reg_rc[REMSTAGES-1][N-1] <= rc[0][N-1];
	reg_rs[REMSTAGES-1][N-1] <= rs[N-1];
	for(pp=0; pp<REMSTAGES-2; pp=pp+1) begin
		reg_rc[REMSTAGES-2-PP][N-2-(NPROPS*pp)-:NPROPS] <= rc[0][N-2-(NPROPS*pp)-:NPROPS];
		reg_rs[REMSTAGES-2-PP][N-2-(NPROPS*pp)-:NPROPS] <= rs[N-2-(NPROPS*pp)-:NPROPS];
	end
	reg_rc[0][0:NPROPS-2] <= rc[0][0:NPROPS-2];
	reg_rs[0][0:NPROPS-2] <= rs[0:NPROPS-2];
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
  
  //automated exhaustive self-checking
 
  /*initial
  begin
	i=0;
	j=1;
	reset_tb=0;
  end*/
  always
  begin
	CLKtb=0;
	#(PERIOD/2);
	CLKtb=1;
	#(PERIOD/2);
  end
  /*always@(negedge CLKtb)
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
  */
  
  initial
  begin
  //reset_tb = 1;
  #2000;
  //reset_tb = 0;
  x_tb = 5'd7;
  y_tb = 5'd3;
  #40000;
  $stop;
  #PERIOD;
  x_tb = 5'd3;
  y_tb = 5'd3;
  #PERIOD;
  x_tb = 5'd4;
  y_tb = 5'd2;
  #PERIOD;
  x_tb = 5'd6;
  y_tb = 5'd2;
  #40000;
  $stop;
  x_tb = -5'd13;
  y_tb = 5'd4;
  #PERIOD;
  x_tb = -5'd120;
  y_tb = 5'd11;
  #10000;
  $stop;
  end

endmodule
