// =========================================================================
// Practical 4: StarCore-1 — Single-Cycle Processor in Verilog
// =========================================================================
//
// GROUP NUMBER: 23
//
// MEMBERS:
//   - Member 1 Max Mendelow, MNDMAX003
//   - Member 2 Sharaav Dhebideen, DHBSHA001

// File        : Datapath.v
// Description : StarCore-1 Datapath.
//               Integrates all sub-components (Tasks 1–6) and implements the
//               full data-flow of the processor. Control signals arrive from
//               an external ControlUnit module (instantiated in StarCore1.v).
//               The opcode of the current instruction is exposed as an output
//               so the ControlUnit can decode it.
//
//               Internal structure (in order of data flow):
//               1.  Program Counter (PC) register
//               2.  PC+2 adder
//               3.  Instruction Memory (ROM)
//               4.  Register-file write-address multiplexer (RegDst)
//               5.  General Purpose Register File (GPR)
//               6.  Immediate sign-extension
//               7.  ALUSrc multiplexer
//               8.  ALU Control Unit
//               9.  ALU
//               10. Branch address adder + branch/sequential mux
//               11. Jump address computation + jump mux
//               12. Data Memory (RAM)
//               13. Write-back multiplexer (MemToReg)
//
// Task 7 — Student Implementation Required
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module Datapath (
    input        clk,

    // --- Control signals from ControlUnit ------------------------------------
    input        jump,          // Select jump target PC
    input        beq,           // Enable branch-on-equal
    input        bne,           // Enable branch-on-not-equal
    input        mem_read,      // Enable data memory read
    input        mem_write,     // Enable data memory write (posedge clk)
    input        alu_src,       // 0 = RS2; 1 = sign-extended immediate
    input        reg_dst,       // 0 = instr[8:6] (I-type); 1 = instr[5:3] (R-type)
    input        mem_to_reg,    // 0 = ALU result; 1 = memory read data
    input        reg_write,     // Enable register file write (posedge clk)
    input  [1:0] alu_op,        // ALU operation class for ALU_Control

    // --- Output to ControlUnit -----------------------------------------------
    output [3:0] opcode         // Instruction opcode field [15:12]
);

    // =========================================================================
    // INTERNAL SIGNAL DECLARATIONS
    // All internal signals that interconnect sub-components go here.
    // =========================================================================

    // --- Program Counter ------------------------------------------------------
    reg  [15:0] pc_current;             // Current PC value (register)
    wire [15:0] pc_next;                // Next PC value (combinational)
    wire [15:0] pc2;                    // PC + 2 (sequential next address)

    // --- Instruction fetch ----------------------------------------------------
    wire [15:0] instr;                  // Fetched instruction word

    // --- Register file --------------------------------------------------------
    wire [2:0]  reg_write_dest;         // Write-back register address (after RegDst mux)
    wire [15:0] reg_write_data;         // Write-back data (after MemToReg mux)
    wire [2:0]  reg_read_addr_1;        // RS1 address (from instr[11:9])
    wire [2:0]  reg_read_addr_2;        // RS2 address (from instr[8:6])
    wire [15:0] reg_read_data_1;        // Data from RS1
    wire [15:0] reg_read_data_2;        // Data from RS2

    // --- Immediate extension --------------------------------------------------
    wire [15:0] ext_im;                 // Sign-extended 6-bit immediate

    // --- ALU ------------------------------------------------------------------
    wire [15:0] alu_operand_b;          // ALUSrc mux output (RS2 or immediate)
    wire [2:0]  alu_control;            // ALU function select from ALU_Control
    wire [15:0] alu_result;             // ALU computed result
    wire        zero_flag;              // ALU zero output

    // --- Branch / Jump PC computation ----------------------------------------
    wire [15:0] pc_branch;              // Branch target address
    wire        beq_taken;              // BEQ condition satisfied
    wire        bne_taken;              // BNE condition satisfied
    wire [15:0] pc_after_branch;        // PC selected after branch evaluation
    wire [12:0] jump_target;            // Jump target (12 bits + appended 0)
    wire [15:0] pc_jump;                // Full 16-bit jump target address

    // --- Data memory ----------------------------------------------------------
    wire [15:0] mem_read_data;          // Data read from memory


    // =========================================================================
    // 1. PROGRAM COUNTER
    // =========================================================================

    // TODO: Initialise pc_current to 16'd0 in an initial block.
    //
           initial begin
               pc_current <= 16'd0;
           end
    //
    // TODO: Update pc_current to pc_next on every positive clock edge.
    //
           always @(posedge clk) begin
               pc_current <= pc_next;
           end
    //
    // TODO: Compute pc2 = pc_current + 16'd2 using a continuous assignment.
            assign pc2 = pc_current + 16'd2;

    // =========================================================================
    // 2. INSTRUCTION MEMORY
    // Instantiate InstructionMemory; connect pc_current and instr.
    // =========================================================================

    // TODO: Instantiate the InstructionMemory module using named port connections.
    //
           InstructionMemory im (
               // Connect the signal "(<...>)" in this module to the port ".<...>" in the instantiated module
               .pc          (pc_current),
               .instruction (instr)
           );
    //
    // TODO: Drive the opcode output from the fetched instruction:
           assign opcode = instr[15:12];


    // =========================================================================
    // 3. REGISTER FILE WRITE-ADDRESS MULTIPLEXER (RegDst)
    // =========================================================================

    // TODO: Select the write-back register address based on the RegDst control.
    //   RegDst = 0 -> I-type: write to WS encoded in instr[8:6]
    //   RegDst = 1 -> R-type: write to WS encoded in instr[5:3]
    //
           assign reg_write_dest = reg_dst ? instr[5:3] : instr[8:6];
    //
    // TODO: Assign the read addresses from the instruction fields:
           assign reg_read_addr_1 = instr[11:9];  // RS1
           assign reg_read_addr_2 = instr[8:6];   // RS2


    // =========================================================================
    // 4. GENERAL PURPOSE REGISTER FILE
    // =========================================================================

    // TODO: Instantiate the GPR module using named port connections.
    //
           GPR reg_file (
                // Connect the signal "(<...>)" in this module to the port ".<...>" in the instantiated module
               .clk              (clk),
               .reg_write_en     (reg_write), 
               .reg_write_dest   (reg_write_dest),
               .reg_write_data   (reg_write_data),
               .reg_read_addr_1  (reg_read_addr_1),
               .reg_read_data_1  (reg_read_data_1),
               .reg_read_addr_2  (reg_read_addr_2),
               .reg_read_data_2  (reg_read_data_2)
           );


    // =========================================================================
    // 5. IMMEDIATE SIGN-EXTENSION
    // Sign-extend the 6-bit immediate field instr[5:0] to 16 bits.
    // The sign bit is instr[5].
    // =========================================================================

    // TODO: Implement using the replication and concatenation operators:
    //
           assign ext_im = { {10{instr[5]}}, instr[5:0] }; 
    //
    //       Explanation:
    //         {10{instr[5]}} replicates the sign bit 10 times (bits 15:6)
    //         instr[5:0]     is the original 6-bit value (bits 5:0)
    //         Together they form a 16-bit sign-extended immediate.


    // =========================================================================
    // 6. ALUSrc MULTIPLEXER
    // Select the second ALU operand.
    //   alu_src = 0 -> use register RS2 value
    //   alu_src = 1 -> use sign-extended immediate (for LD, ST, branches)
    // =========================================================================

    // TODO: assign alu_operand_b = alu_src ? ext_im : reg_read_data_2;
           assign alu_operand_b = alu_src ? ext_im : reg_read_data_2;

    // =========================================================================
    // 7. ALU CONTROL UNIT
    // =========================================================================

    // TODO: Instantiate the ALU_Control module.
    //
           ALU_Control alu_ctrl (
               .ALUOp   (alu_op),
               .Opcode  (instr[15:12]),
               .ALU_Cnt (alu_control)
           );


    // =========================================================================
    // 8. ALU
    // =========================================================================

    // TODO: Instantiate the ALU module.
    //
           ALU alu_unit (
               .a           (reg_read_data_1),
               .b           (alu_operand_b),
               .alu_control (alu_control),
               .result      (alu_result),
               .zero        (zero_flag)
           );


    // =========================================================================
    // 9. BRANCH ADDRESS COMPUTATION AND PC-NEXT MUX CHAIN
    //
    //  pc_branch = pc2 + (sign-extended offset << 1)
    //            = pc2 + {ext_im[14:0], 1'b0}
    //
    //  beq_taken  = beq & zero_flag
    //  bne_taken  = bne & ~zero_flag
    //
    //  pc_after_branch:
    //    if (beq_taken | bne_taken) -> pc_branch
    //    else                       -> pc2
    //
    //  pc_jump = { pc2[15:13], instr[11:0], 1'b0 }
    //
    //  pc_next:
    //    if jump -> pc_jump
    //    else    -> pc_after_branch
    // =========================================================================

    // TODO: Implement all of the above using continuous assignments.
    //
           assign pc_branch       = pc2 + {ext_im[14:0], 1'b0};
           assign beq_taken       = beq & zero_flag;
           assign bne_taken       = bne & ~zero_flag;
           assign pc_after_branch = (beq_taken | bne_taken) ? pc_branch : pc2;
           assign jump_target     = {instr[11:0], 1'b0};
           assign pc_jump         = {pc2[15:13], jump_target};
           assign pc_next         = jump ? pc_jump : pc_after_branch;
    //
    //       Note on jump address: {pc2[15:13], jump_target} preserves the
    //       three most-significant bits of PC+2 and replaces bits [12:0]
    //       with the shifted offset, limiting jumps to within the same
    //       8 KB aligned region. This matches the StarCore ISA specification.


    // =========================================================================
    // 10. DATA MEMORY
    // =========================================================================

    // TODO: Instantiate the DataMemory module.
    //       The memory address comes from the ALU result (address calculation).
    //       The write data comes from RS2 (for ST instructions).
    //
           DataMemory dm (
               .clk             (clk),
               .mem_access_addr (alu_result),
               .mem_write_data  (reg_read_data_2),
               .mem_write_en    (mem_write),
               .mem_read        (mem_read),
               .mem_read_data   (mem_read_data)
           );


    // =========================================================================
    // 11. WRITE-BACK MULTIPLEXER (MemToReg)
    // Select the data written back to the register file.
    //   mem_to_reg = 0 -> ALU result  (for R-type and other compute instructions)
    //   mem_to_reg = 1 -> memory read data (for LD instruction)
    // =========================================================================

    // TODO: assign reg_write_data = mem_to_reg ? mem_read_data : alu_result;
            assign reg_write_data = mem_to_reg ? mem_read_data : alu_result;

endmodule
