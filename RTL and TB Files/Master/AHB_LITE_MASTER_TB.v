`timescale 1ns / 1ps

module AHB_LITE_MASTER_TB;

  reg         HCLK;
  reg         HRESETn;
  reg         HREADY;
  reg         HRESP;
  reg         HWRITE_IN;
  reg  [31:0] HRDATA;
  reg         start;
  reg         burst;
  reg  [31:0] HADDR_IN;
  reg  [31:0] HWDATA_IN;
  reg  [2:0]  HSIZE_IN;
  reg  [2:0]  HBURST_IN;

  wire [31:0] HADDR;
  wire [2:0]  HBURST;
  wire        HMASTLOCK;
  wire [3:0]  HPROT;
  wire [2:0]  HSIZE;
  wire [1:0]  HTRANS;
  wire [31:0] HWDATA;
  wire        HWRITE;

  // Clock generation
  initial begin
    HCLK = 0;
    forever  
      #5 HCLK = ~HCLK;
  end 
 
  // Instantiate DUT
  AHB_LITE_MASTER DUT (
    .HCLK(HCLK), .HRESETn(HRESETn), .HREADY(HREADY), .HRESP(HRESP),
    .HWRITE_IN(HWRITE_IN), .HRDATA(HRDATA), .start(start), .burst(burst),
    .HADDR_IN(HADDR_IN), .HWDATA_IN(HWDATA_IN), .HSIZE_IN(HSIZE_IN), .HBURST_IN(HBURST_IN),
    .HADDR(HADDR), .HBURST(HBURST), .HMASTLOCK(HMASTLOCK), .HPROT(HPROT),
    .HSIZE(HSIZE), .HTRANS(HTRANS), .HWDATA(HWDATA), .HWRITE(HWRITE)
  );

  // Setup
  initial begin
    
    $display("==== AHB-Lite Master Verification Testbench ====");
    HRESETn = 0; HREADY = 1; HRESP = 0; HRDATA = 32'hDEAD_BEEF;
    HWRITE_IN = 0; burst = 0; start = 0;
    repeat (2) @(posedge HCLK);
    HRESETn = 1;
    @(posedge HCLK);

    // Run testcases
    test_single(1'b1, 3'b000); // byte Write
    test_single(1'b0, 3'b000); // byte read

    test_single(1'b1, 3'b001); // halfword write 
    test_single(1'b0, 3'b001); // halfword read

    test_single(1'b1, 3'b010); // word write
    test_single(1'b0, 3'b010); // word read

    test_burst(1'b1, 3'b001, 3'b001); // INCR burst write halfword
    test_burst(1'b0, 3'b001, 3'b001); // INCR burst read halfword
    
    test_burst(1'b1, 3'b010, 3'b011); // INCR4 burst write word
    test_burst(1'b0, 3'b010, 3'b011); // INCR4 burst read word

    test_burst(1'b1, 3'b010, 3'b101); // INCR8 burst write word
    test_burst(1'b0, 3'b010, 3'b101); // INCR8 burst read word

    test_burst(1'b1, 3'b000, 3'b111); // INCR16 burst write byte
    test_burst(1'b1, 3'b000, 3'b111); // INCR16 burst read byte

    wait_state_case();
    error_response_case();

    $display("==== Testbench Complete ====");
    $finish;
  end

  // Single transfer task
  task test_single;
    input wr;
    input [2:0] size;
    begin
      @(posedge HCLK);
      $display("[%0t ns] TEST: SINGLE %s | HSIZE=%0d", $time, wr ? "WRITE" : "READ", size);
      HWRITE_IN = wr;
      HSIZE_IN  = size;
      HBURST_IN = 3'b000;
      burst     = 0;
      start     = 1;
      HADDR_IN  = 32'h1000_0000 + size;
      HWDATA_IN = 32'hA5A5_0000 + size;
      @(posedge HCLK);
      start = 0;
      repeat (3) @(posedge HCLK);
    end
  endtask

  // Burst transfer task
  task test_burst;
    input wr;
    input [2:0] size;
    input [2:0] burst_type;
    integer beats;
    begin
      // Determine beat count
      case (burst_type)
        3'b001: beats = 8;   // INCR: arbitrary max
        3'b011: beats = 4;   // INCR4
        3'b101: beats = 8;   // INCR8
        3'b111: beats = 16;  // INCR16
        default: beats = 1;
      endcase

      @(posedge HCLK);
      $display("[%0t ns] TEST: BURST %s | HSIZE=%0d | HBURST=0b%b (%0d beats)",
               $time, wr ? "WRITE" : "READ", size, burst_type, beats);

      HWRITE_IN = wr;
      HSIZE_IN  = size;
      HBURST_IN = burst_type;
      burst     = 1;
      start     = 1;
      HADDR_IN  = 32'h2000_0000;
      HWDATA_IN = 32'hAA00_0000 | {burst_type, 21'b0};
      @(posedge HCLK);
      start = 0;

      repeat (beats + 4) @(posedge HCLK); // Allow time for burst + FSM delays
    end
  endtask

  // Wait state simulation
  task wait_state_case;
    begin
      @(posedge HCLK);
      $display("[%0t ns] TEST: WAIT STATE", $time);
      HWRITE_IN = 1;
      burst     = 0;
      start     = 1;
      HADDR_IN  = 32'h3000_0000;
      HSIZE_IN  = 3'b010;
      HBURST_IN = 3'b000;
      HWDATA_IN = 32'hCAFEBABE;
      @(posedge HCLK);
      start  = 0;
      HREADY = 0;
      repeat (3) @(posedge HCLK);
      HREADY = 1;
      repeat (3) @(posedge HCLK);
    end
  endtask

  // Error response simulation
  task error_response_case;
    begin
      @(posedge HCLK);
      $display("[%0t ns] TEST: ERROR RESPONSE", $time);
      HRESP     = 1;
      start     = 1;
      burst     = 0;
      HWRITE_IN = 1;
      HADDR_IN  = 32'h4000_0000;
      HWDATA_IN = 32'hBAD0BAD0;
      HSIZE_IN  = 3'b010;
      HBURST_IN = 3'b000;
      @(posedge HCLK);
      start = 0;
      HRESP = 0;
      repeat (3) @(posedge HCLK);
    end
  endtask

endmodule
