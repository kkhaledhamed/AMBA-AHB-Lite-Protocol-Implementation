module AHB_LITE_INTERCONNECTION (
    input wire [31:0] HADDR,
    input wire [31:0] HRDATA_1, HRDATA_2, HRDATA_3,
    input wire        HRESP_1,  HRESP_2,  HRESP_3,
    input wire        HREADYOUT_1, HREADYOUT_2, HREADYOUT_3,
    output wire [31:0] HRDATA,
    output wire        HRESP,
    output wire        HREADY
);

    wire HSEL_1, HSEL_2, HSEL_3;
    wire [1:0] Multiplexor_Select;

    AHB_LITE_DECODER DECODER (
        .slave_sel(HADDR[14:13]),
        .HSEL_1(HSEL_1), .HSEL_2(HSEL_2), .HSEL_3(HSEL_3),
        .Multiplexor_Select(Multiplexor_Select)
    );

    AHB_LITE_MULTIPLEXOR MULTIPLEXOR (
        .Multiplexor_Select(Multiplexor_Select),
        .X1(HRDATA_1), .X2(HRDATA_2), .X3(HRDATA_3),
        .Y1(HRESP_1), .Y2(HRESP_2), .Y3(HRESP_3),
        .Z1(HREADYOUT_1), .Z2(HREADYOUT_2), .Z3(HREADYOUT_3),
        .X(HRDATA), .Y(HRESP), .Z(HREADY)
    );

endmodule
