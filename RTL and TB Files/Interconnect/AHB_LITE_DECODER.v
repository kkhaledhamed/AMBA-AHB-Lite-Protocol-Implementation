module AHB_LITE_DECODER (

	/******************  Input Ports ******************/
	input wire [1:0] slave_sel, // HADDR[14:13]

	/******************  Output Ports ******************/
	output reg  HSEL_1, // First Slave Selection
				HSEL_2, // Second Slave Selection
				HSEL_3, // Third Slave Selection

	output reg [1:0] Multiplexor_Select

	);
	/****************** Functionality ******************/
	always @(*) begin
		HSEL_1 = 0;
		HSEL_2 = 0;
		HSEL_3 = 0;
		case(slave_sel)
			2'b00: begin
				HSEL_1 = 1'b1;
				HSEL_2 = 1'b0;
				HSEL_3 = 1'b0;
				Multiplexor_Select = 2'b00;
			end
			2'b01: begin
				HSEL_1 = 1'b0;
				HSEL_2 = 1'b1;
				HSEL_3 = 1'b0;
				Multiplexor_Select = 2'b01;
			end
			2'b10: begin
				HSEL_1 = 1'b0;
				HSEL_2 = 1'b0;
				HSEL_3 = 1'b1;
				Multiplexor_Select = 2'b10;
			end
			default: begin
				HSEL_1 = 1'b0;
				HSEL_2 = 1'b0;
				HSEL_3 = 1'b0;
				Multiplexor_Select = 2'b11; // No Slave Selected
			end
		endcase
	end
endmodule