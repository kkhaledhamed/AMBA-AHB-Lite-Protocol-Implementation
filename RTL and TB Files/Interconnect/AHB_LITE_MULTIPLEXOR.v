module AHB_LITE_MULTIPLEXOR (
    input wire [1:0] Multiplexor_Select,
    input wire [31:0] X1, X2, X3,
    input wire Y1, Y2, Y3,
    input wire Z1, Z2, Z3,
    output reg [31:0] X,
    output reg Y,
    output reg Z
);

always @(*) begin
    case (Multiplexor_Select)
        2'b00: begin 
                X = X1; 
                Y = Y1; 
                Z = Z1; 
            end
        2'b01: begin 
                X = X2; 
                Y = Y2; 
                Z = Z2; 
            end
        2'b10: begin 
                X = X3; 
                Y = Y3; 
                Z = Z3; 
            end
        default: begin 
                    // Maintain previous values during idle
                    X = X;  
                    Y = Y;  
                    Z = Z;  
                end
    endcase
end

endmodule