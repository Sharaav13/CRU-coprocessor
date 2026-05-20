// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : ALU_Control_tb.v
// Description : Testbench for the ALU Control Unit (Task 5).
//               Drives every row of the ALU control truth table and verifies
//               the 3-bit ALUcnt output.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/ac_sim ../src/ALU_Control.v ALU_Control_tb.v
//   cd ../test && ../build/ac_sim
//   gtkwave ../waves/ac_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ALU_Control_tb;

    reg  [1:0] ALUOp;
    reg  [3:0] Opcode;
    wire [2:0] ALU_Cnt;

    ALU_Control uut (
        .ALUOp   (ALUOp),
        .Opcode  (Opcode),
        .ALU_Cnt (ALU_Cnt)
    );

    initial begin
        $dumpfile("../waves/ac_tb.vcd");
        $dumpvars(0, ALU_Control_tb);
    end

    integer fail_count;
    integer test_id;

    task check_cnt;
        input [2:0] got;
        input [2:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: ALU_Cnt = %b, expected = %b", id, got, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: ALU_Cnt = %b", id, got);
        end
    endtask

    initial begin
        fail_count = 0;
        test_id    = 1;
        $display("=== ALU_Control Testbench ===");

        // ------------------------------------------------------------------
        // ALUOp = 10 (memory access) — always ADD regardless of opcode
        // ------------------------------------------------------------------
        $display("--- ALUOp=10: all opcodes should map to ADD (000) ---");

        // TODO: Apply ALUOp=2'b10 with several different opcode values and
        //       verify ALU_Cnt is always 3'b000 (ADD).
        //
               ALUOp=2'b10; Opcode=4'h0; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;
        
               ALUOp=2'b10; Opcode=4'h1; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               ALUOp=2'b10; Opcode=4'h2; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;
        
               ALUOp=2'b10; Opcode=4'h3; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               ALUOp=2'b10; Opcode=4'h4; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;
        
               ALUOp=2'b10; Opcode=4'h5; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               ALUOp=2'b10; Opcode=4'h6; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;
        
               ALUOp=2'b10; Opcode=4'h7; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               ALUOp=2'b10; Opcode=4'h8; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;
        
               ALUOp=2'b10; Opcode=4'h9; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               ALUOp=2'b10; Opcode=4'hA; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;
        
               ALUOp=2'b10; Opcode=4'hB; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               ALUOp=2'b10; Opcode=4'hC; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;
        
               ALUOp=2'b10; Opcode=4'hD; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;


        // ------------------------------------------------------------------
        // ALUOp = 01 (branch) — always SUB regardless of opcode
        // ------------------------------------------------------------------
        $display("--- ALUOp=01: all opcodes should map to SUB (001) ---");

        // TODO: Apply ALUOp=2'b01 with several opcode values and verify
        //       ALU_Cnt is always 3'b001 (SUB).
               
               ALUOp=2'b01; Opcode=4'h0; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;
        
               ALUOp=2'b01; Opcode=4'h1; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;

               ALUOp=2'b01; Opcode=4'h2; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;
        
               ALUOp=2'b01; Opcode=4'h3; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;

               ALUOp=2'b01; Opcode=4'h4; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;
        
               ALUOp=2'b01; Opcode=4'h5; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;

               ALUOp=2'b01; Opcode=4'h6; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;
        
               ALUOp=2'b01; Opcode=4'h7; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;

               ALUOp=2'b01; Opcode=4'h8; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;
        
               ALUOp=2'b01; Opcode=4'h9; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;

               ALUOp=2'b01; Opcode=4'hA; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;
        
               ALUOp=2'b01; Opcode=4'hB; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;

               ALUOp=2'b01; Opcode=4'hC; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;
        
               ALUOp=2'b01; Opcode=4'hD; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;

        // ------------------------------------------------------------------
        // ALUOp = 00 (R-type) — decode from opcode
        // ------------------------------------------------------------------
        $display("--- ALUOp=00: decode per opcode ---");

        // TODO: Apply ALUOp=2'b00 with each R-type opcode and verify:
        //
        //       Opcode 4'h2 (ADD) -> ALU_Cnt = 3'b000
        //       Opcode 4'h3 (SUB) -> ALU_Cnt = 3'b001
        //       Opcode 4'h4 (INV) -> ALU_Cnt = 3'b010
        //       Opcode 4'h5 (SHL) -> ALU_Cnt = 3'b011
        //       Opcode 4'h6 (SHR) -> ALU_Cnt = 3'b100
        //       Opcode 4'h7 (AND) -> ALU_Cnt = 3'b101
        //       Opcode 4'h8 (OR)  -> ALU_Cnt = 3'b110
        //       Opcode 4'h9 (SLT) -> ALU_Cnt = 3'b111
        //
               // Test for ADD Opcode
               ALUOp=2'b00; Opcode=4'h2; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               // Test for SUB Opcode
               ALUOp=2'b00; Opcode=4'h3; #10;
               check_cnt(ALU_Cnt, 3'b001, test_id); test_id=test_id+1;

               // Test for INV Opcode
               ALUOp=2'b00; Opcode=4'h4; #10;
               check_cnt(ALU_Cnt, 3'b010, test_id); test_id=test_id+1;

               // Test for SHL Opcode
               ALUOp=2'b00; Opcode=4'h5; #10;
               check_cnt(ALU_Cnt, 3'b011, test_id); test_id=test_id+1;

               // Test for SHR Opcode
               ALUOp=2'b00; Opcode=4'h6; #10;
               check_cnt(ALU_Cnt, 3'b100, test_id); test_id=test_id+1;

               // Test for AND Opcode
               ALUOp=2'b00; Opcode=4'h7; #10;
               check_cnt(ALU_Cnt, 3'b101, test_id); test_id=test_id+1;

               // Test for OR Opcode
               ALUOp=2'b00; Opcode=4'h8; #10;
               check_cnt(ALU_Cnt, 3'b110, test_id); test_id=test_id+1;

               // Test for SLT Opcode
               ALUOp=2'b00; Opcode=4'h9; #10;
               check_cnt(ALU_Cnt, 3'b111, test_id); test_id=test_id+1;

        // ------------------------------------------------------------------
        // Default case
        // ------------------------------------------------------------------
        $display("--- Default (ALUOp=00, undefined opcode) -> ADD (000) ---");

        // TODO: Apply ALUOp=2'b00 with an undefined opcode (e.g. 4'hA or 4'hF)
        //       and verify ALU_Cnt defaults to 3'b000.

               // Test for reserved Opcode 1010
               ALUOp=2'b00; Opcode=4'hA; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               // Test for undefined Opcode 1110
               ALUOp=2'b00; Opcode=4'hE; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

               // Test for undefined Opcode 1111
               ALUOp=2'b00; Opcode=4'hF; #10;
               check_cnt(ALU_Cnt, 3'b000, test_id); test_id=test_id+1;

        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule
