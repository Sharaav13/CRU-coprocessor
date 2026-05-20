// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : GPR_tb.v
// Description : Testbench for the General Purpose Register File (Task 2).
//               Verifies synchronous write and asynchronous read behaviour
//               for all 8 registers, plus edge cases.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/gpr_sim ../src/GPR.v GPR_tb.v
//   cd ../test && ../build/gpr_sim
//   gtkwave ../waves/gpr_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module GPR_tb;

    // -------------------------------------------------------------------------
    // DUT port connections
    // -------------------------------------------------------------------------
    reg        clk;
    reg        reg_write_en;
    reg  [2:0] reg_write_dest;
    reg  [15:0] reg_write_data;
    reg  [2:0] reg_read_addr_1;
    reg  [2:0] reg_read_addr_2;
    wire [15:0] reg_read_data_1;
    wire [15:0] reg_read_data_2;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    GPR uut (
        .clk              (clk),
        .reg_write_en     (reg_write_en),
        .reg_write_dest   (reg_write_dest),
        .reg_write_data   (reg_write_data),
        .reg_read_addr_1  (reg_read_addr_1),
        .reg_read_data_1  (reg_read_data_1),
        .reg_read_addr_2  (reg_read_addr_2),
        .reg_read_data_2  (reg_read_data_2)
    );

    // -------------------------------------------------------------------------
    // Clock generation — 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("../waves/gpr_tb.vcd");
        $dumpvars(0, GPR_tb);
    end

    // -------------------------------------------------------------------------
    // Failure counter
    // -------------------------------------------------------------------------
    integer fail_count;
    integer test_id;
    integer i;

    initial begin
        fail_count = 0;
        test_id    = 1;
    end

    task check16;
        input [15:0] got;
        input [15:0] expected;
        input [63:0] id;
        begin
            if (got !== expected) begin
                $display("FAIL [T%0d]: got = 0x%h, expected = 0x%h", id, got, expected);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: value = 0x%h", id, got);
        end
    endtask

    // =========================================================================
    // STIMULUS AND CHECKING
    // =========================================================================
    initial begin
        $display("=== GPR Testbench ===");

        // Initialise control signals
        reg_write_en   = 1'b0;
        reg_write_dest = 3'd0;
        reg_write_data = 16'd0;
        reg_read_addr_1 = 3'd0;
        reg_read_addr_2 = 3'd0;

        // Wait one clock cycle for GPR to initialise
        @(posedge clk); #1;

        // ------------------------------------------------------------------
        // TEST GROUP 1: Write a unique value to every register and read back
        // ------------------------------------------------------------------
        $display("--- Test Group 1: Write and read back all 8 registers ---");

        // TODO: For each register R0–R7, perform a synchronous write followed
        //       by an asynchronous read and verify the value.
        //
        //       Use a loop or individual test cases. Example for R0:
        //
        //           reg_write_en   = 1'b1;
        //           reg_write_dest = 3'd0;
        //           reg_write_data = 16'hA000;     // unique value for R0
        //           @(posedge clk); #1;             // commit the write
        //           reg_write_en   = 1'b0;
        //
        //           reg_read_addr_1 = 3'd0; #2;    // asynchronous read settles
        //           check16(reg_read_data_1, 16'hA000, test_id);
        //           test_id = test_id + 1;
        //
        //       Suggested values: R0=0xA000, R1=0xB001, R2=0xC002, R3=0xD003,
        //                         R4=0xE004, R5=0xF005, R6=0x1006, R7=0x2007


        // ------------------------------------------------------------------
        // TEST GROUP 2: Write with reg_write_en = 0 must NOT change register
        // ------------------------------------------------------------------
        $display("--- Test Group 2: Disabled write must not modify register ---");

        // TODO: Attempt to write a different value to R0 with reg_write_en=0.
        //       Read back R0 and confirm it still holds its original value.
        //
        //           reg_write_en   = 1'b0;
        //           reg_write_dest = 3'd0;
        //           reg_write_data = 16'hDEAD;     // this value must NOT be written
        //           @(posedge clk); #1;
        //
        //           reg_read_addr_1 = 3'd0; #2;
        //           check16(reg_read_data_1, 16'hA000, test_id);  // original value
        //           test_id = test_id + 1;


        // ------------------------------------------------------------------
        // TEST GROUP 3: Simultaneous read from two different registers
        // ------------------------------------------------------------------
        $display("--- Test Group 3: Simultaneous dual-port read ---");

        // TODO: Set reg_read_addr_1 and reg_read_addr_2 to two different
        //       registers and verify both values are correct simultaneously.
        //
        //           reg_read_addr_1 = 3'd1; // R1
        //           reg_read_addr_2 = 3'd3; // R3
        //           #2;
        //           check16(reg_read_data_1, 16'hB001, test_id); test_id=test_id+1;
        //           check16(reg_read_data_2, 16'hD003, test_id); test_id=test_id+1;


        // ------------------------------------------------------------------
        // TEST GROUP 4: Read during write (write-before-read behaviour)
        // ------------------------------------------------------------------
        $display("--- Test Group 4: Read address matches write address during write ---");

        // TODO: Assert reg_write_en, set write and read addresses to the same
        //       register, and observe what reg_read_data_1 returns before
        //       the clock edge commits the write.
        //       Document in your report whether you see the old or new value.
        //
        //           reg_write_en   = 1'b1;
        //           reg_write_dest = 3'd2;
        //           reg_write_data = 16'hNEW_VALUE;
        //           reg_read_addr_1 = 3'd2;         // same as write dest
        //           #2;   // before clock edge
        //           $display("INFO [T%0d]: Read during write = 0x%h (document this)",
        //                    test_id, reg_read_data_1);
        //           test_id = test_id + 1;
        //           @(posedge clk); #1;
        //           reg_write_en = 1'b0;
        //           #2;
        //           check16(reg_read_data_1, 16'hNEW_VALUE, test_id); // after write
        //           test_id = test_id + 1;


        // ------------------------------------------------------------------
        // Summary
        // ------------------------------------------------------------------
        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule
