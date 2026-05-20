// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER:
//
// MEMBERS:
//   - Member 1 Name, Student Number
//   - Member 2 Name, Student Number

// File        : InstructionMemory.v
// Description : Instruction Memory (ROM).
//               16 words × 16 bits. Contents loaded at simulation start from
//               the binary file ./test/test.prog using $readmemb.
//               This is a purely combinational module — the instruction output
//               updates immediately when the PC changes. No clock input.
//
// Task 3 — Student Implementation Required
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module InstructionMemory (
    input  [15:0] pc,           // Program Counter (byte address)
    output [15:0] instruction   // Fetched 16-bit instruction word
);

    // -------------------------------------------------------------------------
    // TODO: Declare the instruction memory array.
    //       It should hold `ROW_I entries, each `COL bits wide.
    //
    //       reg [`COL-1:0] memory [`ROW_I-1:0];
    // -------------------------------------------------------------------------


    // -------------------------------------------------------------------------
    // TODO: Derive the word address from the byte-addressed PC.
    //
    //       Because each instruction is 16 bits (2 bytes) wide, and the PC
    //       increments by 2 each cycle, the word index into the ROM is:
    //
    //           wire [3:0] rom_addr = pc[4:1];
    //
    //       This discards the byte-select bit (pc[0], always 0 for aligned
    //       accesses) and maps the byte address to a word index:
    //           PC=0x0000 -> rom_addr=0
    //           PC=0x0002 -> rom_addr=1
    //           PC=0x0004 -> rom_addr=2   ... and so on.
    // -------------------------------------------------------------------------


    // -------------------------------------------------------------------------
    // TODO: Load the instruction memory contents from file at simulation start.
    //       The file ./test/test.prog must contain one 16-bit binary value
    //       per line (e.g. 0010000001010000).
    //
    //       initial begin
    //           $readmemb("./test/test.prog", memory, 0, 14);
    //       end
    //
    //       Note: the third and fourth arguments (0, 14) specify the start and
    //       end indices in the array to fill. Adjust if your program is longer.
    // -------------------------------------------------------------------------


    // -------------------------------------------------------------------------
    // TODO: Drive the instruction output with a continuous assignment.
    //       The output must update combinationally whenever rom_addr changes.
    //
    //       assign instruction = memory[rom_addr];
    // -------------------------------------------------------------------------


endmodule
