`timescale 1ns / 1ps

`define ON 1'b1
`define OFF 1'b0

module intdiv_padj(op, res, enable);

  parameter WIDTH=1;

  // IN
  input [WIDTH-1:0] op;
  input enable;
  // OUT
  output [WIDTH-1:0] res;

  reg [WIDTH-1:0] res;
  always @(op or enable)
  begin
    if (enable == `ON) res <= op + 1'b1;
    else res <= op;
  end

endmodule
