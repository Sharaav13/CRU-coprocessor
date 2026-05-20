// =============================================================================
// EEE4120F Practical 4 — StarCore-1 Processor
// File        : ControlUnit_tb.v
// Description : Testbench for the Main Control Unit (Task 6).
//               Applies every defined opcode and verifies all ten control
//               signal outputs match the truth table in Section 3.3 of the
//               practical manual.
//
// Run:
//   iverilog -Wall -I ../src -o ../build/cu_sim ../src/ControlUnit.v ControlUnit_tb.v
//   cd ../test && ../build/cu_sim
//   gtkwave ../waves/cu_tb.vcd &
// =============================================================================

`timescale 1ns / 1ps
`include "../src/Parameter.v"

module ControlUnit_tb;

    reg  [3:0] opcode;

    wire [1:0] alu_op;
    wire       jump;
    wire       beq;
    wire       bne;
    wire       mem_read;
    wire       mem_write;
    wire       alu_src;
    wire       reg_dst;
    wire       mem_to_reg;
    wire       reg_write;

    ControlUnit uut (
        .opcode     (opcode),
        .alu_op     (alu_op),
        .jump       (jump),
        .beq        (beq),
        .bne        (bne),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .alu_src    (alu_src),
        .reg_dst    (reg_dst),
        .mem_to_reg (mem_to_reg),
        .reg_write  (reg_write)
    );

    initial begin
        $dumpfile("../waves/cu_tb.vcd");
        $dumpvars(0, ControlUnit_tb);
    end

    integer fail_count;
    integer test_id;

    // -------------------------------------------------------------------------
    // Composite check task — verifies all 10 control signals in one call.
    // Parameters mirror the truth table column order from the manual.
    // -------------------------------------------------------------------------
    task check_ctrl;
        // Expected values
        input [1:0] e_alu_op;
        input       e_jump, e_beq, e_bne;
        input       e_mem_read, e_mem_write;
        input       e_alu_src, e_reg_dst;
        input       e_mem_to_reg, e_reg_write;
        input [63:0] id;

        reg failed;
        begin
            failed = 1'b0;

            if (alu_op    !== e_alu_op)    begin $display("  MISMATCH alu_op:    %b vs %b", alu_op,    e_alu_op);    failed=1; end
            if (jump      !== e_jump)      begin $display("  MISMATCH jump:      %b vs %b", jump,      e_jump);      failed=1; end
            if (beq       !== e_beq)       begin $display("  MISMATCH beq:       %b vs %b", beq,       e_beq);       failed=1; end
            if (bne       !== e_bne)       begin $display("  MISMATCH bne:       %b vs %b", bne,       e_bne);       failed=1; end
            if (mem_read  !== e_mem_read)  begin $display("  MISMATCH mem_read:  %b vs %b", mem_read,  e_mem_read);  failed=1; end
            if (mem_write !== e_mem_write) begin $display("  MISMATCH mem_write: %b vs %b", mem_write, e_mem_write); failed=1; end
            if (alu_src   !== e_alu_src)   begin $display("  MISMATCH alu_src:   %b vs %b", alu_src,   e_alu_src);   failed=1; end
            if (reg_dst   !== e_reg_dst)   begin $display("  MISMATCH reg_dst:   %b vs %b", reg_dst,   e_reg_dst);   failed=1; end
            if (mem_to_reg!== e_mem_to_reg)begin $display("  MISMATCH mem_to_reg:%b vs %b", mem_to_reg,e_mem_to_reg);failed=1; end
            if (reg_write !== e_reg_write) begin $display("  MISMATCH reg_write: %b vs %b", reg_write, e_reg_write); failed=1; end

            if (failed) begin
                $display("FAIL [T%0d]: opcode=%b", id, opcode);
                fail_count = fail_count + 1;
            end else
                $display("PASS [T%0d]: opcode=%b all signals correct", id, opcode);
        end
    endtask

    initial begin
        fail_count = 0;
        test_id    = 1;
        $display("=== ControlUnit Testbench ===");
        $display("    Format: check_ctrl(alu_op, jump, beq, bne, mem_read, mem_write, alu_src, reg_dst, mem_to_reg, reg_write, id)");

        // Truth table columns (from Section 3.3 of the manual):
        // Instr    | RegDst | ALUSrc | MemToReg | RegWrite | MemRd | MemWr | Branch | ALUOp | Jump
        // LD       |   0    |   1    |    1     |    1     |   1   |   0   |   0    |  10   |  0
        // ST       |   0    |   1    |    0     |    0     |   0   |   1   |   0    |  10   |  0
        // R-type   |   1    |   0    |    0     |    1     |   0   |   0   |   0    |  00   |  0
        // BEQ      |   0    |   0    |    0     |    0     |   0   |   0   | beq=1  |  01   |  0
        // BNE      |   0    |   0    |    0     |    0     |   0   |   0   | bne=1  |  01   |  0
        // JMP      |   0    |   0    |    0     |    0     |   0   |   0   |   0    |  00   |  1
        // Reserved |   0    |   0    |    0     |    0     |   0   |   0   |   0    |  00   |  0

        // ------------------------------------------------------------------
        // TODO: Apply each opcode and call check_ctrl with expected values.
        //
               // LD (opcode = 4'b0000)
               opcode = 4'b0000; #10;
               //        alu_op  jump  beq   bne   mr    mw    as    rd    mtr   rw    id
               check_ctrl(2'b10, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b1, 1'b1, test_id);
               test_id = test_id + 1;
        
               // ST (opcode = 4'b0001)
               opcode = 4'b0001; #10;
               check_ctrl(2'b10, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, test_id);
               test_id = test_id + 1;
        
               // ADD (opcode = 4'b0010)  -- R-type
               opcode = 4'b0010; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
               test_id = test_id + 1;

               // SUB (opcode = 4'b0011)  -- R-type
               opcode = 4'b0011; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
               test_id = test_id + 1;

               // INV (opcode = 4'b0100)  -- R-type
               opcode = 4'b0100; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
               test_id = test_id + 1;

               // SHL (opcode = 4'b0101)  -- R-type
               opcode = 4'b0101; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
               test_id = test_id + 1;

               // SHR (opcode = 4'b0110)  -- R-type
               opcode = 4'b0110; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
               test_id = test_id + 1;

               // AND (opcode = 4'b0111)  -- R-type
               opcode = 4'b0111; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
               test_id = test_id + 1;

               // OR (opcode = 4'b1000)  -- R-type
               opcode = 4'b1000; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
               test_id = test_id + 1;

               // SLT (opcode = 4'b1001)  -- R-type
               opcode = 4'b1001; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b1, test_id);
               test_id = test_id + 1;

               // Reserved (opcode = 4'b1010)
               opcode = 4'b1010; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
               test_id = test_id + 1;

               // BEQ (opcode = 4'b1011)
               opcode = 4'b1011; #10;
               check_ctrl(2'b01, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
               test_id = test_id + 1;

               // BNE (opcode = 4'b1100)
               opcode = 4'b1100; #10;
               check_ctrl(2'b01, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
               test_id = test_id + 1;

               // JMP (opcode = 4'b1101)
               opcode = 4'b1101; #10;
               check_ctrl(2'b00, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
               test_id = test_id + 1;

               // Undefined (opcode = 4'b1110)
               opcode = 4'b1110; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
               test_id = test_id + 1;

               // Undefined (opcode = 4'b1111)
               opcode = 4'b1111; #10;
               check_ctrl(2'b00, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, test_id);
               test_id = test_id + 1;
        //
        //       // ... continue for all R-type opcodes (0010 through 1001)
        //       // ... then BEQ (1011), BNE (1100), JMP (1101)
        //       // ... and reserved (1010) and a default/undefined opcode
        //
        //       NOTE on Branch: the manual's 'Branch' column maps to beq=1
        //       for BEQ and bne=1 for BNE. Both beq and bne are 0 for JMP.
        // ------------------------------------------------------------------


        $display("");
        if (fail_count == 0)
            $display("=== ALL %0d TESTS PASSED ===", test_id - 1);
        else
            $display("=== %0d / %0d TESTS FAILED ===", fail_count, test_id - 1);
        $finish;
    end

endmodule
