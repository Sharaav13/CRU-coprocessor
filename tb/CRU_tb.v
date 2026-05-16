`timescale 1ns / 1ps

module cordic_test;

   localparam SZ = 16; // bits of accuracy

   // Inputs to CRU
   reg               CLK_100MHZ;
   reg               reset;
   reg               enable;
   reg         [3:0] opcode;
   reg signed [15:0] angle;
   reg signed [15:0] Xin, Yin;
   
   // Outputs from CRU
   wire signed [15:0] Xout, Yout; // Updated to 16-bit from [SZ:0]
   wire               busy;
   wire               done;

   // Waveform generator variables
   localparam FALSE = 1'b0;
   localparam TRUE  = 1'b1;
   
   // Reduce by a factor of 1.647 since that's the gain of the CORDIC algorithm
   localparam VALUE = 32000 / 1.647; 

   reg signed [63:0] i;

   // Instantiate the newly adapted Coordinate Rotation Unit (CRU)
   CRU dut (
      .clock(CLK_100MHZ),
      .reset(reset),
      .enable(enable),
      .opcode(opcode),
      .angle(angle),
      .Xin(Xin),
      .Yin(Yin),
      .Xout(Xout),
      .Yout(Yout),
      .busy(busy),
      .done(done)
   );

   initial begin
      $write("Starting sim\n");
      
      // Initialize inputs
      CLK_100MHZ = 1'b0;
      reset      = 1'b1;
      enable     = 1'b0;
      opcode     = 4'b0000;
      angle      = 16'd0;
      Xin        = VALUE; // Xout will be 32000*cos(angle)
      Yin        = 16'd0; // Yout will be 32000*sin(angle)
      
      i = 60; // Test with a 60-degree angle
      
      // Hold reset for a while
      #100;
      @(posedge CLK_100MHZ);
      reset = 1'b0;
      #20;

      // ---------------------------------------------------------
      // StarCore-1 Interface Simulation
      // ---------------------------------------------------------
      
      // 1. Prepare data 
      // Calculate 16-bit angle: (angle_in_degrees / 360) * 2^16
      // example: 45 deg = 45/360 * 2^16 = 8192 (16'h2000)
      angle = ((1 << 16) * i) / 360;    
      $display("Setting Angle = %d degrees, Hex = %h", i, angle);

      // 2. Trigger the Coprocessor
      @(posedge CLK_100MHZ);
      enable = TRUE;
      opcode = 4'b1010; // StarCore-1 trigger opcode

      // 3. Clear trigger after one clock cycle (simulating a 1-cycle instruction issue)
      @(posedge CLK_100MHZ);
      enable = FALSE;
      opcode = 4'b0000;
      
      // 4. Wait for the CRU to finish processing
      $display("Waiting for CRU to process...");
      wait(done == 1'b1);
      
      // 5. Capture and display outputs
      $display("Processing Finished!");
      $display("Outputs -> Xout (Cos): %d, Yout (Sin): %d", Xout, Yout);

      #500;
      $write("Simulation has finished\n");
      $stop;
   end

   // Clock generation
   parameter CLK100_SPEED = 10;  // 100Mhz = 10ns period
   initial begin
      CLK_100MHZ = 1'b0;
      $display("CLK_100MHZ started");
      #5;
      forever begin
         #(CLK100_SPEED/2) CLK_100MHZ = 1'b1;
         #(CLK100_SPEED/2) CLK_100MHZ = 1'b0;
      end
   end

endmodule