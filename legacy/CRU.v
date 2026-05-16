// =========================================================================
// Practical 4 Extension: StarCore-1 — CRU Co-processor
// =========================================================================
//
// GROUP NUMBER: 23
//
// MEMBERS:
//   - Member 1 Max Mendelow, MNDMAX003
//   - Member 2 Sharaav Dhebideen, DHBSHA001
//
// File        : CRU.v
// Description : Coordinate Rotation Unit (CRU) — CORDIC-based co-processor
//               for the StarCore-1 processor.
//
//               The CRU accelerates trigonometric computation (sin/cos) using
//               the CORDIC (COordinate Rotation DIgital Computer) algorithm,
//               enabling satellite attitude determination without large LUTs.
//
//               It is triggered by opcode 1010 in the StarCore ISA (currently
//               reserved). Because CORDIC requires 16 pipeline stages, the CRU
//               is a multi-cycle co-processor: it asserts `busy` for 16 clock
//               cycles and pulses `done` for one cycle when the result is ready.
//               StarCore-1 must stall its PC and suppress register writes while
//               `busy` is asserted (see integration notes below).
//
// CRU Instruction Format (uses R-type encoding, opcode = 4'b1010):
//
//   Bits [15:12] = 1010          — CRU opcode
//   Bits [11: 9] = RS1           — Source register: angle in Q1.15 fixed-point
//   Bits [ 8: 6] = WS            — Destination register for write-back
//   Bits [ 5: 3] = func_sel      — 3'b000 = cosine, 3'b001 = sine
//   Bits [ 2: 0] = (unused)
//
// Angle encoding (Q1.15 fixed-point, unsigned, full 360° circle):
//
//   0x0000 =   0°      0x2000 =  45°
//   0x4000 =  90°      0x6000 = 135°
//   0x8000 = 180°      0xC000 = 270°
//
// Result encoding (Q1.15 signed, two's complement):
//
//   0x7FFF ≈ +1.0      0x0000 = 0.0      0x8001 ≈ -1.0
//
// Integration with StarCore-1:
//   1. ControlUnit asserts `cru_en` when opcode == 4'b1010.
//   2. Datapath drives `angle_in` from reg_read_data_1 (RS1) and
//      `func_sel` from instr[5:3].
//   3. While `busy` is high, the Datapath must freeze the PC
//      (hold pc_current) and suppress reg_write.
//   4. When `done` pulses high, the Datapath writes `cru_result`
//      to the register file at address WS (instr[8:6]).
//
// CORDIC core: instantiates `sine_cosine` from codic.v
//   Pipeline depth : 16 stages (STG = c_parameter = 16)
//   Total latency  : 17 clock cycles (1 latch + 16 pipeline stages)
//   CORDIC gain K  : ≈1.6468
//   Xin constant   : 19898 = round(32768 / 1.6468)
//   Output range   : ≈ ±32764 (fits within signed 16-bit)
//
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module CRU (
    input        clk,           // System clock (shared with StarCore-1)
    input        rst,           // Synchronous active-high reset

    // --- StarCore-1 interface ------------------------------------------------
    input        cru_en,        // Asserted for ONE cycle by ControlUnit
                                // when opcode == 4'b1010 and processor is not stalled
    input [15:0] angle_in,      // Angle from RS1 register (Q1.15, unsigned)
    input [ 2:0] func_sel,      // 3'b000 = cosine output, 3'b001 = sine output

    // --- Result interface ----------------------------------------------------
    output reg [15:0] cru_result, // Q1.15 signed result; stable while !busy
    output reg        done,        // Pulses HIGH for exactly one clock cycle
                                   // when cru_result is valid
    output reg        busy         // HIGH while the CORDIC pipeline is running;
                                   // StarCore-1 must stall (freeze PC, no reg writes)
);

    // =========================================================================
    // CORDIC PIPELINE PARAMETERS
    // =========================================================================

    // Pipeline depth equals the bit-width parameter of sine_cosine (STG = 16)
    localparam PIPE_DEPTH = 16;

    // Xin constant: 1/K_cordic × 2^15 = 19898 (normalises output to Q1.15)
    // With Xin=19898 and Yin=0:  Xout ≈ 32764×cos(θ),  Yout ≈ 32764×sin(θ)
    localparam signed [15:0] CORDIC_X_INIT = 16'd19898;

    // =========================================================================
    // INTERNAL SIGNALS
    // =========================================================================

    // Latched angle scaled from 16-bit Q1.15 to 32-bit CORDIC format.
    // Scaling: {angle_in, 16'b0} maps 0x0000→0°, 0x4000→90°, 0x8000→180°
    reg  [31:0] angle_latched;

    // CORDIC engine outputs (17-bit signed: one guard bit beyond Q1.15)
    wire signed [16:0] cordic_xout; // cos component × Xin × K
    wire signed [16:0] cordic_yout; // sin component × Xin × K

    // Pipeline stage counter (needs to count to PIPE_DEPTH = 16)
    reg [4:0] stage_cnt;

    // Latched function select — captured at start so it stays stable
    reg [2:0] func_latched;

    // =========================================================================
    // CORDIC ENGINE INSTANTIATION
    // Instantiates sine_cosine from codic.v.
    // Yin is tied to 0 so the CORDIC rotates the unit vector (Xin, 0) by angle,
    // producing (Xin·K·cos θ, Xin·K·sin θ) = (≈32764·cos θ, ≈32764·sin θ).
    // =========================================================================

    sine_cosine #(
        .c_parameter (PIPE_DEPTH)   // 16-bit precision; sets pipeline depth to 16
    ) cordic_core (
        .clock (clk),
        .angle (angle_latched),     // 32-bit angle; sampled every posedge
        .Xin   (CORDIC_X_INIT),     // Constant: 1/K × 2^15 ≈ 19898
        .Yin   (16'd0),             // Yin = 0 for standard sin/cos computation
        .Xout  (cordic_xout),       // 17-bit: cosine result (with guard bit)
        .Yout  (cordic_yout)        // 17-bit: sine   result (with guard bit)
    );

    // =========================================================================
    // SATURATION FUNCTION
    //
    // The CORDIC gain K ≈ 1.6468 accumulates across 16 stages and can cause
    // the 17-bit pipeline output to slightly exceed the 16-bit signed range
    // (e.g., Xout = 32770 at 0°, Yout = 32772 at 90°).  Naively taking
    // [15:0] would flip the sign bit, producing a grossly wrong result.
    //
    // Saturation clamps the 17-bit signed value to [-32768, +32767] before
    // truncating to 16 bits, preserving the correct sign in all cases.
    // =========================================================================

    function signed [15:0] saturate17to16;
        input signed [16:0] val;
        begin
            if      (val > 17'sd32767)   saturate17to16 = 16'sh7FFF; // +32767
            else if (val < -17'sd32768)  saturate17to16 = 16'sh8000; // -32768
            else                         saturate17to16 = val[15:0];
        end
    endfunction

    // =========================================================================
    // CRU CONTROL FSM
    //
    // States (encoded in {busy, stage_cnt}):
    //   IDLE   : busy=0, stage_cnt=0  — waiting for cru_en
    //   RUNNING: busy=1, stage_cnt∈[0,PIPE_DEPTH-1] — pipeline filling
    //   CAPTURE: busy=0, stage_cnt==PIPE_DEPTH — result captured, done pulsed
    //            (returns to IDLE on next cycle)
    //
    // Timeline from cru_en pulse to done:
    //   Cycle 0 : cru_en detected; angle_latched and func_latched set;
    //             busy <= 1, stage_cnt <= 0
    //   Cycle 1 : CORDIC stage-0 register samples angle_latched
    //   Cycle 2 : Generate stage 0 computes X[1]
    //   ...
    //   Cycle 16: Generate stage 14 computes X[15] (= cordic_xout)
    //   Cycle 17: stage_cnt == PIPE_DEPTH; result captured; done pulsed for 1 cycle
    // =========================================================================

    always @(posedge clk) begin
        if (rst) begin
            busy         <= 1'b0;
            done         <= 1'b0;
            stage_cnt    <= 5'd0;
            cru_result   <= 16'd0;
            angle_latched<= 32'd0;
            func_latched <= 3'b000;
        end else begin
            // Default: done is a single-cycle pulse; clear it every cycle
            done <= 1'b0;

            if (!busy && cru_en) begin
                // -----------------------------------------------------------
                // IDLE → RUNNING
                // Latch inputs and start the CORDIC pipeline.
                // Scale angle from Q1.15 (16-bit) to the 32-bit CORDIC format
                // by zero-extending into the lower 16 bits.
                // -----------------------------------------------------------
                angle_latched <= {angle_in, 16'b0};
                func_latched  <= func_sel;
                busy          <= 1'b1;
                stage_cnt     <= 5'd0;

            end else if (busy) begin
                // -----------------------------------------------------------
                // RUNNING — advance the stage counter each clock
                // -----------------------------------------------------------
                if (stage_cnt == PIPE_DEPTH[4:0]) begin
                    // -------------------------------------------------------
                    // CAPTURE — CORDIC pipeline result is now stable.
                    // cordic_xout = Xin·K·cos(θ) ≈ 32764·cos(θ)  [Q1.15]
                    // cordic_yout = Xin·K·sin(θ) ≈ 32764·sin(θ)  [Q1.15]
                    // Select lower 16 bits (drop guard bit [16]).
                    // -------------------------------------------------------
                    busy      <= 1'b0;
                    done      <= 1'b1;     // 1-cycle pulse
                    stage_cnt <= 5'd0;

                    if (func_latched == 3'b001)
                        cru_result <= saturate17to16(cordic_yout); // sine
                    else
                        cru_result <= saturate17to16(cordic_xout); // cosine (default)

                end else begin
                    stage_cnt <= stage_cnt + 5'd1;
                end
            end
        end
    end

endmodule
