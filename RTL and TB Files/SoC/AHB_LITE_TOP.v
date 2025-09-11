module AHB_LITE_TOP (
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        start,
    input  wire        burst,
    input  wire        HWRITE_IN,
    input  wire [31:0] HADDR_IN,
    input  wire [31:0] HWDATA_IN,
    input  wire [2:0]  HSIZE_IN,
    input  wire [2:0]  HBURST_IN
);

    // Global Master <-> Interconnect wires
    wire [31:0] HADDR, HRDATA_M, HWDATA;
    wire        HWRITE;
    wire [3:0]  HPROT;
    wire [2:0]  HSIZE, HBURST;
    wire [1:0]  HTRANS;
    wire        HMASTLOCK;
    wire        HREADY, HRESP;

    // Slave <-> Interconnect HRDATA, HRESP, HREADYOUT
    wire [31:0] HRDATA_S1, HRDATA_S2, HRDATA_S3;
    wire        HRESP_S1, HRESP_S2, HRESP_S3;
    wire        HREADYOUT_S1, HREADYOUT_S2, HREADYOUT_S3;

    // Instantiate the AHB Master
    AHB_LITE_MASTER MASTER_UNIT (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HREADY(HREADY),
        .HRESP(HRESP),
        .HRDATA(HRDATA_M),
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HBURST(HBURST),
        .HPROT(HPROT),
        .HTRANS(HTRANS),
        .HMASTLOCK(HMASTLOCK),
        .HWDATA(HWDATA),
        .HWRITE_IN(HWRITE_IN),
        .HADDR_IN(HADDR_IN),
        .HWDATA_IN(HWDATA_IN),
        .HSIZE_IN(HSIZE_IN),
        .HBURST_IN(HBURST_IN),
        .start(start),
        .burst(burst)
    );

    // Instantiate AHB Interconnection (includes Decoder + MUX)
    AHB_LITE_INTERCONNECTION INTERCONNECT_UNIT (
        .HADDR(HADDR),

        .HRDATA_1(HRDATA_S1),
        .HRDATA_2(HRDATA_S2),
        .HRDATA_3(HRDATA_S3),

        .HRESP_1(HRESP_S1),
        .HRESP_2(HRESP_S2),
        .HRESP_3(HRESP_S3),

        .HREADYOUT_1(HREADYOUT_S1),
        .HREADYOUT_2(HREADYOUT_S2),
        .HREADYOUT_3(HREADYOUT_S3),

        .HRDATA(HRDATA_M),
        .HRESP(HRESP),
        .HREADY(HREADY)
    );

    // Instantiate 3 AHB slaves with different address spaces
    AHB_LITE_SLAVE #(
        .BASE_ADDR(32'h40000000),
        .MEM_SIZE(1024),
        .SLOT_ID(0)
    ) SLAVE_UNIT0 (
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
        .HRDATA(HRDATA_S1),
        .HREADYOUT(HREADYOUT_S1),
        .HRESP(HRESP_S1)
    );

    AHB_LITE_SLAVE #(
        .BASE_ADDR(32'h4000_2000),
        .MEM_SIZE(1024),
        .SLOT_ID(1)
    ) SLAVE_UNIT1 (
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
        .HRDATA(HRDATA_S2),
        .HREADYOUT(HREADYOUT_S2),
        .HRESP(HRESP_S2)
    );

    AHB_LITE_SLAVE #(
        .BASE_ADDR(32'h4000_4000),
        .MEM_SIZE(1024),
        .SLOT_ID(2)
    ) SLAVE_UNIT2 (
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
        .HRDATA(HRDATA_S3),
        .HREADYOUT(HREADYOUT_S3),
        .HRESP(HRESP_S3)
    );

endmodule
