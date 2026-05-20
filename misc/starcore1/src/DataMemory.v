// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER: 23
//
// MEMBERS:
//   - Member 1 Max Mendelow, MNDMAX003
//   - Member 2 Sharaav Dhebideen, DHBSHA001

// File        : DataMemory.v
// Description : Data Memory (RAM).
//               8 words × 16 bits. Contents loaded at simulation start from
//               the binary file ./test/test.data using $readmemb.
//               Writes are synchronous (positive-edge clocked).
//               Reads are combinational and gated by the mem_read enable.
//
// Task 4 — Student Implementation Required
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module DataMemory (
    input        clk,

    // Shared address bus (used for both reads and writes)
    input  [15:0] mem_access_addr,  // Byte address; only lower bits used for indexing

    // Write port
    input  [15:0] mem_write_data,   // Data to store
    input        mem_write_en,      // Assert to write on the next posedge clk

    // Read port
    input        mem_read,          // Assert to enable the read output
    output [15:0] mem_read_data     // Read result; 16'd0 when mem_read is de-asserted
);

    // -------------------------------------------------------------------------
    // TODO: Declare the data memory array.
    //       It should hold `ROW_D entries, each `COL bits wide.
    //
        reg [`COL-1:0] memory [`ROW_D-1:0]; 
        // "`" is used for macros shared across all files
    // -------------------------------------------------------------------------


    // -------------------------------------------------------------------------
    // TODO: Derive the word address from mem_access_addr.
    //       The data memory is 8 words deep so only 3 address bits are needed.
    //       The ALU computes a byte address; use the lower 3 bits as the index:
    //
        wire [2:0] ram_addr;
        assign ram_addr = mem_access_addr[2:0];
        // A word refers to the data being used/carried, hence this can be of any bit length 
    //
    //       This maps byte addresses 0,1,2,3,4,5,6,7 to words 0–7.
    //       (In a full system the byte offset within a word would also be
    //       handled, but StarCore-1 only supports 16-bit aligned accesses.)
    // -------------------------------------------------------------------------


    // -------------------------------------------------------------------------
    // TODO: Load the data memory from file at simulation start.
    //       The file ./test/test.data must contain one 16-bit binary value
    //       per line (8 lines total, one per word).
    //
       integer log_fd;
       initial begin
           $readmemb("../test/test.data", memory);
       end
       // "initial begin" is used for a block of code that should run once upon simulation start
    //
    //       Optional — add a $fmonitor to log memory contents to a file.
    //       This is useful for verifying ST instructions during simulation:
    //
    //   initial begin
    //       log_fd = $fopen(`DMEM_LOG);
    //       $fmonitor(log_fd, "t=%0t  [0]=%h [1]=%h [2]=%h [3]=%h",
    //                 $time, memory[0], memory[1], memory[2], memory[3]);
    //       `SIM_TIME;
    //       $fclose(log_fd);
    //   end
       // "log_fd" stores a number or ticket to access the actual file 
       // "$fopen()" only sends the ticket number
       // "$fmonitor" writes to the file
       // `define DMEM_LOG  "./waves/dmem_log.txt" stores the path of the log file as a macro
       // `define SIM_TIME  #640   states the length of the delay to account for simulation time
    // -------------------------------------------------------------------------


    // -------------------------------------------------------------------------
    // TODO: Implement the synchronous write port.
    //       Write mem_write_data to memory[ram_addr] on the rising clock edge
    //       when mem_write_en is asserted.
    //
       always @(posedge clk) begin
           if (mem_write_en)
               memory[ram_addr] <= mem_write_data;
       end
       // On the positive clock edge assign the value contained 
       // in "mem_write_data" to the memory address "ram_addr" 
       // if memory writing is enabled
    //
    //       IMPORTANT: Use non-blocking assignment (<=).
    // -------------------------------------------------------------------------


    // -------------------------------------------------------------------------
    // TODO: Implement the combinational (gated) read port.
    //       When mem_read is 1, output memory[ram_addr].
    //       When mem_read is 0, output 16'd0 (prevents spurious register writes
    //       during non-LD instructions).
    //
       assign mem_read_data = mem_read ? memory[ram_addr] : 16'd0;
       // "mem_read ?" => check the state/value of mem_read
       // "memory[ram_addr] : 16'd0" => value to assign if true : value to assign if false
    // -------------------------------------------------------------------------
endmodule
