// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : DataMemory_tb.v
// Description : Testbench for the Data Memory module (Task 4).
//               Verifies synchronous write, gated combinational read,
//               write followed by immediate read, and disabled-write safety.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/dm_sim ../src/DataMemory.v DataMemory_tb.v
//   cd ../test && ../build/dm_sim
//   gtkwave ../waves/dm_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module DataMemory_tb;

    reg        clk;
    reg  [15:0] mem_access_addr;
    reg  [15:0] mem_write_data;
    reg        mem_write_en;
    reg        mem_read;
    wire [15:0] mem_read_data;

    integer i;
    integer fail_count;
    integer test_id;

    // Expected initial values (from test.data)
    reg [15:0] expected_init [0:7];

    // Values to write in Group 2
    reg [15:0] write_values [0:7];

    DataMemory uut (
        .clk             (clk),
        .mem_access_addr (mem_access_addr),
        .mem_write_data  (mem_write_data),
        .mem_write_en    (mem_write_en),
        .mem_read        (mem_read),
        .mem_read_data   (mem_read_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("../waves/dm_tb.vcd");
        $dumpvars(0, DataMemory_tb);
    end

    initial begin
        // Initialize arrays
        expected_init[0]=16'h0001; expected_init[1]=16'h0002;
        expected_init[2]=16'h0003; expected_init[3]=16'h0004;
        expected_init[4]=16'h0005; expected_init[5]=16'h0006;
        expected_init[6]=16'h0007; expected_init[7]=16'h0008;

        write_values[0]=16'hABCD; write_values[1]=16'hDABC;
        write_values[2]=16'hCDAB; write_values[3]=16'hBCDA;
        write_values[4]=16'hAABB; write_values[5]=16'hBAAB;
        write_values[6]=16'hBBAA; write_values[7]=16'hCCDD;

        fail_count = 0;
        test_id    = 1;

        mem_write_en = 0;
        mem_read     = 0;

        $display("=== DataMemory Testbench ===");

        // ==================================================
        // GROUP 1: Initial memory values
        // ==================================================
        $display("--- Group 1: Initial values ---");

        mem_read = 1;
        for (i = 0; i < 8; i = i + 1) begin
            mem_access_addr = i;
            #5;
            if (mem_read_data !== expected_init[i]) begin
                $display("FAIL [T%0d]: addr=%0d got=0x%h exp=0x%h",
                         test_id, i, mem_read_data, expected_init[i]);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d]: addr=%0d", test_id, i);
            end
            test_id = test_id + 1;
        end
        mem_read = 0;

        // ==================================================
        // GROUP 2: Write then read
        // ==================================================
        $display("--- Group 2: Write then read ---");

        for (i = 0; i < 8; i = i + 1) begin
            // Write
            mem_write_en    = 1;
            mem_access_addr = i;
            mem_write_data  = write_values[i];
            @(posedge clk);
            mem_write_en    = 0;

            // Read
            mem_read = 1;
            #5;
            if (mem_read_data !== write_values[i]) begin
                $display("FAIL [T%0d]: addr=%0d got=0x%h exp=0x%h",
                         test_id, i, mem_read_data, write_values[i]);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d]: addr=%0d", test_id, i);
            end
            test_id = test_id + 1;
            mem_read = 0;
        end

        // ==================================================
        // GROUP 3: mem_read disabled
        // ==================================================
        $display("--- Group 3: mem_read disabled ---");

        mem_read = 0;
        for (i = 0; i < 8; i = i + 1) begin
            mem_access_addr = i;
            #5;
            if (mem_read_data !== 16'd0) begin
                $display("FAIL [T%0d]: addr=%0d output=%h",
                         test_id, i, mem_read_data);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d]: addr=%0d", test_id, i);
            end
            test_id = test_id + 1;
        end

        // ==================================================
        // GROUP 4: Immediate read after write
        // ==================================================
        $display("--- Group 4: Immediate read ---");

        mem_write_en = 1;
        mem_access_addr = 3;
        mem_write_data  = 16'hABCD;
        @(posedge clk);
        mem_write_en = 0;

        mem_read = 1;
        #5;
        if (mem_read_data !== 16'hABCD) begin
            $display("FAIL [T%0d]", test_id);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS [T%0d]", test_id);
        end
        test_id = test_id + 1;
        mem_read = 0;

        // ==================================================
        // GROUP 5: Disabled write
        // ==================================================
        $display("--- Group 5: Disabled write ---");

        for (i = 0; i < 8; i = i + 1) begin
            // Valid write
            mem_write_en    = 1;
            mem_access_addr = i;
            mem_write_data  = write_values[i];
            @(posedge clk);
            mem_write_en    = 0;

            // Attempt overwrite (should NOT happen)
            mem_write_data  = ~write_values[i];
            @(posedge clk);

            // Read back
            mem_read = 1;
            #5;
            if (mem_read_data !== write_values[i]) begin
                $display("FAIL [T%0d]: addr=%0d got=0x%h exp=0x%h",
                         test_id, i, mem_read_data, write_values[i]);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [T%0d]: addr=%0d", test_id, i);
            end
            test_id = test_id + 1;
            mem_read = 0;
        end

        // ==================================================
        // SUMMARY
        // ==================================================
        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);

        $finish;
    end

endmodule