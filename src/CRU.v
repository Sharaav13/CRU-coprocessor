`timescale 1ns / 1ps

module CRU(
   input  wire               clock,
   input  wire               reset,   // Added reset for control state initialization
   input  wire               enable,  // Signal from StarCore-1 that a coprocessor instruction is ready
   input  wire         [3:0] opcode,  // Opcode from StarCore-1 (Triggers on 4'b1010)
   
   input  signed      [15:0] angle,   // Target angle for rotation
   input  signed      [15:0] Xin,     // Initial X coordinate
   input  signed      [15:0] Yin,     // Initial Y coordinate
   
   output signed      [15:0] Xout,    // Final X rotated coordinate
   output signed      [15:0] Yout,    // Final Y rotated coordinate
   
   output wire               busy,    // Notifies StarCore-1 that the CRU is processing
   output wire               done     // Flags StarCore-1 that processing is finished and outputs are valid
);

   //------------------------------------------------------------------------------
   //                              Parameters
   //------------------------------------------------------------------------------
   parameter c_parameter = 16;      // Bit width of input and output data
   localparam STG = c_parameter;    // Number of CORDIC pipeline stages (16 stages for 16-bit precision)
   
   //------------------------------------------------------------------------------
   //                    Coprocessor Control Path (StarCore-1 Interface)
   //------------------------------------------------------------------------------
   // valid_pipe tracks the active instruction as it flows through the 16 CORDIC stages.
   // Instead of stalling the processor with a traditional state machine, a pipelined 
   // design allows StarCore-1 to potentially issue a new CRU instruction every clock cycle.
   reg [STG-1:0] valid_pipe;

   always @(posedge clock or posedge reset) begin
      if (reset) begin
         valid_pipe <= 0;
      end else begin
         // Inject a '1' into the pipeline if enabled and the opcode matches 1010.
         // Shift existing valid bits down the pipeline parallel to the data.
         valid_pipe <= {valid_pipe[STG-2:0], (enable && (opcode == 4'b1010))};
      end
   end

   // The CRU is 'busy' if any stage prior to the final output holds a valid instruction.
   assign busy = |valid_pipe[STG-2:0];
   
   // 'done' is asserted when the instruction reaches the final stage, meaning Xout/Yout are ready.
   assign done = valid_pipe[STG-1];


   //------------------------------------------------------------------------------
   //                              Arctan Lookup Table
   //------------------------------------------------------------------------------
   // 16-bit resolution table. Represents atan(2^-i) for each stage.
   wire signed [15:0] atan_table [0:30];
   
   assign atan_table[00] = 16'b0010000000000000; // 45.000 degrees -> atan(2^0)
   assign atan_table[01] = 16'b0001001011100100; // 26.565 degrees -> atan(2^-1)
   assign atan_table[02] = 16'b0000100111111011; // 14.036 degrees -> atan(2^-2)
   assign atan_table[03] = 16'b0000010100010001; // atan(2^-3)
   assign atan_table[04] = 16'b0000001010001011;
   assign atan_table[05] = 16'b0000000101000101;
   assign atan_table[06] = 16'b0000000010100010;
   assign atan_table[07] = 16'b0000000001010001;
   assign atan_table[08] = 16'b0000000000101000;
   assign atan_table[09] = 16'b0000000000010100;
   assign atan_table[10] = 16'b0000000000001010;
   assign atan_table[11] = 16'b0000000000000101;
   assign atan_table[12] = 16'b0000000000000010;
   assign atan_table[13] = 16'b0000000000000001;
   assign atan_table[14] = 16'b0000000000000000;
   assign atan_table[15] = 16'b0000000000000000; // Values taper off to 0 due to 16-bit precision limit
   
   //------------------------------------------------------------------------------
   //                              Pipeline Registers
   //------------------------------------------------------------------------------
   // Arrays of registers to hold the X, Y, and Z (angle remainder) at each stage
   reg signed [c_parameter -1:0] X [0:STG-1];
   reg signed [c_parameter -1:0] Y [0:STG-1];
   reg signed             [15:0] Z [0:STG-1];
   
   //------------------------------------------------------------------------------
   //                      Stage 0: Pre-rotation (Quadrant Mapping)
   //------------------------------------------------------------------------------
   // The CORDIC algorithm natively only converges if the angle is between -PI/2 and PI/2.
   // We look at the top 2 bits to determine the quadrant and rotate by +/- 90 degrees if needed.
   wire [1:0] quadrant = angle[15:14];
   
   always @(posedge clock) begin 
      case (quadrant)
         2'b00, 2'b11: begin 
            // Quadrants 1 & 4 (already between -PI/2 and PI/2) -> No rotation needed
            X[0] <= Xin;
            Y[0] <= Yin;
            Z[0] <= angle;
         end
         
         2'b01: begin
            // Quadrant 2 -> Pre-rotate by -90 degrees
            X[0] <= -Yin;
            Y[0] <= Xin;
            Z[0] <= {2'b00, angle[13:0]}; 
         end
         
         2'b10: begin
            // Quadrant 3 -> Pre-rotate by +90 degrees
            X[0] <= Yin;
            Y[0] <= -Xin;
            Z[0] <= {2'b11, angle[13:0]}; 
         end
      endcase
   end
   
   //------------------------------------------------------------------------------
   //                      Stages 1 to STG-1: Micro-rotations
   //------------------------------------------------------------------------------
   // This generates the hardware for the remaining pipeline stages. At each step, 
   // the vector is rotated by progressively smaller angles to converge on zero error.
   genvar i;
   generate
      for (i=0; i < (STG-1); i=i+1) begin: XYZ
         wire                   Z_sign;
         wire signed  [c_parameter -1:0] X_shr, Y_shr; 
      
         // Arithmetic shift right simulates division by 2^i
         assign X_shr = X[i] >>> i;
         assign Y_shr = Y[i] >>> i;
         
         // Z_sign determines rotation direction. 1 = negative remainder, 0 = positive remainder
         assign Z_sign = Z[i][15];
      
         always @(posedge clock) begin
            // If remainder angle is negative (Z_sign=1), rotate clockwise (add Y to X, subtract X from Y).
            // If remainder angle is positive (Z_sign=0), rotate counter-clockwise (subtract Y from X, add X to Y).
            X[i+1] <= Z_sign ? X[i] + Y_shr         : X[i] - Y_shr;
            Y[i+1] <= Z_sign ? Y[i] - X_shr         : Y[i] + X_shr;
            Z[i+1] <= Z_sign ? Z[i] + atan_table[i] : Z[i] - atan_table[i];
         end
      end
   endgenerate
   
   //------------------------------------------------------------------------------
   //                                 Data Output
   //------------------------------------------------------------------------------
   // Wire the final stage to the coprocessor outputs. These values should be read
   // by StarCore-1 exactly when 'done' asserts high.
   assign Xout = X[STG-1];
   assign Yout = Y[STG-1];

endmodule