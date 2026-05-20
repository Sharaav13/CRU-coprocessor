// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER:
//
// MEMBERS:
//   - Member 1 Name, Student Number
//   - Member 2 Name, Student Number

// File        : ALU.v
// Description : 16-bit Arithmetic and Logic Unit (ALU).
//               Implements all arithmetic and logic operations required by
//               the StarCore ISA. This is a purely combinational module —
//               it has no clock input and no internal state.
//
// Task 1 — Student Implementation Required
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ALU (
    input  [15:0] a,            // Operand A  — connected to GPR read data 1
    input  [15:0] b,            // Operand B  — connected to ALUSrc mux output
    input  [ 2:0] alu_control,  // Operation select — driven by ALU_Control unit
    output reg [15:0] result,   // Computed result  — fed to DataMemory and write-back mux
    output         zero         // Zero flag: asserted (1) when result == 16'd0
);

    // -------------------------------------------------------------------------
    // TODO: Implement the zero flag using a continuous assignment.
    //       The zero output must be a wire driven by a single assign statement.
    //       It should be 1 when result equals 16'd0, and 0 otherwise.
    //
    //       assign zero = ...;
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // TODO: Implement the ALU operations using a combinational always block.
    //
    //       Use: always @(*) begin
    //                case (alu_control)
    //                    ...
    //                endcase
    //            end
    //
    //       ALUcnt | Operation | Expression
    //       -------+-----------+------------------------------
    //       3'b000 | ADD       | result = a + b
    //       3'b001 | SUB       | result = a - b
    //       3'b010 | INV       | result = ~a   (bitwise NOT; b is ignored)
    //       3'b011 | SHL       | result = a << b[3:0]
    //       3'b100 | SHR       | result = a >> b[3:0]
    //       3'b101 | AND       | result = a & b
    //       3'b110 | OR        | result = a | b
    //       3'b111 | SLT       | result = (a < b) ? 16'd1 : 16'd0  (unsigned)
    //       default| ADD       | result = a + b   (safe fallback)
    //
    //       Hint: The SLT comparison uses unsigned arithmetic because Verilog
    //       treats reg/wire values as unsigned by default. This is correct
    //       for the StarCore ISA.
    // -------------------------------------------------------------------------


endmodule
