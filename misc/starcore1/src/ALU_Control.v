// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER: 23
//
// MEMBERS:
//   - Member 1 Max Mendelow, MNDMAX003
//   - Member 2 Sharaav Dhebideen, DHBSHA001

// File        : ALU_Control.v
// Description : ALU Control Unit.
//               Maps the 2-bit ALUOp signal (from the Main Control Unit) and
//               the 4-bit instruction opcode to the 3-bit ALUcnt signal that
//               drives the ALU's operation select input.
//               This is a purely combinational module.
//
// Task 5 — Student Implementation Required
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ALU_Control (
    input  [1:0] ALUOp,         // From ControlUnit:
                                //   2'b10 = memory access (always ADD for address)
                                //   2'b01 = branch      (always SUB for comparison)
                                //   2'b00 = R-type      (decode from opcode)
    input  [3:0] Opcode,        // Instruction opcode field [15:12]
    output reg [2:0] ALU_Cnt    // To ALU alu_control input
);

    // -------------------------------------------------------------------------
    // TODO: Concatenate ALUOp and Opcode into a single 6-bit control word so
    //       you can use a casex statement with don't-care bits.
    //
        wire [5:0] control_in; // Creates a 6 bit (index 5 is MSB and index 0 is LSB) physical connection or wire
        assign control_in = {ALUOp, Opcode}; // Concatenate both input values through to control_in.
    //
    //       The casex truth table (from Section 3.4 of the manual):
    //
    //       control_in | ALU_Cnt | Operation   | Instruction
    //       -----------+---------+-------------+------------------
    //       6'b10xxxx  |  3'b000 | ADD         | LD, ST
    //       6'b01xxxx  |  3'b001 | SUB         | BEQ, BNE
    //       6'b000010  |  3'b000 | ADD         | ADD
    //       6'b000011  |  3'b001 | SUB         | SUB
    //       6'b000100  |  3'b010 | INV (NOT)   | INV
    //       6'b000101  |  3'b011 | SHL         | SHL
    //       6'b000110  |  3'b100 | SHR         | SHR
    //       6'b000111  |  3'b101 | AND         | AND
    //       6'b001000  |  3'b110 | OR          | OR
    //       6'b001001  |  3'b111 | SLT         | SLT
    //       default    |  3'b000 | ADD (safe)  | reserved / undefined
    //
    //       Implement using:
               always @(*) begin
                   casex (control_in)
                       6'b10xxxx : ALU_Cnt = 3'b000; // ADD         | LD, ST
                       6'b01xxxx : ALU_Cnt = 3'b001; // SUB         | BEQ, BNE
                       6'b000010 : ALU_Cnt = 3'b000; // ADD         | ADD
                       6'b000011 : ALU_Cnt = 3'b001; // SUB         | SUB
                       6'b000100 : ALU_Cnt = 3'b010; // INV (NOT)   | INV
                       6'b000101 : ALU_Cnt = 3'b011; // SHL         | SHL
                       6'b000110 : ALU_Cnt = 3'b100; // SHR         | SHR
                       6'b000111 : ALU_Cnt = 3'b101; // AND         | AND
                       6'b001000 : ALU_Cnt = 3'b110; // OR          | OR
                       6'b001001 : ALU_Cnt = 3'b111; // SLT         | SLT
                       default   : ALU_Cnt = 3'b000; // ADD (safe)  | reserved / undefined
                   endcase
               end
    //
    //       IMPORTANT: The 'x' in casex patterns matches any logic value
    //       (0, 1, X, or Z). This correctly encodes don't-care bits for the
    //       opcode field when ALUOp selects memory or branch mode.
    // -------------------------------------------------------------------------


endmodule
