`timescale 1ns / 1ps

`define ON 1'b1
`define OFF 1'b0

//sd2 encoding
`define NEG1 2'b11
`define ZERO 2'b00
`define POS1_1 2'b01
`define POS1_2 2'b10

/*
module intdiv_negconv(op, res, enable);

  parameter WIDTH=1;

  // IN
  input [1:0] op[WIDTH-1:0]; //WIDTH-wide SD2 number
  input enable;
  // OUT
  input [1:0] res[WIDTH-1:0]; //WIDTH-wide SD2 number

  reg [1:0] res[WIDTH-1:0];
  always @(op or enable)
  begin
    if (enable == `ON) res <= op + 1'b1;
    else res <= op;
  end

endmodule
*/

module intdiv_sdcmp(op, res, enable);

  //IN
  input [1:0] op;
  input enable;
  // OUT
  input [1:0] res;

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

endmodule;

