`timescale 1ns/1ps

module AHB_LITE_SLAVE_TB;

    // Clock and reset
    reg HCLK, HRESETn;

    // Master-side signals
    reg  [31:0] HADDR;
    reg         HWRITE;
    reg  [2:0]  HSIZE;
    reg  [2:0]  HBURST;
    reg  [3:0]  HPROT;
    reg  [1:0]  HTRANS;
    reg         HMASTLOCK;
    reg  [31:0] HWDATA;
    reg         HREADY;
    wire [31:0] HRDATA;
    wire        HREADYOUT;
    wire        HRESP;

    // Instantiate the DUT
    AHB_LITE_SLAVE #(
        .BASE_ADDR(32'h40000000),
        .MEM_SIZE(1024)
    ) DUT (
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
        .HREADYIN(HREADY),      // For simple test, loopback
        .HRDATA(HRDATA),
        .HREADYOUT(HREADYOUT),
        .HRESP(HRESP)
    );

    // Clock generation
    initial HCLK = 0;
    always #5 HCLK = ~HCLK;

    // Test procedure
    initial begin
        HRESETn = 0;
        #20;
        HRESETn = 1;
        // Default values
        HADDR      = 0;
        HWRITE     = 0;
        HSIZE      = 3'b010; // word
        HBURST     = 3'b000;
        HPROT      = 4'b0000;
        HTRANS     = 2'b00;
        HMASTLOCK  = 0;
        HWDATA     = 0;
        HREADY     = 1;

        wait(HRESETn == 1);
        #10;

        $display("\nStarting AHB-Lite Slave Testbench\n");

        // Test 1: Basic word write/read
        write_word(32'h40000000, 32'h12345678);
        read_word (32'h40000000, 32'h12345678);

        // Test 2: Byte write/read
        write_byte(32'h40000004, 8'hAB);
        read_byte (32'h40000004, 8'hAB);

        // Test 3: Half-word write/read
        write_half(32'h40000008, 16'hCDEF);
        read_half (32'h40000008, 16'hCDEF);

        // Test 4: Immediate read after write
        write_word(32'h4000000C, 32'hA5A5A5A5);
        read_word (32'h4000000C, 32'hA5A5A5A5);

        $display("\nTestbench completed.\n");
        $finish;
    end

    // === Helper Tasks ===

    task wait_ready;
        begin
            @(posedge HCLK);
            while (!HREADYOUT) @(posedge HCLK);
        end
    endtask

    task write_word(input [31:0] addr, input [31:0] data);
        begin
            @(posedge HCLK);
            HADDR   <= addr;
            HWDATA  <= data;
            HWRITE  <= 1;
            HTRANS  <= 2'b10; // NONSEQ
            HSIZE   <= 3'b010; // Word
            @(posedge HCLK);
            HTRANS  <= 2'b00;
            HWRITE  <= 0;
            wait_ready();
            $display("Write: Addr = 0x%08h, Data = 0x%08h", addr, data);
        end
    endtask

    task read_word(input [31:0] addr, input [31:0] expected);
        begin
            @(posedge HCLK);
            HADDR   <= addr;
            HWRITE  <= 0;
            HTRANS  <= 2'b10; // NONSEQ
            HSIZE   <= 3'b010;
            @(posedge HCLK);
            HTRANS  <= 2'b00;
            wait_ready();
            @(posedge HCLK); // Wait for data to appear
            if (HRDATA !== expected)
                $display("ERROR: Addr = 0x%08h | Expected = 0x%08h | Got = 0x%08h", addr, expected, HRDATA);
            else
                $display("PASS : Addr = 0x%08h | Data = 0x%08h", addr, HRDATA);
        end
    endtask

    task write_byte(input [31:0] addr, input [7:0] data);
        begin
            @(posedge HCLK);
            HADDR   <= addr;
            HWDATA  <= {4{data}}; // replicate to fill word
            HWRITE  <= 1;
            HTRANS  <= 2'b10;
            HSIZE   <= 3'b000; // Byte
            @(posedge HCLK);
            HTRANS  <= 2'b00;
            HWRITE  <= 0;
            wait_ready();
            $display("Write: Addr = 0x%08h, Byte = 0x%02h", addr, data);
        end
    endtask

    task read_byte(input [31:0] addr, input [7:0] expected);
        reg [7:0] actual;
        begin
            @(posedge HCLK);
            HADDR   <= addr;
            HWRITE  <= 0;
            HTRANS  <= 2'b10;
            HSIZE   <= 3'b000; // Byte
            @(posedge HCLK);
            HTRANS  <= 2'b00;
            wait_ready();
            @(posedge HCLK);
            case (addr[1:0])
                2'b00: actual = HRDATA[7:0];
                2'b01: actual = HRDATA[15:8];
                2'b10: actual = HRDATA[23:16];
                2'b11: actual = HRDATA[31:24];
            endcase
            if (actual !== expected)
                $display("ERROR: Addr = 0x%08h | Expected = 0x%02h | Got = 0x%02h", addr, expected, actual);
            else
                $display("PASS : Addr = 0x%08h | Byte = 0x%02h", addr, actual);
        end
    endtask

    task write_half(input [31:0] addr, input [15:0] data);
        begin
            @(posedge HCLK);
            HADDR   <= addr;
            HWDATA  <= {2{data}};
            HWRITE  <= 1;
            HTRANS  <= 2'b10;
            HSIZE   <= 3'b001; // Halfword
            @(posedge HCLK);
            HTRANS  <= 2'b00;
            HWRITE  <= 0;
            wait_ready();
            $display("Write: Addr = 0x%08h, Half = 0x%04h", addr, data);
        end
    endtask

    task read_half(input [31:0] addr, input [15:0] expected);
        reg [15:0] actual;
        begin
            @(posedge HCLK);
            HADDR   <= addr;
            HWRITE  <= 0;
            HTRANS  <= 2'b10;
            HSIZE   <= 3'b001;
            @(posedge HCLK);
            HTRANS  <= 2'b00;
            wait_ready();
            @(posedge HCLK);
            actual = addr[1] ? HRDATA[31:16] : HRDATA[15:0];
            if (actual !== expected)
                $display("ERROR: Addr = 0x%08h | Expected = 0x%04h | Got = 0x%04h", addr, expected, actual);
            else
                $display("PASS : Addr = 0x%08h | Half = 0x%04h", addr, actual);
        end
    endtask

endmodule
