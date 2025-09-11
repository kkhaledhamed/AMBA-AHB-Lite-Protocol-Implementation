module AHB_LITE_SLAVE #(
    parameter BASE_ADDR = 32'h4000_0000,
    parameter MEM_SIZE  = 1024,
    parameter SLOT_ID   = 0
)(
    input wire         HCLK,
    input wire         HRESETn,
    input wire [31:0]  HADDR,
    input wire         HWRITE,
    input wire [2:0]   HSIZE, 
    input wire [2:0]   HBURST,
    input wire [3:0]   HPROT,
    input wire [1:0]   HTRANS,
    input wire         HMASTLOCK,
    input wire         HREADY,
    input wire [31:0]  HWDATA,
    input wire         HREADYIN,

    output reg [31:0]  HRDATA,
    output reg         HREADYOUT,
    output reg         HRESP
);

    // Internal Parameters
    localparam HIGH_ADDR = BASE_ADDR + MEM_SIZE - 1;
    localparam MEM_DEPTH = MEM_SIZE >> 2;
    localparam ADDR_LSB  = 2;

    localparam [1:0] IDLE   = 2'b00,
                     ERROR1 = 2'b01,
                     ERROR2 = 2'b10;

    // Registers
    reg [31:0] memory [0:MEM_DEPTH-1];
    reg [31:0] haddr_d;
    reg        hwrite_d;
    reg [2:0]  hsize_d;
    reg [1:0]  htrans_d;
    reg        active_d;
    reg        error_d;
    reg [1:0]  state;
    reg        hready_d;

    // Address decoding and error checks
    wire in_range     = (HADDR >= BASE_ADDR) && (HADDR <= HIGH_ADDR);
    wire transfer_in  = HREADYIN && HTRANS[1];
    wire slave_sel    = in_range && transfer_in;

    wire [31:0] access_end = HADDR + (1 << HSIZE) - 1;
    wire out_of_range      = access_end > HIGH_ADDR;
    wire size_error        = (HSIZE != 3'b000) && (HSIZE != 3'b001) && (HSIZE != 3'b010);
    wire align_error       = ((HSIZE == 3'b010 && |HADDR[1:0]) || (HSIZE == 3'b001 && HADDR[0]));
    wire error_cond        = slave_sel && (out_of_range || size_error || align_error);

    wire [31:0] mem_addr = (haddr_d - BASE_ADDR) >> ADDR_LSB;

    // Input latching 
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            haddr_d  <= 0;
            hwrite_d <= 0;
            hsize_d  <= 0;
            htrans_d <= 0;
            active_d <= 0;
            error_d  <= 0;
            hready_d <= 1;
        end else begin
            hready_d <= HREADYIN;
            if (HREADYIN) begin
                haddr_d  <= HADDR;
                hwrite_d <= HWRITE;
                hsize_d  <= HSIZE;
                htrans_d <= HTRANS;
                active_d <= slave_sel;
                error_d  <= error_cond;
            end
        end
    end

    // Error FSM
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) 
            state <= IDLE;
        else case (state)
            IDLE:   if (active_d && error_d) state <= ERROR1;
            ERROR1: state <= ERROR2;
            ERROR2: state <= IDLE;
            default: state <= IDLE;
        endcase
    end

    // Memory Write
    always @(posedge HCLK) begin
        if (active_d && hwrite_d && state == IDLE && !error_d) begin
            case (hsize_d)
                3'b000: // byte
                    case (haddr_d[1:0])
                        2'b00: memory[mem_addr][7:0]   <= HWDATA[7:0];
                        2'b01: memory[mem_addr][15:8]  <= HWDATA[7:0];
                        2'b10: memory[mem_addr][23:16] <= HWDATA[7:0];
                        2'b11: memory[mem_addr][31:24] <= HWDATA[7:0];
                    endcase
                3'b001: // halfword
                    if (haddr_d[1])
                        memory[mem_addr][31:16] <= HWDATA[15:0];
                    else
                        memory[mem_addr][15:0]  <= HWDATA[15:0];
                3'b010: // word
                    memory[mem_addr] <= HWDATA;
            endcase
        end
    end

    // Memory Read and Outputs
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA    <= 0;
            HREADYOUT <= 1;
            HRESP     <= 0;
        end else begin
            // Default outputs
            HREADYOUT <= 1;
            HRESP     <= 0;
            
            // Error response
            if (state == ERROR1 || state == ERROR2) begin
                HREADYOUT <= (state == ERROR2);
                HRESP     <= 1;
            end 
            // Valid read operation
            else if (active_d && !hwrite_d) begin
                HRDATA <= memory[mem_addr];
            end
        end
    end


endmodule