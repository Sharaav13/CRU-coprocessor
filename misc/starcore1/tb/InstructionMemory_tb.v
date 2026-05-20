// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : InstructionMemory_tb.v
// Description : Testbench for the Instruction Memory module (Task 3).
//               Walks the PC through all valid addresses and verifies the
//               correct instruction word is output combinationally.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/im_sim ../src/InstructionMemory.v InstructionMemory_tb.v
//   cd ../test && ../build/im_sim
//   gtkwave ../waves/im_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module InstructionMemory_tb;

    reg  [15:0] pc;
    wire [15:0] instruction;

    InstructionMemory uut (.pc(pc), .instruction(instruction));

    initial begin
        $dumpfile("../waves/im_tb.vcd");
        $dumpvars(0, InstructionMemory_tb);
    end

    integer fail_count;
    integer test_id;
    // Expected instruction words — these must match the contents of test.prog.
    // Update these values after you finalise your test.prog file.
    reg [15:0] expected [0:14];

    initial begin
        fail_count = 0;
        test_id    = 1;

        $display("=== InstructionMemory Testbench ===");

        // TODO: Load the expected values to match your test.prog file.
        //       For example, if your first instruction is ADD R2,R0,R1 (0010000001010000):
        //           expected[0]  = 16'b0010000001010000;
        //       Fill in all 15 entries to match your test.prog exactly.
        //
        //       expected[0]  = 16'bXXXXXXXXXXXXXXXX;
        //       expected[1]  = 16'bXXXXXXXXXXXXXXXX;
        //       ... (fill all 15)

        // TODO: Walk PC through addresses 0, 2, 4, ... 28 (14 instructions).
        //       At each address, verify instruction == expected[rom_index].
        //       Verify also that the output is combinational (no clock needed).
        //
        //       For each address:
        //           pc = 16'd0; #5;  // set PC, wait for combinational output
        //           if (instruction !== expected[0])
        //               $display("FAIL [T%0d]: PC=0 got %b exp %b",
        //                        test_id, instruction, expected[0]);
        //           else
        //               $display("PASS [T%0d]: PC=0 instr=%b", test_id, instruction);
        //           test_id = test_id + 1;
        //
        //           pc = 16'd2; #5;
        //           ... and so on.

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule
