# CORDIC Co-Processor for StarCore-1
**EEE4120F HPES Project — Group 23**  
Max Mendelow (MNDMAX003) · Sharaav Dhebideen (DHBSHA001)  
University of Cape Town, 2026

---

## Overview

This repository contains the complete design and verification files for a
CORDIC-based **Coordinate Rotation Unit (CRU)** implemented as a hardware
coprocessor for the **StarCore-1** single-cycle 16-bit processor.

The CRU accelerates sine and cosine computation using only shift-and-add
operations — no hardware multipliers required. It is activated by StarCore-1
when it decodes the reserved opcode `1010`, offloading trigonometric work
that would otherwise require large look-up tables or expensive software loops.

---

## Repository Structure

```
.
├── src/                        # StarCore-1 processor source files
│   ├── ALU.v                   # 16-bit Arithmetic & Logic Unit
│   ├── ALU_Control.v           # ALU control decoder (6-bit casex)
│   ├── ControlUnit.v           # Main control unit (opcode → signals)
│   ├── DataMemory.v            # 8×16-bit synchronous RAM
│   ├── Datapath.v              # Full processor datapath (integrates all above)
│   ├── GPR.v                   # General Purpose Register File (8×16-bit)
│   ├── InstructionMemory.v     # 16×16-bit ROM, loaded from test.prog
│   ├── StarCore1.v             # Top-level: wires Datapath ↔ ControlUnit
│   └── Parameter.v             # Shared compile-time parameters (`define macros)
│
├── coprocessor/                # CRU coprocessor files
│   ├── CRU.v                   # Coordinate Rotation Unit (16-stage CORDIC pipeline)
│   └── CRU_tb.v                # CRU testbench — simulates StarCore-1 interface
│
├── reference/                  # Original reference CORDIC (not synthesised)
│   ├── codic.v                 # 32-bit, 31-stage CORDIC (Verilog reference)
│   └── cordic_tb.v             # Reference CORDIC testbench
│
├── test/                       # Test vectors
│   ├── test.prog               # StarCore-1 instruction memory (binary, one word/line)
│   └── test.data               # StarCore-1 data memory   (binary, one word/line)
│
├── matlab/
│   └── gold_standard.m         # IEEE 754 gold standard: cos/sin × 32000, timed
│
└── README.md                   # This file
```

---

## CRU Design Summary

| Parameter          | Value                                  |
|--------------------|----------------------------------------|
| Architecture       | Fully-pipelined CORDIC (rotation mode) |
| Pipeline stages    | 16                                     |
| Data width         | 16-bit signed fixed-point              |
| Angle encoding     | Q2.14 — `angle = floor(θ/360 × 2^16)` |
| Input pre-scaling  | Xin = 19 431 (= 32 000 / 1.6468)      |
| Output range       | ±32 000 LSB                            |
| Clock frequency    | 100 MHz (10 ns period)                 |
| Latency            | 16 clock cycles = 160 ns               |
| Throughput         | 1 result/cycle (pipelined)             |
| Average max error  | 0.031 % vs IEEE 754 gold standard      |
| Average speedup    | ~3 × over MATLAB double-precision      |

### Key Design Decisions

- **16-bit arctangent LUT** — Entries for stages 14–15 truncate to zero,
  effectively limiting the active pipeline to 14 stages. This is the dominant
  source of output error (~0.05 % worst case).
- **Quadrant pre-rotation** — The two MSBs of the angle word determine which
  quadrant the input lies in. Inputs in Q2/Q3 are pre-rotated by ±90°, keeping
  the CORDIC iteration within its convergence range of (−π/2, π/2).
- **CORDIC gain correction** — The cumulative gain K ≈ 1.6468 is absorbed by
  pre-scaling Xin before the pipeline rather than applying a post-multiplier.
- **`valid_pipe` shift register** — A 16-bit shift register tracks the job
  through the pipeline. The MSB drives the `done` output, giving a
  deterministic handshake to StarCore-1.

---

## Coprocessor Interface (StarCore-1 ↔ CRU)

```
StarCore-1                        CRU
──────────────────────────────────────────────────
Decodes opcode 1010    ──enable──▶  Accepts job
Writes angle to RS1    ──angle──▶   Q2.14 input
                       ──Xin──▶    Pre-scaled = 19431
                       ──Yin──▶    Always 0 (cos/sin only)
Stalls pipeline        ◀──done────  Asserts after 16 cycles
Reads result           ◀──Xout────  32000 × cos(θ)
                       ◀──Yout────  32000 × sin(θ)
```

---

## Simulation Instructions

### Requirements
- [EDA Playground](https://www.edaplayground.com) — Icarus Verilog 12.0,
  or a local Icarus Verilog installation (`iverilog` + `vvp`).

### Running the CRU testbench (EDA Playground)

1. Upload `CRU.v` as the design file and `CRU_tb.v` as the testbench.
2. Select **Icarus Verilog** as the simulator.
3. Click **Run**. Expected output:

```
Starting sim
CLK_100MHZ started
Setting Angle = 200 degrees, Hex = e38e
Waiting for CRU to process (done = 0)...
Processing Finished! (done = 1)
Outputs -> Xout (Cos): -30073, Yout (Sin): -10929

=============================================
        CRU EXECUTION TIME PROFILE
=============================================
Start Time     : 1130.00 ns
End Time       : 1290.00 ns
Total Run Time : 160.00 ns
Clock Cycles   : 16 cycles
=============================================
```

The message `$stop called at ...` at the end is **normal** — it indicates
successful simulation completion, not an error.

### Running locally

```bash
iverilog -o cru_sim coprocessor/CRU.v coprocessor/CRU_tb.v
vvp cru_sim
```

---

## Gold Standard (MATLAB)

`matlab/gold_standard.m` computes the IEEE 754 reference output for a single
angle and measures the average MATLAB execution time over 10⁵ runs (discarding
the first 5 warmup iterations).

```matlab
% Edit these two lines, then run the script:
angle_deg  = 45;
NUM_RUNS   = 105;
```

The script prints Xout, Yout, and a timing summary (average, min, max, std).

---

## Accuracy Results

| Angle  | GS Xout | CRU Xout | GS Yout | CRU Yout | Max % Error |
|--------|---------|----------|---------|----------|-------------|
| 24°    | 29234   | 29224    | 13016   | 13022    | 0.0296 %    |
| 155°   | −29002  | −28992   | 13524   | 13529    | 0.0308 %    |
| 200°   | −30070  | −30073   | −10945  | −10929   | 0.0489 %    |
| 346°   | 31050   | 31045    | −7742   | −7740    | 0.0140 %    |
| **Avg**|         |          |         |          | **0.031 %** |

---

## Known Limitations

- The 16-bit arctangent LUT truncates stages 14–15 to zero; the effective
  pipeline depth is therefore 14 stages.
- Angle encoding uses 16 bits (Q2.14), so the angular resolution is
  360°/65536 ≈ 0.0055°/LSB.
- The current testbench tests one angle per simulation run. Modify `i` in
  `CRU_tb.v` to test other angles (0–359 degrees).

---

## References

1. J. Volder, "The CORDIC Trigonometric Computing Technique," *IRE Transactions
   on Electronic Computers*, vol. EC-8, no. 3, pp. 330–334, 1959.
2. R. Andraka, "A survey of CORDIC algorithms for FPGAs," *Proc. ACM/SIGDA FPGA*,
   pp. 191–200, 1998.
3. EDA Playground — Online Verilog Simulator: https://www.edaplayground.com
4. Icarus Verilog: http://iverilog.icarus.com
5. IEEE Std 754-2019, *IEEE Standard for Floating-Point Arithmetic*, 2019.
