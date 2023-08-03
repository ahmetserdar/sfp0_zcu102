/*

Copyright (c) 2020-2021 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Language: Verilog 2001

`resetall
`timescale 1ns / 1ps
`default_nettype none

/*
 * FPGA top-level module
 */
module fpga (
    /*
     * Clock: 125MHz LVDS
     * Reset: Push button, active low
     */
    input  wire       clk_125mhz, 
    input  wire       rst_125mhz,
   // udp parameters
    input wire [47:0] local_mac_user,
    input wire [31:0] local_ip_user,
    input wire [31:0] server_ip_user,
    input wire [31:0] gateway_ip_user,
    input wire [31:0] subnet_mask_user,
    input wire [15:0] udp_port_user,
    input wire [15:0] udp_length_user, // 1032
    input wire        udp_hdr_valid_user,
    /*
     * GPIO
     */
    input  wire       btnu,
    input  wire       btnl,
    input  wire       btnd,
    input  wire       btnr,
    input  wire       btnc,
    input  wire [7:0] sw,
    output wire [7:0] led,

    /*
     * UART: 115200 bps, 8N1
     */
    input  wire       uart_rxd,
    output wire       uart_txd,
    input  wire       uart_rts,
    output wire       uart_cts,

    /*
     * Ethernet: SFP+
     */
    input  wire       sfp0_rx_p,
    input  wire       sfp0_rx_n,
    output wire       sfp0_tx_p,
    output wire       sfp0_tx_n,
    input  wire       sfp1_rx_p,
    input  wire       sfp1_rx_n,
    output wire       sfp1_tx_p,
    output wire       sfp1_tx_n,
    input  wire       sfp2_rx_p,
    input  wire       sfp2_rx_n,
    output wire       sfp2_tx_p,
    output wire       sfp2_tx_n,
    input  wire       sfp3_rx_p,
    input  wire       sfp3_rx_n,
    output wire       sfp3_tx_p,
    output wire       sfp3_tx_n,
    input  wire       sfp_mgt_refclk_0_p,
    input  wire       sfp_mgt_refclk_0_n,
    output wire       sfp0_tx_disable_b,
    output wire       sfp1_tx_disable_b,
    output wire       sfp2_tx_disable_b,
    output wire       sfp3_tx_disable_b,
    
    output wire [63:0] rx_fifo_udp_payload_axis_tdata,
    output wire [7:0] rx_fifo_udp_payload_axis_tkeep,
    output wire rx_fifo_udp_payload_axis_tvalid,
    input  wire rx_fifo_udp_payload_axis_tready,
    output wire rx_fifo_udp_payload_axis_tlast,
    output wire rx_fifo_udp_payload_axis_tuser,
    
    input wire [63:0] tx_fifo_udp_payload_axis_tdata,
    input wire [7:0] tx_fifo_udp_payload_axis_tkeep,
    input wire tx_fifo_udp_payload_axis_tvalid,
    output wire tx_fifo_udp_payload_axis_tready,
    input wire tx_fifo_udp_payload_axis_tlast,
    input wire tx_fifo_udp_payload_axis_tuser,
    output wire fifo_clk_156mhz,
    output wire fifo_clk_rst_156mhz
);

// Clock and reset

wire clk_125mhz_ibufg;
wire clk_125mhz_bufg;

// Internal 125 MHz clock
wire clk_125mhz_int;
wire rst_125mhz_int;

// Internal 156.25 MHz clock
wire clk_156mhz_int;
wire rst_156mhz_int;

//wire mmcm_rst = reset;
//wire mmcm_locked;
//wire mmcm_clkfb;

//IBUFGDS #(
//   .DIFF_TERM("FALSE"),
//   .IBUF_LOW_PWR("FALSE")   
//)
//clk_125mhz_ibufg_inst (
//   .O   (clk_125mhz_ibufg),
//   .I   (clk_125mhz_p),
//   .IB  (clk_125mhz_n) 
//);

//BUFG
//clk_125mhz_bufg_in_inst (
//    .I(clk_125mhz_ibufg),
//    .O(clk_125mhz_bufg)
//);

//// MMCM instance
//// 125 MHz in, 125 MHz out
//// PFD range: 10 MHz to 500 MHz
//// VCO range: 800 MHz to 1600 MHz
//// M = 8, D = 1 sets Fvco = 1000 MHz (in range)
//// Divide by 8 to get output frequency of 125 MHz
//MMCME4_BASE #(
//    .BANDWIDTH("OPTIMIZED"),
//    .CLKOUT0_DIVIDE_F(8),
//    .CLKOUT0_DUTY_CYCLE(0.5),
//    .CLKOUT0_PHASE(0),
//    .CLKOUT1_DIVIDE(1),
//    .CLKOUT1_DUTY_CYCLE(0.5),
//    .CLKOUT1_PHASE(0),
//    .CLKOUT2_DIVIDE(1),
//    .CLKOUT2_DUTY_CYCLE(0.5),
//    .CLKOUT2_PHASE(0),
//    .CLKOUT3_DIVIDE(1),
//    .CLKOUT3_DUTY_CYCLE(0.5),
//    .CLKOUT3_PHASE(0),
//    .CLKOUT4_DIVIDE(1),
//    .CLKOUT4_DUTY_CYCLE(0.5),
//    .CLKOUT4_PHASE(0),
//    .CLKOUT5_DIVIDE(1),
//    .CLKOUT5_DUTY_CYCLE(0.5),
//    .CLKOUT5_PHASE(0),
//    .CLKOUT6_DIVIDE(1),
//    .CLKOUT6_DUTY_CYCLE(0.5),
//    .CLKOUT6_PHASE(0),
//    .CLKFBOUT_MULT_F(8),
//    .CLKFBOUT_PHASE(0),
//    .DIVCLK_DIVIDE(1),
//    .REF_JITTER1(0.010),
//    .CLKIN1_PERIOD(8.0),
//    .STARTUP_WAIT("FALSE"),
//    .CLKOUT4_CASCADE("FALSE")
//)
//clk_mmcm_inst (
//    .CLKIN1(clk_125mhz_bufg),
//    .CLKFBIN(mmcm_clkfb),
//    .RST(mmcm_rst),
//    .PWRDWN(1'b0),
//    .CLKOUT0(clk_125mhz_mmcm_out),
//    .CLKOUT0B(),
//    .CLKOUT1(),
//    .CLKOUT1B(),
//    .CLKOUT2(),
//    .CLKOUT2B(),
//    .CLKOUT3(),
//    .CLKOUT3B(),
//    .CLKOUT4(),
//    .CLKOUT5(),
//    .CLKOUT6(),
//    .CLKFBOUT(mmcm_clkfb),
//    .CLKFBOUTB(),
//    .LOCKED(mmcm_locked)
//);

//BUFG
//clk_125mhz_bufg_inst (
//    .I(clk_125mhz_mmcm_out),
//    .O(clk_125mhz_int)
//);

//sync_reset #(
//    .N(4)
//)
//sync_reset_125mhz_inst (
//    .clk(clk_125mhz_int),
//    .rst(~mmcm_locked),
//    .out(rst_125mhz_int)
//);


// AXI INPUT-OUTPUT
wire [63:0] rx_fifo_udp_payload_axis_tdata_i;
wire [7:0] rx_fifo_udp_payload_axis_tkeep_i;
wire rx_fifo_udp_payload_axis_tvalid_i;
wire rx_fifo_udp_payload_axis_tready_i;
wire rx_fifo_udp_payload_axis_tlast_i;
wire rx_fifo_udp_payload_axis_tuser_i;

wire [63:0] tx_fifo_udp_payload_axis_tdata_i;
wire [7:0] tx_fifo_udp_payload_axis_tkeep_i;
wire tx_fifo_udp_payload_axis_tvalid_i;
wire tx_fifo_udp_payload_axis_tready_i;
wire tx_fifo_udp_payload_axis_tlast_i;
wire tx_fifo_udp_payload_axis_tuser_i;

// GPIO
wire btnu_int;
wire btnl_int;
wire btnd_int;
wire btnr_int;
wire btnc_int;
wire [7:0] sw_int;

debounce_switch #(
    .WIDTH(9),
    .N(8),
    .RATE(156000)
)
debounce_switch_inst (
    .clk(clk_156mhz_int),
    .rst(rst_156mhz_int),
    .in({btnu,
        btnl,
        btnd,
        btnr,
        btnc,
        sw}),
    .out({btnu_int,
        btnl_int,
        btnd_int,
        btnr_int,
        btnc_int,
        sw_int})
);

wire uart_rxd_int;
wire uart_rts_int;

sync_signal #(
    .WIDTH(2),
    .N(2)
)
sync_signal_inst (
    .clk(clk_156mhz_int),
    .in({uart_rxd, uart_rts}),
    .out({uart_rxd_int, uart_rts_int})
);

// XGMII 10G PHY
assign sfp0_tx_disable_b = 1'b1;
assign sfp1_tx_disable_b = 1'b1;
assign sfp2_tx_disable_b = 1'b1;
assign sfp3_tx_disable_b = 1'b1;

wire        sfp0_tx_clk_int;
wire        sfp0_tx_rst_int;
wire [63:0] sfp0_txd_int;
wire [7:0]  sfp0_txc_int;
wire        sfp0_rx_clk_int;
wire        sfp0_rx_rst_int;
wire [63:0] sfp0_rxd_int;
wire [7:0]  sfp0_rxc_int;

wire        sfp1_tx_clk_int;
wire        sfp1_tx_rst_int;
wire [63:0] sfp1_txd_int;
wire [7:0]  sfp1_txc_int;
wire        sfp1_rx_clk_int;
wire        sfp1_rx_rst_int;
wire [63:0] sfp1_rxd_int;
wire [7:0]  sfp1_rxc_int;

wire        sfp2_tx_clk_int;
wire        sfp2_tx_rst_int;
wire [63:0] sfp2_txd_int;
wire [7:0]  sfp2_txc_int;
wire        sfp2_rx_clk_int;
wire        sfp2_rx_rst_int;
wire [63:0] sfp2_rxd_int;
wire [7:0]  sfp2_rxc_int;

wire        sfp3_tx_clk_int;
wire        sfp3_tx_rst_int;
wire [63:0] sfp3_txd_int;
wire [7:0]  sfp3_txc_int;
wire        sfp3_rx_clk_int;
wire        sfp3_rx_rst_int;
wire [63:0] sfp3_rxd_int;
wire [7:0]  sfp3_rxc_int;

assign clk_156mhz_int = sfp0_tx_clk_int;
assign rst_156mhz_int = sfp0_tx_rst_int;

assign clk_125mhz_int=clk_125mhz;
assign rst_125mhz_int=rst_125mhz;

wire sfp0_rx_block_lock;
wire sfp1_rx_block_lock;
wire sfp2_rx_block_lock;
wire sfp3_rx_block_lock;

wire sfp_mgt_refclk_0;

IBUFDS_GTE4 ibufds_gte4_sfp_mgt_refclk_0_inst (
    .I     (sfp_mgt_refclk_0_p),
    .IB    (sfp_mgt_refclk_0_n),
    .CEB   (1'b0),
    .O     (sfp_mgt_refclk_0),
    .ODIV2 ()
);

wire sfp_qpll0lock;
wire sfp_qpll0outclk;
wire sfp_qpll0outrefclk;

eth_xcvr_phy_wrapper #(
    .HAS_COMMON(1)
)
sfp0_phy_inst (
    .xcvr_ctrl_clk(clk_125mhz_int),
    .xcvr_ctrl_rst(rst_125mhz_int),

    // Common
    .xcvr_gtpowergood_out(),

    // PLL out
    .xcvr_gtrefclk00_in(sfp_mgt_refclk_0),
    .xcvr_qpll0lock_out(sfp_qpll0lock),
    .xcvr_qpll0outclk_out(sfp_qpll0outclk),
    .xcvr_qpll0outrefclk_out(sfp_qpll0outrefclk),

    // PLL in
    .xcvr_qpll0lock_in(1'b0),
    .xcvr_qpll0reset_out(),
    .xcvr_qpll0clk_in(1'b0),
    .xcvr_qpll0refclk_in(1'b0),

    // Serial data
    .xcvr_txp(sfp0_tx_p),
    .xcvr_txn(sfp0_tx_n),
    .xcvr_rxp(sfp0_rx_p),
    .xcvr_rxn(sfp0_rx_n),

    // PHY connections
    .phy_tx_clk(sfp0_tx_clk_int),
    .phy_tx_rst(sfp0_tx_rst_int),
    .phy_xgmii_txd(sfp0_txd_int),
    .phy_xgmii_txc(sfp0_txc_int),
    .phy_rx_clk(sfp0_rx_clk_int),
    .phy_rx_rst(sfp0_rx_rst_int),
    .phy_xgmii_rxd(sfp0_rxd_int),
    .phy_xgmii_rxc(sfp0_rxc_int),
    .phy_tx_bad_block(),
    .phy_rx_error_count(),
    .phy_rx_bad_block(),
    .phy_rx_sequence_error(),
    .phy_rx_block_lock(sfp0_rx_block_lock),
    .phy_rx_high_ber(),
    .phy_tx_prbs31_enable(),
    .phy_rx_prbs31_enable()
);

eth_xcvr_phy_wrapper #(
    .HAS_COMMON(0)
)
sfp1_phy_inst (
    .xcvr_ctrl_clk(clk_125mhz_int),
    .xcvr_ctrl_rst(rst_125mhz_int),

    // Common
    .xcvr_gtpowergood_out(),

    // PLL out
    .xcvr_gtrefclk00_in(1'b0),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0outclk_out(),
    .xcvr_qpll0outrefclk_out(),

    // PLL in
    .xcvr_qpll0lock_in(sfp_qpll0lock),
    .xcvr_qpll0reset_out(),
    .xcvr_qpll0clk_in(sfp_qpll0outclk),
    .xcvr_qpll0refclk_in(sfp_qpll0outrefclk),

    // Serial data
    .xcvr_txp(sfp1_tx_p),
    .xcvr_txn(sfp1_tx_n),
    .xcvr_rxp(sfp1_rx_p),
    .xcvr_rxn(sfp1_rx_n),

    // PHY connections
    .phy_tx_clk(sfp1_tx_clk_int),
    .phy_tx_rst(sfp1_tx_rst_int),
    .phy_xgmii_txd(sfp1_txd_int),
    .phy_xgmii_txc(sfp1_txc_int),
    .phy_rx_clk(sfp1_rx_clk_int),
    .phy_rx_rst(sfp1_rx_rst_int),
    .phy_xgmii_rxd(sfp1_rxd_int),
    .phy_xgmii_rxc(sfp1_rxc_int),
    .phy_tx_bad_block(),
    .phy_rx_error_count(),
    .phy_rx_bad_block(),
    .phy_rx_sequence_error(),
    .phy_rx_block_lock(sfp1_rx_block_lock),
    .phy_rx_high_ber(),
    .phy_tx_prbs31_enable(),
    .phy_rx_prbs31_enable()
);

eth_xcvr_phy_wrapper #(
    .HAS_COMMON(0)
)
sfp2_phy_inst (
    .xcvr_ctrl_clk(clk_125mhz_int),
    .xcvr_ctrl_rst(rst_125mhz_int),

    // Common
    .xcvr_gtpowergood_out(),

    // PLL out
    .xcvr_gtrefclk00_in(1'b0),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0outclk_out(),
    .xcvr_qpll0outrefclk_out(),

    // PLL in
    .xcvr_qpll0lock_in(sfp_qpll0lock),
    .xcvr_qpll0reset_out(),
    .xcvr_qpll0clk_in(sfp_qpll0outclk),
    .xcvr_qpll0refclk_in(sfp_qpll0outrefclk),

    // Serial data
    .xcvr_txp(sfp2_tx_p),
    .xcvr_txn(sfp2_tx_n),
    .xcvr_rxp(sfp2_rx_p),
    .xcvr_rxn(sfp2_rx_n),

    // PHY connections
    .phy_tx_clk(sfp2_tx_clk_int),
    .phy_tx_rst(sfp2_tx_rst_int),
    .phy_xgmii_txd(sfp2_txd_int),
    .phy_xgmii_txc(sfp2_txc_int),
    .phy_rx_clk(sfp2_rx_clk_int),
    .phy_rx_rst(sfp2_rx_rst_int),
    .phy_xgmii_rxd(sfp2_rxd_int),
    .phy_xgmii_rxc(sfp2_rxc_int),
    .phy_tx_bad_block(),
    .phy_rx_error_count(),
    .phy_rx_bad_block(),
    .phy_rx_sequence_error(),
    .phy_rx_block_lock(sfp2_rx_block_lock),
    .phy_rx_high_ber(),
    .phy_tx_prbs31_enable(),
    .phy_rx_prbs31_enable()
);

eth_xcvr_phy_wrapper #(
    .HAS_COMMON(0)
)
sfp3_phy_inst (
    .xcvr_ctrl_clk(clk_125mhz_int),
    .xcvr_ctrl_rst(rst_125mhz_int),

    // Common
    .xcvr_gtpowergood_out(),

    // PLL out
    .xcvr_gtrefclk00_in(1'b0),
    .xcvr_qpll0lock_out(),
    .xcvr_qpll0outclk_out(),
    .xcvr_qpll0outrefclk_out(),

    // PLL in
    .xcvr_qpll0lock_in(sfp_qpll0lock),
    .xcvr_qpll0reset_out(),
    .xcvr_qpll0clk_in(sfp_qpll0outclk),
    .xcvr_qpll0refclk_in(sfp_qpll0outrefclk),

    // Serial data
    .xcvr_txp(sfp3_tx_p),
    .xcvr_txn(sfp3_tx_n),
    .xcvr_rxp(sfp3_rx_p),
    .xcvr_rxn(sfp3_rx_n),

    // PHY connections
    .phy_tx_clk(sfp3_tx_clk_int),
    .phy_tx_rst(sfp3_tx_rst_int),
    .phy_xgmii_txd(sfp3_txd_int),
    .phy_xgmii_txc(sfp3_txc_int),
    .phy_rx_clk(sfp3_rx_clk_int),
    .phy_rx_rst(sfp3_rx_rst_int),
    .phy_xgmii_rxd(sfp3_rxd_int),
    .phy_xgmii_rxc(sfp3_rxc_int),
    .phy_tx_bad_block(),
    .phy_rx_error_count(),
    .phy_rx_bad_block(),
    .phy_rx_sequence_error(),
    .phy_rx_block_lock(sfp3_rx_block_lock),
    .phy_rx_high_ber(),
    .phy_tx_prbs31_enable(),
    .phy_rx_prbs31_enable()
);

fpga_core
core_inst (
    /*
     * Clock: 156.25 MHz
     * Synchronous reset
     */
    .clk(clk_156mhz_int),
    .rst(rst_156mhz_int),

    .local_mac_user(local_mac_user),
    .local_ip_user(local_ip_user),
    .server_ip_user(server_ip_user),
    .gateway_ip_user(gateway_ip_user),
    .subnet_mask_user(subnet_mask_user),
    .udp_port_user(udp_port_user),
    .udp_length_user(udp_length_user), // 1032
    .udp_hdr_valid_user(udp_hdr_valid_user),
    /*
     * GPIO
     */
    .btnu(btnu_int),
    .btnl(btnl_int),
    .btnd(btnd_int),
    .btnr(btnr_int),
    .btnc(btnc_int),
    .sw(sw_int),
    .led(led),
    /*
     * UART: 115200 bps, 8N1
     */
    .uart_rxd(uart_rxd_int),
    .uart_txd(uart_txd),
    .uart_rts(uart_rts_int),
    .uart_cts(uart_cts),
    /*
     * Ethernet: SFP+
     */
    .sfp0_tx_clk(sfp0_tx_clk_int),
    .sfp0_tx_rst(sfp0_tx_rst_int),
    .sfp0_txd(sfp0_txd_int),
    .sfp0_txc(sfp0_txc_int),
    .sfp0_rx_clk(sfp0_rx_clk_int),
    .sfp0_rx_rst(sfp0_rx_rst_int),
    .sfp0_rxd(sfp0_rxd_int),
    .sfp0_rxc(sfp0_rxc_int),
    .sfp1_tx_clk(sfp1_tx_clk_int),
    .sfp1_tx_rst(sfp1_tx_rst_int),
    .sfp1_txd(sfp1_txd_int),
    .sfp1_txc(sfp1_txc_int),
    .sfp1_rx_clk(sfp1_rx_clk_int),
    .sfp1_rx_rst(sfp1_rx_rst_int),
    .sfp1_rxd(sfp1_rxd_int),
    .sfp1_rxc(sfp1_rxc_int),
    .sfp2_tx_clk(sfp2_tx_clk_int),
    .sfp2_tx_rst(sfp2_tx_rst_int),
    .sfp2_txd(sfp2_txd_int),
    .sfp2_txc(sfp2_txc_int),
    .sfp2_rx_clk(sfp2_rx_clk_int),
    .sfp2_rx_rst(sfp2_rx_rst_int),
    .sfp2_rxd(sfp2_rxd_int),
    .sfp2_rxc(sfp2_rxc_int),
    .sfp3_tx_clk(sfp3_tx_clk_int),
    .sfp3_tx_rst(sfp3_tx_rst_int),
    .sfp3_txd(sfp3_txd_int),
    .sfp3_txc(sfp3_txc_int),
    .sfp3_rx_clk(sfp3_rx_clk_int),
    .sfp3_rx_rst(sfp3_rx_rst_int),
    .sfp3_rxd(sfp3_rxd_int),
    .sfp3_rxc(sfp3_rxc_int),
    .rx_fifo_udp_payload_axis_tdata(rx_fifo_udp_payload_axis_tdata_i),
    .rx_fifo_udp_payload_axis_tkeep(rx_fifo_udp_payload_axis_tkeep_i),
    .rx_fifo_udp_payload_axis_tvalid(rx_fifo_udp_payload_axis_tvalid_i),
    .rx_fifo_udp_payload_axis_tready(rx_fifo_udp_payload_axis_tready_i),
    .rx_fifo_udp_payload_axis_tlast(rx_fifo_udp_payload_axis_tlast_i),
    .rx_fifo_udp_payload_axis_tuser(rx_fifo_udp_payload_axis_tuser_i),
    
    .tx_fifo_udp_payload_axis_tdata(tx_fifo_udp_payload_axis_tdata_i),
    .tx_fifo_udp_payload_axis_tkeep(tx_fifo_udp_payload_axis_tkeep_i),
    .tx_fifo_udp_payload_axis_tvalid(tx_fifo_udp_payload_axis_tvalid_i),
    .tx_fifo_udp_payload_axis_tready(tx_fifo_udp_payload_axis_tready_i),
    .tx_fifo_udp_payload_axis_tlast(tx_fifo_udp_payload_axis_tlast_i),
    .tx_fifo_udp_payload_axis_tuser(tx_fifo_udp_payload_axis_tuser_i)
);


assign tx_fifo_udp_payload_axis_tdata_i = tx_fifo_udp_payload_axis_tdata;
assign tx_fifo_udp_payload_axis_tkeep_i = tx_fifo_udp_payload_axis_tkeep;
assign tx_fifo_udp_payload_axis_tvalid_i = tx_fifo_udp_payload_axis_tvalid;
assign tx_fifo_udp_payload_axis_tready = tx_fifo_udp_payload_axis_tready_i;
assign tx_fifo_udp_payload_axis_tlast_i = tx_fifo_udp_payload_axis_tlast;
assign tx_fifo_udp_payload_axis_tuser_i = tx_fifo_udp_payload_axis_tuser;

assign rx_fifo_udp_payload_axis_tdata = rx_fifo_udp_payload_axis_tdata_i;
assign rx_fifo_udp_payload_axis_tkeep = rx_fifo_udp_payload_axis_tkeep_i;
assign rx_fifo_udp_payload_axis_tvalid = rx_fifo_udp_payload_axis_tvalid_i;
assign rx_fifo_udp_payload_axis_tready_i = rx_fifo_udp_payload_axis_tready;
assign rx_fifo_udp_payload_axis_tlast = rx_fifo_udp_payload_axis_tlast_i;
assign rx_fifo_udp_payload_axis_tuser = rx_fifo_udp_payload_axis_tuser_i;

assign fifo_clk_156mhz=clk_156mhz_int;
assign fifo_clk_rst_156mhz=rst_156mhz_int;

endmodule

`resetall
