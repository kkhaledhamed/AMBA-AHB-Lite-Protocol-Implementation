module AHB_LITE_MASTER (
    input wire         HCLK,
    input wire         HRESETn,
    input wire         HREADY,
    input wire         HRESP,
    input wire         HWRITE_IN,
    input wire [31:0]  HRDATA,
    input wire         start,
    input wire         burst,
    input wire [31:0]  HADDR_IN,
    input wire [31:0]  HWDATA_IN,  
    input wire [2:0]   HSIZE_IN,
    input wire [2:0]   HBURST_IN,

    output reg [31:0]  HADDR,
    output reg [2:0]   HBURST,
    output reg         HMASTLOCK,
    output reg [3:0]   HPROT,
    output reg [2:0]   HSIZE,  
    output reg [1:0]   HTRANS,
    output reg [31:0]  HWDATA,
    output reg         HWRITE
);

    // FSM States
    localparam IDLE    = 2'b00,
               BUSY    = 2'b01,
               NON_SEQ = 2'b10,
               SEQ     = 2'b11;

    // Burst types
    parameter SINGLE  = 3'b000,
              INCR    = 3'b001,
              INCR4   = 3'b011,
              INCR8   = 3'b101,
              INCR16  = 3'b111;

    // Burst beats
    localparam INCR4_BEATS  = 3,
               INCR8_BEATS  = 7,
               INCR16_BEATS = 15;
    
    // Internal signals
    reg [3:0]  burst_counter;
    reg [31:0] HWDATA_reg;
    reg [3:0]  addr_inc;

    reg [1:0] current_state, next_state;

    // Address increment logic based on size
    always @(*) begin
        case(HSIZE)
            3'b000:  addr_inc = 1;
            3'b001:  addr_inc = 2;
            3'b010:  addr_inc = 4;
            3'b011:  addr_inc = 8;
            default: addr_inc = 4;
        endcase
    end

    // FSM - Current state
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // FSM Next state
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE:
                if (start && HREADY)
                    next_state = NON_SEQ;
                else next_state = IDLE;
            BUSY:
                if (~start || HRESP)
                    next_state = IDLE;
                else if (start && burst && HREADY)
                    next_state = (burst_counter > 0) ? SEQ : NON_SEQ;
                else next_state = BUSY;
            NON_SEQ:
                if (~start || HRESP)
                    next_state = IDLE;
                else if (burst && start && HREADY)
                    next_state = (burst_counter > 0) ? SEQ : NON_SEQ;
                else if (burst && start && ~HREADY)
                    next_state = BUSY;
                else next_state = NON_SEQ;
            SEQ:
                if (~start || HRESP || burst_counter == 0)
                    next_state = IDLE;
                else if (start && burst && ~HREADY)
                    next_state = BUSY;
                else if (!burst)
                    next_state = NON_SEQ;
                else next_state = SEQ;
        endcase
    end

    // Burst counter logic
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            burst_counter <= 0;
        else begin
            case (current_state)
                IDLE:
                    if (start && HREADY)
                        burst_counter <= (HBURST_IN == INCR4)  ? INCR4_BEATS :
                                         (HBURST_IN == INCR8)  ? INCR8_BEATS :
                                         (HBURST_IN == INCR16) ? INCR16_BEATS : 0;
                SEQ:
                    if (HREADY && burst_counter > 0)
                        burst_counter <= burst_counter - 1;
            endcase
        end
    end

    // Write data handling
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HWDATA_reg <= 0;
            HWDATA <= 0;
        end else if (HREADY && !HWRITE) begin
            if (current_state == NON_SEQ) begin
                HWDATA_reg <= HWDATA_IN;
                HWDATA     <= HWDATA_IN;
            end else if (current_state == SEQ) begin
                HWDATA_reg <= HWDATA_IN;
                HWDATA     <= HWDATA_reg;
            end
        end
    end


    // FSM Output logic
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR     <= 0;
            HBURST    <= 0;
            HMASTLOCK <= 0;
            HPROT     <= 0;
            HSIZE     <= 0;
            HTRANS    <= 0;
            HWRITE    <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    HTRANS <= IDLE;
                    if (HREADY && start) begin
                        HWRITE <= HWRITE_IN;
                        HSIZE  <= HSIZE_IN;
                        HBURST <= burst ? HBURST_IN : SINGLE;
                        HADDR  <= HADDR_IN;
                    end
                end
                BUSY:
                    HTRANS <= BUSY;
                NON_SEQ: begin
                    HTRANS <= NON_SEQ;
                    if (HREADY && start) begin
                        HWRITE <= HWRITE_IN;
                        HSIZE  <= HSIZE_IN;
                        HBURST <= burst ? HBURST_IN : SINGLE;
                        if (burst && burst_counter > 0)
                            HADDR <= HADDR + addr_inc;
                    end
                end
                SEQ: begin
                    HTRANS <= SEQ;
                    if (HREADY)
                        HADDR <= HADDR + addr_inc;
                end
            endcase
        end
    end

endmodule
