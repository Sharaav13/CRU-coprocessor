// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER: 23
//
// MEMBERS:
//   - Member 1 Max Mendelow, MNDMAX003
//   - Member 2 Sharaav Dhebideen, DHBSHA001

// File        : ControlUnit.v
// Description : Main Control Unit.
//               Decodes the 4-bit opcode from the fetched instruction and
//               asserts the full set of control signals that govern the
//               Datapath for the current clock cycle.
//               This is a purely combinational module.
//
// Task 6 — Student Implementation Required
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ControlUnit (
    input  [3:0] opcode,        // Instruction opcode [15:12] from Datapath

    // ALU control
    output reg [1:0] alu_op,    // Passed to ALU_Control: 10=mem, 01=branch, 00=R-type

    // PC control
    output reg       jump,      // Assert to select the jump target PC
    output reg       beq,       // Assert to enable branch-on-equal
    output reg       bne,       // Assert to enable branch-on-not-equal

    // Memory control
    output reg       mem_read,  // Assert to enable data memory read output
    output reg       mem_write, // Assert to write data memory on posedge clk

    // Datapath multiplexer selects
    output reg       alu_src,   // 0 = RS2 register value; 1 = sign-extended immediate
    output reg       reg_dst,   // 0 = instr[8:6] (I-type WS); 1 = instr[5:3] (R-type WS)
    output reg       mem_to_reg,// 0 = ALU result; 1 = data memory read data (for LD)
    output reg       reg_write  // Assert to write the register file on posedge clk
);

    // -------------------------------------------------------------------------
    // Control signal truth table (from Section 3.3 of the manual):
    //
    // Opcode | Instr     | RegDst | ALUSrc | MemToReg | RegWrite | MemRd | MemWr | Branch | ALUOp | Jump
    // -------+-----------+--------+--------+----------+----------+-------+-------+--------+-------+-----
    // 0000   | LD        |   0    |   1    |    1     |    1     |   1   |   0   |   0    |  10   |  0
    // 0001   | ST        |   0    |   1    |    0     |    0     |   0   |   1   |   0    |  10   |  0
    // 0010–  | R-type    |   1    |   0    |    0     |    1     |   0   |   0   |   0    |  00   |  0
    // 1001   | (ADD–SLT) |        |        |          |          |       |       |        |       |
    // 1010   | Reserved  |   0    |   0    |    0     |    0     |   0   |   0   |   0    |  00   |  0
    // 1011   | BEQ       |   0    |   0    |    0     |    0     |   0   |   0   |   1    |  01   |  0
    // 1100   | BNE       |   0    |   0    |    0     |    0     |   0   |   0   |   1    |  01   |  0
    // 1101   | JMP       |   0    |   0    |    0     |    0     |   0   |   0   |   0    |  00   |  1
    //
    // For BEQ and BNE the Branch signal is asserted; the Datapath uses beq & zero_flag
    // and bne & ~zero_flag respectively to determine whether the branch is taken.
    // -------------------------------------------------------------------------

    // -------------------------------------------------------------------------
    // TODO: Implement the control unit using always @(*) and a case statement.
    //
    //       STEP 1 — Assign safe defaults to ALL outputs at the top of the
    //       always block BEFORE the case statement. This prevents accidental
    //       latches when an opcode branch does not assign every signal:
    //
               always @(*) begin // Whenever input changes, assign these values to the output ports
                   // Safe defaults: no writes, no branches, no jumps
                   reg_dst   = 1'b0;
                   alu_src   = 1'b0;
                   mem_to_reg= 1'b0;
                   reg_write = 1'b0;
                   mem_read  = 1'b0;
                   mem_write = 1'b0;
                   beq       = 1'b0;
                   bne       = 1'b0;
                   alu_op    = 2'b00;
                   jump      = 1'b0;
    //
                   case (opcode)
                       4'b0000: begin  // LD
                           reg_dst   = 1'b0;
                           alu_src   = 1'b1;
                           mem_to_reg= 1'b1;
                           reg_write = 1'b1;
                           mem_read  = 1'b1;
                           alu_op    = 2'b10;
                       end
    //
                       4'b0001: begin  // ST
                           alu_src   = 1'b1;
                           mem_write = 1'b1;
                           alu_op    = 2'b10;                          
                       end
    //
    //                   // R-type instructions share identical control signals.
    //                   // List each opcode individually OR use a Verilog 2001
    //                   // comma-separated case item:
                       4'b0010, 4'b0011, 4'b0100, 4'b0101, 4'b0110, 4'b0111, 4'b1000, 4'b1001: begin
                           reg_dst   = 1'b1;
                           reg_write = 1'b1;
                       end
    //
                       4'b1010: begin  // Reserved — must be a no-operation
                           // All outputs remain at safe defaults.
                           // No register or memory side-effects.
                       end
    //
                       4'b1011: begin  // BEQ
                           beq    = 1'b1;
                           alu_op = 2'b01;
                       end
    //
                       4'b1100: begin  // BNE
                           bne    = 1'b1;
                           alu_op = 2'b01;
                       end
    //
                       4'b1101: begin  // JMP
                           jump = 1'b1;
                       end
    //
                       default: begin
                           // Safe defaults already set above.
                       end
                   endcase
               end
    // -------------------------------------------------------------------------


endmodule
