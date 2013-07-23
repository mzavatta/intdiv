`timescale 1ns / 1ps

`define ON 1'b1
`define OFF 1'b0

/*
//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10
*/

//sd2 encoding
`define NEG1_pn 2'b01
`define ZERO_pn_1 2'b00
`define ZERO_pn_2 2'b11
`define POS1_pn 2'b10

/* Works only with (p,n) SD2 encoding
 * Input is N-bit SD2, output is N-bit 2C thus overflow might occur.
 * Converts any SD2 integer into its 2C representation, taking the inverse if enabled
 */
module intdiv_negconv(op, res, enable);

  parameter WIDTH = 5;

  // IN
  //input [1:0] op[WIDTH-1:0]; unfortunately illegal in Verilog (legal in SystemVerilog)
  input [((WIDTH-1)*2)+1:0] op; //WIDTH-wide SD2 number, (p,n)=p-n encoded
  input enable;
  // OUT
  output [WIDTH-1:0] res; //WIDTH-wide 2C number

  wire [1:0] opt[WIDTH-1:0];
  wire [WIDTH-1:0] P;
  wire [WIDTH-1:0] N;

  genvar j;
  generate

  //essentially remap op into a vector signal. Vectors cannot be inputs or outputs in Verilog
  for (j=WIDTH-1; j>=0; j=j-1) begin: signal
  assign opt[j][0] = op[j*2];
  assign opt[j][1] = op[j*2+1];
  end

  //swap (p,n) if enable=1
  //if enable=1 then P=n and N=p, otherwise P=p and N=n
  for (j=WIDTH-1; j>=0; j=j-1) begin: bits
	assign P[j] = enable ? opt[j][0] : opt[j][1];
	assign N[j] = enable ? opt[j][1] : opt[j][0];
  end

  endgenerate

  //result is subtraction of the two parts
  assign res = P-N;

endmodule


//test bench
module intdiv_negconv_tb();

  parameter WIDTH = 5;

  reg enable_tb;
  //reg [1:0] op_tb[WIDTH-1:0];
  reg [((WIDTH-1)*2)+1:0] op_tb;
  wire [WIDTH-1:0] res_tb;

  intdiv_negconv  #(.WIDTH(WIDTH))
	idnegconv(
	.op(op_tb),
	.res(res_tb),
	.enable(enable_tb)
	);

  
  initial
  begin
	op_tb = {`ZERO_pn_1, `POS1_pn, `NEG1_pn, `ZERO_pn_1, `POS1_pn};
	enable_tb = `OFF;
	#100;
	enable_tb = `ON;
	#100;
	op_tb = {`POS1_pn, `POS1_pn, `POS1_pn, `ZERO_pn_1, `POS1_pn};
	enable_tb = `OFF;
	#100;
	enable_tb = `ON;
	#100;
	op_tb = {`ZERO_pn_1, `ZERO_pn_1, `ZERO_pn_1, `ZERO_pn_1, `ZERO_pn_1};
	enable_tb = `OFF;
	#100;
	enable_tb = `ON;
	#100;
	op_tb = {`POS1_pn, `ZERO_pn_1, `ZERO_pn_1, `ZERO_pn_1, `NEG1_pn};
	enable_tb = `OFF;
	#100;
	enable_tb = `ON;
	#100;
	op_tb = {`ZERO_pn_1, `NEG1_pn, `ZERO_pn_1, `POS1_pn, `NEG1_pn};
	enable_tb = `OFF;
	#100;
	enable_tb = `ON;
	#100;
	op_tb = {`ZERO_pn_1, `NEG1_pn, `ZERO_pn_1, `POS1_pn, `NEG1_pn};
	enable_tb = `OFF;
	#100;
	enable_tb = `ON;
	#100;
	op_tb = {`NEG1_pn, `ZERO_pn_1, `ZERO_pn_1, `ZERO_pn_1, `ZERO_pn_1};
	enable_tb = `OFF;
	#100;
	enable_tb = `ON;
	#100;
	$stop;
  end
endmodule


/*
//for the moment only does a negation of a digit if enable is high
module intdiv_sdcmp(op, res, enable);

  //IN
  input [1:0] op;
  input enable;
  // OUT
  output [1:0] res;

  reg [1:0] res;
  always @(op or enable)
  begin
    if (enable == `ON) begin
  	case (op)
		{`POS1_1}: begin
			res <= `NEG1;
			end
		{`POS1_2}: begin
			res <= `NEG1;
			end
		{`NEG1}: begin
			res <= `POS1_1;
			end
		default: begin
			res <= `ZERO;
			end
	endcase
    end
    else res <= op;
  end

endmodule
*/
