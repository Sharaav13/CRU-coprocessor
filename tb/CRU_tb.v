`timescale 1ns / 1ps

module cordic_test;

   localparam SZ = 16; // bits of accuracy

   // Inputs to CRU
   reg               CLK_100MHZ;
   reg               reset;
   reg               enable;
   reg signed [15:0] angle;
   reg signed [15:0] Xin, Yin;
   
   // Outputs from CRU
   wire signed [15:0] Xout, Yout;
   wire               done;

   // Waveform generator variables
   localparam FALSE = 1'b0;
   localparam TRUE  = 1'b1;
   
   // Reduce by a factor of 1.647 since that's the gain of the CORDIC algorithm
   localparam VALUE = 32000 / 1.647; 

   reg signed [63:0] i;

   // Instantiate the Coordinate Rotation Unit (CRU)
   CRU dut (
      .clock(CLK_100MHZ),
      .reset(reset),
      .enable(enable),
      .angle(angle),
      .Xin(Xin),
      .Yin(Yin),
      .Xout(Xout),
      .Yout(Yout),
      .done(done)
   );

   initial begin
      $write("Starting sim\n");
      
      // Initialize inputs
      CLK_100MHZ = 1'b0;
      reset      = 1'b1;
      enable     = 1'b0;
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
      angle = ((1 << 16) * i) / 360;    
      $display("Setting Angle = %d degrees, Hex = %h", i, angle);

      // 2. Trigger the Coprocessor (StarCore-1 has already decoded opcode 1010)
      @(posedge CLK_100MHZ);
      enable = TRUE; 

      // 3. Clear trigger after one clock cycle (simulating a 1-cycle instruction issue)
      @(posedge CLK_100MHZ);
      enable = FALSE;
      
      // 4. Wait for the CRU to finish processing
      $display("Waiting for CRU to process (done = 0)...");
      wait(done == 1'b1); // When done asserts to 1, processing is complete
      
      // 5. Capture and display outputs
      $display("Processing Finished! (done = 1)");
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