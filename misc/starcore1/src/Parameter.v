// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER:
//
// MEMBERS:
//   - Member 1 Name, Student Number
//   - Member 2 Name, Student Number

// File        : Parameter.v
// Description : Shared compile-time parameters used across all modules.
//               Include this file at the top of every .v file:
//                   `include "../src/Parameter.v"
// =============================================================================

`ifndef PARAMETER_H_
`define PARAMETER_H_

// ---------------------------------------------------------------------------
// Memory dimensions
// ---------------------------------------------------------------------------
`define COL     16          // Data/instruction word width (bits)
`define ROW_I   16          // Instruction memory depth (words, 16 x 16-bit)
`define ROW_D    8          // Data memory depth (words,  8 x 16-bit)

// ---------------------------------------------------------------------------
// Simulation control
// Increase SIM_TIME if your test program needs more clock cycles to complete.
// At 10 ns per clock (100 MHz) each #10 is one half-period; 320 ns = 16 cycles.
// ---------------------------------------------------------------------------
`define SIM_TIME  #640      // Total simulation time for integration testbench

// ---------------------------------------------------------------------------
// Output file for data-memory dump (used in DataMemory.v $fmonitor)
// ---------------------------------------------------------------------------
`define DMEM_LOG  "./waves/dmem_log.txt"

`endif  // PARAMETER_H_
