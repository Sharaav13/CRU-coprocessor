// =========================================================================
// Practical 4 Extension: StarCore-1 — CRU Co-processor Testbench
// =========================================================================
//
// GROUP NUMBER: 23
//
// MEMBERS:
//   - Member 1 Max Mendelow, MNDMAX003
//   - Member 2 Sharaav Dhebideen, DHBSHA001
//
// File        : CRU_tb.v
// Description : Testbench for the Coordinate Rotation Unit (CRU) co-processor.
//
//               Tests the CRU module in isolation by driving its interface
//               signals directly (no StarCore-1 integration required).
//
// Compile and simulate with:
//   iverilog -o cru_sim CRU_tb.v CRU.v codic.v && vvp cru_sim
//
// Expected output (Q1.15 fixed-point, 1.0 ≈ 32767 after saturation):
//
//   Angle (deg) | func  | Expected   | Result (approx)
//   ────────────┼───────┼────────────┼─────────────────
//      0        | COS   | +32767     | +32767  (saturated from 32770)
//      0        | SIN   |      0     | ~0
//     90        | COS   |      0     | ~0 (=-1)
//     90        | SIN   | +32767     | +32767  (saturated from 32772)
//     45        | COS   | +23170     | ~23171
//     45        | SIN   | +23170     | ~23170
//    180        | COS   | -32768     | -32768  (saturated from -32772)
//    180        | SIN   |      0     | ~0 (=+1)
//    270        | COS   |      0     | ~0 (=-1)
//    270        | SIN   | -32768     | -32768  (saturated from -32769)
//     30        | SIN   | +16384     | ~16380
//     60        | COS   | +16384     | ~16380
//
// Saturation note:
//   The CORDIC accumulates a gain K ≈ 1.6468 across 16 stages. At cardinal
//   angles (0°, 90°, 180°, 270°) the raw 17-bit output slightly exceeds the
//   16-bit signed range (e.g., +32770 or -32772). The CRU saturates these to
//   ±32767 / -32768, preserving the correct sign in all cases.
//
// Q1.15 format reminder:
//   value = result_signed / 32768.0  →  e.g. 23171/32768 ≈ 0.7070 ≈ cos(45°)
// =============================================================================

`timescale 1ns / 1ps

module CRU_tb;

    // =========================================================================
    // DUT SIGNALS
    // =========================================================================

    reg        clk;
    reg        rst;
    reg        cru_en;
    reg [15:0] angle_in;
    reg [ 2:0] func_sel;

    wire [15:0] cru_result;
    wire        done;
    wire        busy;

    // =========================================================================
    // DUT INSTANTIATION
    // =========================================================================

    CRU dut (
        .clk        (clk),
        .rst        (rst),
        .cru_en     (cru_en),
        .angle_in   (angle_in),
        .func_sel   (func_sel),
        .cru_result (cru_result),
        .done       (done),
        .busy       (busy)
    );

    // =========================================================================
    // CLOCK GENERATION — 10 ns period (100 MHz)
    // =========================================================================

    initial clk = 1'b0;
    always  #5 clk = ~clk;

    // =========================================================================
    // BOOKKEEPING
    // =========================================================================

    integer pass_count;
    integer fail_count;

    // Tolerance for CORDIC approximation error (in LSB).
    // 16-stage CORDIC is accurate to < 2^-14 ≈ 6 × 10^-5 of full scale.
    // Full scale = 32764, so worst-case error ≈ 32764 × 6e-5 ≈ 2 LSB.
    // We allow 16 LSB to be conservative.
    localparam TOLERANCE = 16;

    // =========================================================================
    // HELPER TASK: drive_cru
    //   Presents inputs to the CRU for one cycle, then waits for `done`.
    //   Prints a PASS/FAIL verdict based on the expected value ± TOLERANCE.
    //
    //   Parameters:
    //     test_name  : string label printed in the log
    //     angle      : 16-bit Q1.15 unsigned angle (0x0000=0°, 0x4000=90°…)
    //     func       : 3'b000 = cosine, 3'b001 = sine
    //     expected   : expected 16-bit signed result in Q1.15
    // =========================================================================

    task drive_cru;
        input [127:0] test_name; // 128-bit wide to fit 16 ASCII chars
        input [ 15:0] angle;
        input [  2:0] func;
        input signed [15:0] expected;

        integer result_signed;
        integer diff;
        begin
            // ------------------------------------------------------------------
            // Assert cru_en for exactly one clock cycle so the CRU latches
            // the inputs correctly (matches the behaviour of ControlUnit which
            // asserts cru_en for the single cycle the CRU instruction is fetched)
            // ------------------------------------------------------------------
            @(negedge clk);          // change inputs on falling edge (setup time)
            angle_in = angle;
            func_sel = func;
            cru_en   = 1'b1;

            @(negedge clk);          // hold for one full clock period
            cru_en   = 1'b0;

            // ------------------------------------------------------------------
            // Wait for the CRU to finish (done pulses for 1 cycle)
            // ------------------------------------------------------------------
            @(posedge done);
            @(negedge clk);          // sample result safely after done rises

            // ------------------------------------------------------------------
            // Check result
            // ------------------------------------------------------------------
            result_signed = $signed(cru_result);
            diff          = result_signed - $signed(expected);
            if (diff < 0) diff = -diff;  // absolute value

            if (diff <= TOLERANCE) begin
                $display("  [PASS] %-20s  angle=0x%04h func=%b  result=%6d  expected=%6d  err=%3d",
                         test_name, angle, func, result_signed, $signed(expected), diff);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] %-20s  angle=0x%04h func=%b  result=%6d  expected=%6d  err=%3d  <-- EXCEEDED TOLERANCE (%0d)",
                         test_name, angle, func, result_signed, $signed(expected), diff, TOLERANCE);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================================
    // STIMULUS
    // =========================================================================

    initial begin
        // --- Initialise signals -----------------------------------------------
        rst      = 1'b1;
        cru_en   = 1'b0;
        angle_in = 16'd0;
        func_sel = 3'b000;
        pass_count = 0;
        fail_count = 0;

        // --- Assert reset for 3 cycles ----------------------------------------
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        $display("");
        $display("=========================================================");
        $display(" CRU Testbench — Coordinate Rotation Unit (CORDIC-based) ");
        $display("=========================================================");
        $display(" Clock      : 100 MHz (10 ns period)");
        $display(" Precision  : Q1.15 fixed-point signed");
        $display(" Full-scale : 32767 LSB = 1.0 (saturated from raw CORDIC gain)");
        $display(" Tolerance  : ±%0d LSB", TOLERANCE);
        $display("---------------------------------------------------------");

        // ======================================================================
        // SECTION 1 — Cardinal angles
        //
        // At 0°, 90°, 180°, 270° the raw 17-bit CORDIC output slightly overflows
        // 16-bit signed range.  The CRU saturates to ±32767 / -32768.
        // Expected values derived from the raw probe data:
        //   0°  : Xout=32770 → saturate(+) = +32767,  Yout=0
        //   90° : Xout=-1≈0,                           Yout=32772 → +32767
        //  180° : Xout=-32772 → saturate(-) = -32768,  Yout=1≈0
        //  270° : Xout=-1≈0,                           Yout=-32769 → -32768
        // ======================================================================

        $display("");
        $display("--- Section 1: Cardinal angles ---");

        // cos(0°) = 1.0  → 32767 (saturated)
        drive_cru("cos(  0 deg)", 16'h0000, 3'b000, 16'sh7FFF);

        // sin(0°) = 0
        drive_cru("sin(  0 deg)", 16'h0000, 3'b001, 16'd0);

        // cos(90°) ≈ 0 (raw Xout = -1)
        drive_cru("cos( 90 deg)", 16'h4000, 3'b000, 16'd0);

        // sin(90°) = 1.0 → 32767 (saturated from 32772)
        drive_cru("sin( 90 deg)", 16'h4000, 3'b001, 16'sh7FFF);

        // cos(180°) = -1.0 → -32768 (saturated from -32772)
        drive_cru("cos(180 deg)", 16'h8000, 3'b000, 16'sh8000);

        // sin(180°) ≈ 0 (raw Yout = +1)
        drive_cru("sin(180 deg)", 16'h8000, 3'b001, 16'd0);

        // cos(270°) ≈ 0 (raw Xout = -1)
        drive_cru("cos(270 deg)", 16'hC000, 3'b000, 16'd0);

        // sin(270°) = -1.0 → -32768 (saturated from -32769)
        drive_cru("sin(270 deg)", 16'hC000, 3'b001, 16'sh8000);

        // ======================================================================
        // SECTION 2 — Diagonal angles
        // cos(45°) = sin(45°) = √2/2 ≈ 0.70711 → 23170
        // angle_in for 45°: 0x4000 × (45/90) = 0x2000
        // ======================================================================

        $display("");
        $display("--- Section 2: Diagonal angles (45°, 135°, 225°, 315°) ---");

        // 45°  : 0x2000
        drive_cru("cos( 45 deg)", 16'h2000, 3'b000, 16'd23170);
        drive_cru("sin( 45 deg)", 16'h2000, 3'b001, 16'd23170);

        // 135° : 0x6000  → cos=-0.70711→-23170, sin=+0.70711→+23170
        drive_cru("cos(135 deg)", 16'h6000, 3'b000, -16'd23170);
        drive_cru("sin(135 deg)", 16'h6000, 3'b001,  16'd23170);

        // 225° : 0xA000  → cos=-0.70711, sin=-0.70711
        drive_cru("cos(225 deg)", 16'hA000, 3'b000, -16'd23170);
        drive_cru("sin(225 deg)", 16'hA000, 3'b001, -16'd23170);

        // 315° : 0xE000  → cos=+0.70711, sin=-0.70711
        drive_cru("cos(315 deg)", 16'hE000, 3'b000,  16'd23170);
        drive_cru("sin(315 deg)", 16'hE000, 3'b001, -16'd23170);

        // ======================================================================
        // SECTION 3 — 30° and 60° (satellite attitude relevant angles)
        // sin(30°) = cos(60°) = 0.5      → 16384
        // cos(30°) = sin(60°) = √3/2≈0.866 → 28378
        // angle_in for 30°: (30/360) × 0x10000 = 0x1555
        // angle_in for 60°: (60/360) × 0x10000 = 0x2AAB
        // ======================================================================

        $display("");
        $display("--- Section 3: 30° and 60° (attitude determination angles) ---");

        // 30°
        drive_cru("cos( 30 deg)", 16'h1555, 3'b000, 16'd28378);
        drive_cru("sin( 30 deg)", 16'h1555, 3'b001, 16'd16384);

        // 60°
        drive_cru("cos( 60 deg)", 16'h2AAB, 3'b000, 16'd16384);
        drive_cru("sin( 60 deg)", 16'h2AAB, 3'b001, 16'd28378);

        // ======================================================================
        // SECTION 4 — Handshake protocol verification
        // Verify that busy stays high during computation and that cru_en
        // while busy is correctly ignored (no spurious restart).
        // ======================================================================

        $display("");
        $display("--- Section 4: Handshake protocol ---");

        begin : handshake_test
            integer cycle_count_busy;
            integer was_busy;

            @(negedge clk);
            angle_in = 16'h2000; // 45°
            func_sel = 3'b000;   // cosine
            cru_en   = 1'b1;
            @(negedge clk);
            cru_en = 1'b0;

            // Count how many cycles busy stays high
            cycle_count_busy = 0;
            was_busy         = 0;

            fork
                begin : count_busy
                    forever begin
                        @(posedge clk);
                        if (busy) begin
                            cycle_count_busy = cycle_count_busy + 1;
                            was_busy = 1;
                        end else if (was_busy) begin
                            disable count_busy;
                        end
                    end
                end
                begin : wait_done
                    @(posedge done);
                    disable count_busy;
                end
            join

            // Pipeline is 16 stages deep; CRU busy for exactly 17 cycles
            // (1 latch + 16 pipeline stages before stage_cnt reaches PIPE_DEPTH)
            if (cycle_count_busy == 17) begin
                $display("  [PASS] busy_duration            busy for %0d cycles (expected 17)", cycle_count_busy);
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] busy_duration            busy for %0d cycles (expected 17)", cycle_count_busy);
                fail_count = fail_count + 1;
            end

            @(negedge clk);

            // Verify that a second cru_en while busy is safely ignored
            // (drive cru_en immediately after a fresh computation starts)
            angle_in = 16'h4000; // 90° — sin should be ~32764
            func_sel = 3'b001;
            cru_en   = 1'b1;
            @(negedge clk);

            // Now pulse cru_en again while busy — should have no effect
            angle_in = 16'h0000; // 0° — if picked up, cos would be ~32764, sin ~0
            cru_en   = 1'b1;     // spurious cru_en while busy
            @(negedge clk);
            cru_en   = 1'b0;

            // Wait for result
            @(posedge done);
            @(negedge clk);

            // Result should still be sin(90°) ≈ 32767 (saturated), NOT sin(0°) = 0
            begin : spurious_check
                integer res;
                integer err;
                res = $signed(cru_result);
                err = res - 32767;
                if (err < 0) err = -err;
                if (err <= TOLERANCE) begin
                    $display("  [PASS] spurious_en_ignored      result=%6d (correct sin(90°)≈32767, not corrupted by spurious cru_en)", res);
                    pass_count = pass_count + 1;
                end else begin
                    $display("  [FAIL] spurious_en_ignored      result=%6d (expected ~32767 for sin(90°)); spurious cru_en may have overwritten latch", res);
                    fail_count = fail_count + 1;
                end
            end
        end

        // ======================================================================
        // SECTION 5 — Reset mid-computation
        // Assert rst while busy and verify the CRU recovers cleanly.
        // ======================================================================

        $display("");
        $display("--- Section 5: Reset recovery ---");

        begin : reset_test
            @(negedge clk);
            angle_in = 16'h4000; // 90°
            func_sel = 3'b000;   // cosine
            cru_en   = 1'b1;
            @(negedge clk);
            cru_en   = 1'b0;

            // Wait a few cycles into computation then assert rst
            repeat (5) @(posedge clk);
            @(negedge clk);
            rst = 1'b1;
            @(negedge clk);
            rst = 1'b0;

            // busy should now be deasserted
            @(posedge clk);
            if (!busy && !done) begin
                $display("  [PASS] rst_clears_busy          busy=0, done=0 one cycle after rst");
                pass_count = pass_count + 1;
            end else begin
                $display("  [FAIL] rst_clears_busy          busy=%b, done=%b (both should be 0 after rst)", busy, done);
                fail_count = fail_count + 1;
            end

            // After reset, a fresh computation should work correctly
            repeat (2) @(posedge clk);
            @(negedge clk);
            angle_in = 16'h0000; // 0°
            func_sel = 3'b000;   // cosine → expect ~32764
            cru_en   = 1'b1;
            @(negedge clk);
            cru_en   = 1'b0;

            @(posedge done);
            @(negedge clk);
            begin : post_reset_check
                integer res;
                integer err;
                res = $signed(cru_result);
                err = res - 32767;
                if (err < 0) err = -err;
                if (err <= TOLERANCE) begin
                    $display("  [PASS] post_rst_computation     cos(0°)=%6d (correct, ≈+32767)", res);
                    pass_count = pass_count + 1;
                end else begin
                    $display("  [FAIL] post_rst_computation     cos(0°)=%6d (expected ~32767)", res);
                    fail_count = fail_count + 1;
                end
            end
        end

        // ======================================================================
        // SUMMARY
        // ======================================================================

        $display("");
        $display("=========================================================");
        $display(" Results: %0d PASSED  /  %0d FAILED  /  %0d TOTAL",
                 pass_count, fail_count, pass_count + fail_count);
        $display("=========================================================");
        $display("");

        if (fail_count == 0)
            $display(" ALL TESTS PASSED — CRU functional verification complete.");
        else
            $display(" SOME TESTS FAILED — review CORDIC integration and pipeline timing.");

        $display("");
        #20;
        $finish;
    end

    // =========================================================================
    // WATCHDOG — abort simulation if it hangs (e.g. done never arrives)
    // =========================================================================

    initial begin
        #200000;
        $display("[WATCHDOG] Simulation exceeded maximum time — possible hang in CRU FSM.");
        $finish;
    end

    // =========================================================================
    // OPTIONAL WAVEFORM DUMP (uncomment for GTKWave inspection)
    // =========================================================================
    //
    // initial begin
    //     $dumpfile("cru_wave.vcd");
    //     $dumpvars(0, CRU_tb);
    // end

endmodule
