`timescale 1ns / 1ps

module AHB_LITE_TOP_TB;

  // Clock and Reset
  reg HCLK, HRESETn;

  // Master Inputs
  reg         start;
  reg         burst;
  reg  [31:0] HADDR_IN;
  reg  [31:0] HWDATA_IN;
  reg         HWRITE_IN;
  reg  [2:0]  HSIZE_IN;
  reg  [2:0]  HBURST_IN;

  // Slave-to-Interconnect
  wire [31:0] HRDATA_1, HRDATA_2, HRDATA_3;
  wire        HREADYOUT_1, HREADYOUT_2, HREADYOUT_3;
  wire        HRESP_1, HRESP_2, HRESP_3;

  // Interconnect-to-Master
  wire [31:0] HRDATA;
  wire        HREADY;
  wire        HRESP;

  // Master Outputs
  wire [31:0] HADDR;
  wire [2:0]  HBURST;
  wire        HMASTLOCK;
  wire [3:0]  HPROT;
  wire [2:0]  HSIZE;
  wire [1:0]  HTRANS;
  wire [31:0] HWDATA;
  wire        HWRITE;

  // Clock Generation
  initial begin
    HCLK = 0;
    forever #5 HCLK = ~HCLK;
  end 

  // Instantiate DUTs
  AHB_LITE_MASTER master (
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .HREADY(HREADY),
    .HRESP(HRESP),
    .HWRITE_IN(HWRITE_IN),
    .HRDATA(HRDATA),
    .start(start),
    .burst(burst),
    .HADDR_IN(HADDR_IN),
    .HWDATA_IN(HWDATA_IN),
    .HSIZE_IN(HSIZE_IN),
    .HBURST_IN(HBURST_IN),
    .HADDR(HADDR),
    .HBURST(HBURST),
    .HMASTLOCK(HMASTLOCK),
    .HPROT(HPROT),
    .HSIZE(HSIZE),
    .HTRANS(HTRANS),
    .HWDATA(HWDATA),
    .HWRITE(HWRITE)
  );

  AHB_LITE_INTERCONNECTION interconnect (
    .HADDR(HADDR),
    .HRDATA_1(HRDATA_1),
    .HRDATA_2(HRDATA_2),
    .HRDATA_3(HRDATA_3),
    .HRESP_1(HRESP_1),
    .HRESP_2(HRESP_2),
    .HRESP_3(HRESP_3),
    .HREADYOUT_1(HREADYOUT_1),
    .HREADYOUT_2(HREADYOUT_2),
    .HREADYOUT_3(HREADYOUT_3),
    .HRDATA(HRDATA),
    .HRESP(HRESP),
    .HREADY(HREADY)
  );

  AHB_LITE_SLAVE #(
    .BASE_ADDR(32'h4000_0000),
    .MEM_SIZE(1024),
    .SLOT_ID(0)
  ) slave1 (
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .HADDR(HADDR),
    .HWRITE(HWRITE),
    .HSIZE(HSIZE),
    .HBURST(HBURST),
    .HPROT(HPROT),
    .HTRANS(HTRANS),
    .HMASTLOCK(HMASTLOCK),
    .HREADY(HREADY),
    .HWDATA(HWDATA),
    .HREADYIN(HREADY),
    .HRDATA(HRDATA_1),
    .HREADYOUT(HREADYOUT_1),
    .HRESP(HRESP_1)
  );

  AHB_LITE_SLAVE #(
    .BASE_ADDR(32'h4000_2000),
    .MEM_SIZE(1024),
    .SLOT_ID(1)
  ) slave2 (
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .HADDR(HADDR),
    .HWRITE(HWRITE),
    .HSIZE(HSIZE),
    .HBURST(HBURST),
    .HPROT(HPROT),
    .HTRANS(HTRANS),
    .HMASTLOCK(HMASTLOCK),
    .HREADY(HREADY),
    .HWDATA(HWDATA),
    .HREADYIN(HREADY),
    .HRDATA(HRDATA_2),
    .HREADYOUT(HREADYOUT_2),
    .HRESP(HRESP_2)
  );

  AHB_LITE_SLAVE #(
    .BASE_ADDR(32'h4000_4000),
    .MEM_SIZE(1024),
    .SLOT_ID(2)
  ) slave3 (
    .HCLK(HCLK),
    .HRESETn(HRESETn),
    .HADDR(HADDR),
    .HWRITE(HWRITE),
    .HSIZE(HSIZE),
    .HBURST(HBURST),
    .HPROT(HPROT),
    .HTRANS(HTRANS),
    .HMASTLOCK(HMASTLOCK),
    .HREADY(HREADY),
    .HWDATA(HWDATA),
    .HREADYIN(HREADY),
    .HRDATA(HRDATA_3),
    .HREADYOUT(HREADYOUT_3),
    .HRESP(HRESP_3)
  );

  // Test Sequence
  initial begin
    HRESETn = 0;
    #20 HRESETn = 1;

    $display("==== Starting Master-Slave System Test ====");
    
    // Initialize inputs
    start = 0;
    burst = 0;
    HADDR_IN = 0;
    HWDATA_IN = 0;
    HWRITE_IN = 0;
    HSIZE_IN = 3'b010;  // Default to word size
    HBURST_IN = 3'b000; // Single transfer
    #40; // Wait for reset
    
    // Test 1: Write to Slave 1
    write(32'h4000_0000, 32'h11223344);
    #40;
    
    // Test 2: Read from Slave 1
    read(32'h4000_0000, 32'h11223344);
    #40;
    
    // Test 3: Write to Slave 2
    write(32'h4000_2000, 32'hDEADBEEF);
    #40;
    
    // Test 4: Read from Slave 2
    read(32'h4000_2000, 32'hDEADBEEF);
    #40;
    
    // Test 5: Write to Slave 3
    write(32'h4000_4000, 32'hAABBCCDD);
    #40;
    
    // Test 6: Read from Slave 3
    read(32'h4000_4000, 32'hAABBCCDD);
    #40;
    
    $display("==== Test Done ====");
    #100 $stop;
  end

  // Fixed Write Task
  task write(input [31:0] addr, input [31:0] data);
    begin
      $display("Writing 0x%h to 0x%h %0t", data, addr, $time);
      
      HADDR_IN = addr;
      HWDATA_IN = data;
      HWRITE_IN = 1;
      start = 1;
      
      // Wait for address phase completion
      wait(HTRANS == 2'b10 && HREADY);
      @(posedge HCLK); // Complete data phase
      
      start = 0; // Deassert after transfer completes
      $display("Write complete at %0t", $time);
    end
  endtask

  // Fixed Read Task
  task read(input [31:0] addr, input [31:0] expected);
    reg [31:0] read_data;
    begin
      $display("Reading from 0x%h at %0t", addr, $time);
      
      HADDR_IN = addr;
      HWRITE_IN = 0;
      start = 1;
      
      // Wait for address phase completion
      wait(HTRANS == 2'b10 && HREADY);
      @(posedge HCLK); // Move to data phase
      @(posedge HCLK); // Capture data
      
      read_data = HRDATA;
      start = 0; // Deassert after data capture
      
      $display("Read data: 0x%h at %0t", read_data, $time);

    end
  endtask

  // Real-time bus monitor
  initial begin
      $monitor("[%0t] HTRANS: %b, HADDR: %h, HWRITE: %b, HWDATA: %h, HRDATA: %h, HREADY: %b",
               $time, HTRANS, HADDR, HWRITE, HWDATA, HRDATA, HREADY);
  end


endmodule
