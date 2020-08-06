/*
Based in the netfpga sume example of 
Alex Forencich, we use this cores
https://github.com/alexforencich/verilog-ethernet

kudos to him and his work!

We use the xilinx pcs/pma core to generate 10gbase-r phy
*/

`timescale 1ns / 1ps

/*
 *  Top level module   
 */

module fpga(
    /*
     * Clock 100MHz CMOS25
     */
    input   wire            clk_100,
    
    /*
     *  GPIO
     */
    input   wire            btn1,
    input   wire    [3:0]   leds,

    /*
     *  Ethernet SFP+
     */
    input   wire            sfp_a_rx_p,
    input   wire            sfp_a_rx_n,
    input   wire            sfp_a_tx_p,
    input   wire            sfp_a_tx_n,
    
    output  wire            sfp_a_tx_disable,
    output  wire            sfp_a_rate,

    input   wire            sfp_b_rx_p,
    input   wire            sfp_b_rx_n,
    input   wire            sfp_b_tx_p,
    input   wire            sfp_b_tx_n,
    
    output  wire            sfp_b_tx_disable,
    output  wire            sfp_b_rate,
    
    //156.25 LVDS clock 
    input   wire            sfp_mgt_refclk_p,
    input   wire            sfp_mgt_refclk_n,
    
    output  wire            sfp_clk_rst,

    //payload received    
    output  wire    [63:0]  udp_rx_payload_tdata,
    output  wire            udp_rx_payload_tvalid,
    output  wire            udp_rx_payload_tlast
    /* The example of alex uses also i2c porst to enable the transmition, 
     * also there are the following extra sfp+ pins:
     * - sfp_1_mod_detect --> 1 if there are no sfp in the module host
     *                        alex doesnt use it            
     * - sfp_1_tx_fault   --> 0 is normal operation
     *                        alex doesnt use it
     * - sfp_1_rs [1:0]   --> rate selection (in the sume the module are qsfp)
     *                        alex set it to 1'b1
     * - sfp_1_los        --> 0 normal operation
     *                        alex doesnt use it
     * the example with the board doesnt use them, so I assume they are
     * hardwire to the good values
     */
);

    wire clk_100mhz_ibufg;
    
    wire clk_125mhz_mmcm_out;
    
    // internal 125 mhz clock
    wire clk_125mhz_int;
    wire rst_125mhz_int;

    // Internal 156.25 MHz clock
    wire clk_156mhz_int;
    wire rst_156mhz_int;

    wire mmcm_rst = 1'b0;
    wire mmcm_locked;
    wire mmcm_clkfb; 

    IBUFG clk_ibufg_inst(
        .I(clk_100),
        .O(clk_100mhz_ibufg)
    );

    //MMCM instance
    //100mhz in 125 out
    //kintex mmcm vco range (600-1200)mhz
    //max pfd 450
    //fvco = fin*M/D; fout=fin*M/(D*O)
    //M=10, D=1 --> fvco=1000
    //divided by 8 to get 125mhz
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKOUT0_DIVIDE_F(8),
        .CLKOUT0_DUTY_CYCLE(0.5),
        .CLKOUT0_PHASE(0),
        .CLKOUT1_DIVIDE(1),
        .CLKOUT1_DUTY_CYCLE(0.5),
        .CLKOUT1_PHASE(0),
        .CLKOUT2_DIVIDE(1),
        .CLKOUT2_DUTY_CYCLE(0.5),
        .CLKOUT2_PHASE(0),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT3_DUTY_CYCLE(0.5),
        .CLKOUT3_PHASE(0),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT4_DUTY_CYCLE(0.5),
        .CLKOUT4_PHASE(0),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT5_DUTY_CYCLE(0.5),
        .CLKOUT5_PHASE(0),
        .CLKOUT6_DIVIDE(1),
        .CLKOUT6_DUTY_CYCLE(0.5),
        .CLKOUT6_PHASE(0),
        .CLKFBOUT_MULT_F(10),
        .CLKFBOUT_PHASE(0),
        .DIVCLK_DIVIDE(1),
        .REF_JITTER1(0.010),
        .CLKIN1_PERIOD(10.0),
        .STARTUP_WAIT("FALSE"),
        .CLKOUT4_CASCADE("FALSE")
    ) clk_mmcm_inst (
        .CLKIN1(clk_100mhz_ibufg),
        .CLKFBIN(mmcm_clkfb),
        .RST(mmcm_rst),
        .PWRDWN(1'b0),
        .CLKOUT0(clk_125mhz_mmcm_out),
        .CLKOUT0B(),
        .CLKOUT1(),
        .CLKOUT1B(),
        .CLKOUT2(),
        .CLKOUT2B(),
        .CLKOUT3(),
        .CLKOUT3B(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),
        .CLKFBOUT(mmcm_clkfb),
        .CLKFBOUTB(),
        .LOCKED(mmcm_locked)
    );
    
    BUFG clk_125mhz_bufg_inst (
        .I(clk_125mhz_mmcm_out),
        .O(clk_125mhz_int)
    );

    //synchronizer with a 4 pipelined registers for the reset
    sync_reset #(
        .N(4)
    ) sync_reset_125mhz_inst (
        .clk(clk_125mhz_int),
        .rst(~mmcm_locked),
        .out(rst_125mhz_int)
    );

    //GPIO

    wire btn_int;
    wire sfp_a_led_int;
    wire sfp_b_led_int;
    wire led_int;

    debounce_switch #(
        .WIDTH(1),
        .N(4),
        .RATE(156250)
        )
    debounce_switch_inst (
            .clk(clk_156mhz_int),
            .rst(rst_156mhz_int),
            .in({btn1}),
        .   out({btn_int})
        );
    
    
    assign sfp_clk_rst = rst_125mhz_int;
    

    //XGMII 10G PHY
    
    assign sfp_a_tx_disable = 1'b0;
    assign sfp_b_tx_disable = 1'b0;
    assign sfp_a_rate = 1'b1;
    assign sfp_b_rate = 1'b1;

    wire        sfp_a_tx_clk_int = clk_156mhz_int;
    wire        sfp_a_tx_rst_int = rst_156mhz_int;
    wire [63:0] sfp_a_txd_int;
    wire [7:0]  sfp_a_txc_int;
    wire        sfp_a_rx_clk_int = clk_156mhz_int;
    wire        sfp_a_rx_rst_int = rst_156mhz_int;
    wire [63:0] sfp_a_rxd_int;
    wire [7:0]  sfp_a_rxc_int;
    wire        sfp_b_tx_clk_int = clk_156mhz_int;
    wire        sfp_b_tx_rst_int = rst_156mhz_int;
    wire [63:0] sfp_b_txd_int;
    wire [7:0]  sfp_b_txc_int;
    wire        sfp_b_rx_clk_int = clk_156mhz_int;
    wire        sfp_b_rx_rst_int = rst_156mhz_int;
    wire [63:0] sfp_b_rxd_int;
    wire [7:0]  sfp_b_rxc_int;

    //pcs-pma ports

    wire sfp_reset_in;
    wire sfp_txusrclk;
    wire sfp_txusrclk2;
    wire sfp_coreclk;
    wire sfp_qplloutclk;
    wire sfp_qplloutrefclk;
    wire sfp_qplllock;
    wire sfp_gttxreset;
    wire sfp_gtrxreset;
    wire sfp_txuserrdy;
    wire sfp_areset_datapathclk;
    wire sfp_resetdone;
    wire sfp_reset_counter_done;


    sync_reset #(
    .N(4)
    )
    sync_reset_sfp_inst (
        .clk(sfp_coreclk),
        .rst(rst_125mhz_int),
        .out(sfp_reset_in)
    );

    assign clk_156mhz_int = sfp_coreclk;

    //configuration of the pcs/pma core
    wire [535:0] sfp_config_vector; 
    assign sfp_config_vector[14:1]    = 0;
    assign sfp_config_vector[79:17]   = 0;
    assign sfp_config_vector[109:84]  = 0;
    assign sfp_config_vector[175:170] = 0;
    assign sfp_config_vector[239:234] = 0;
    assign sfp_config_vector[269:246] = 0;
    assign sfp_config_vector[511:272] = 0;
    assign sfp_config_vector[515:513] = 0;
    assign sfp_config_vector[517:517] = 0;
    assign sfp_config_vector[0]       = 0; // pma_loopback;
    assign sfp_config_vector[15]      = 0; // pma_reset;
    assign sfp_config_vector[16]      = 0; // global_tx_disable;
    assign sfp_config_vector[83:80]   = 0; // pma_vs_loopback;
    assign sfp_config_vector[110]     = 0; // pcs_loopback;
    assign sfp_config_vector[111]     = 0; // pcs_reset;
    assign sfp_config_vector[169:112] = 0; // test_patt_a;
    assign sfp_config_vector[233:176] = 0; // test_patt_b;
    assign sfp_config_vector[240]     = 0; // data_patt_sel;
    assign sfp_config_vector[241]     = 0; // test_patt_sel;
    assign sfp_config_vector[242]     = 0; // rx_test_patt_en;
    assign sfp_config_vector[243]     = 0; // tx_test_patt_en;
    assign sfp_config_vector[244]     = 0; // prbs31_tx_en;
    assign sfp_config_vector[245]     = 0; // prbs31_rx_en;
    assign sfp_config_vector[271:270] = 0; // pcs_vs_loopback;
    assign sfp_config_vector[512]     = 0; // set_pma_link_status;
    assign sfp_config_vector[516]     = 0; // set_pcs_link_status;
    assign sfp_config_vector[518]     = 0; // clear_pcs_status2;
    assign sfp_config_vector[519]     = 0; // clear_test_patt_err_count;
    assign sfp_config_vector[535:520] = 0;
    
        
    wire [447:0] sfp_a_status_vector;
    wire [447:0] sfp_b_status_vector;

    wire sfp_a_rx_block_lock = sfp_a_status_vector[256];
    wire sfp_b_rx_block_lock = sfp_b_status_vector[256];
    
    wire [7:0] sfp_a_core_status;
    wire [7:0] sfp_b_core_status;

    //generate two pcs/pma modules, the first one has the shared logic included
    //in the core option, so it generates the necessary clocks
   
    
    ten_gig_eth_pcs_pma_0 sfp_1_pcs_pma_inst (
        .dclk(clk_125mhz_int),
        .rxrecclk_out(),
        .refclk_p(sfp_mgt_refclk_p),
        .refclk_n(sfp_mgt_refclk_n),
        .sim_speedup_control(1'b0),
        .coreclk_out(sfp_coreclk),
        .qplloutclk_out(sfp_qplloutclk),
        .qplloutrefclk_out(sfp_qplloutrefclk),
        .qplllock_out(sfp_qplllock),
        .txusrclk_out(sfp_txusrclk),
        .txusrclk2_out(sfp_txusrclk2),
        .areset_datapathclk_out(sfp_areset_datapathclk),
        .gttxreset_out(sfp_gttxreset),
        .gtrxreset_out(sfp_gtrxreset),
        .txuserrdy_out(sfp_txuserrdy),
        .reset_counter_done_out(sfp_reset_counter_done),
        .reset(sfp_reset_in),
        .xgmii_txd(sfp_a_txd_int),
        .xgmii_txc(sfp_a_txc_int),
        .xgmii_rxd(sfp_a_rxd_int),
        .xgmii_rxc(sfp_a_rxc_int),
        .txp(sfp_a_tx_p),
        .txn(sfp_a_tx_n),
        .rxp(sfp_a_rx_p),
        .rxn(sfp_a_rx_n),
        .configuration_vector(sfp_config_vector),
        .status_vector(sfp_a_status_vector),
        .core_status(sfp_a_core_status),
        .resetdone_out(sfp_resetdone),
        .signal_detect(1'b1),
        .tx_fault(1'b0),
        .drp_req(),
        .drp_gnt(1'b1),
        .drp_den_o(),
        .drp_dwe_o(),
        .drp_daddr_o(),
        .drp_di_o(),
        .drp_drdy_o(),
        .drp_drpdo_o(),
        .drp_den_i(1'b0),
        .drp_dwe_i(1'b0),
        .drp_daddr_i(16'd0),
        .drp_di_i(16'd0),
        .drp_drdy_i(1'b0),
        .drp_drpdo_i(16'd0),
        .pma_pmd_type(3'd0),
        .tx_disable()
    );

        
    ten_gig_eth_pcs_pma_1 sfp_2_pcs_pma_inst (
        .dclk(clk_125mhz_int),
        .rxrecclk_out(),
        .coreclk(sfp_coreclk),
        .txusrclk(sfp_txusrclk),
        .txusrclk2(sfp_txusrclk2),
        .txoutclk(),
        .areset(sfp_reset_in),
        .areset_coreclk(sfp_areset_datapathclk),
        .gttxreset(sfp_gttxreset),
        .gtrxreset(sfp_gtrxreset),
        .sim_speedup_control(1'b0),
        .txuserrdy(sfp_txuserrdy),
        .qplllock(sfp_qplllock),
        .qplloutclk(sfp_qplloutclk),
        .qplloutrefclk(sfp_qplloutrefclk),
        .reset_counter_done(sfp_reset_counter_done),
        .xgmii_txd(sfp_b_txd_int),
        .xgmii_txc(sfp_b_txc_int),
        .xgmii_rxd(sfp_b_rxd_int),
        .xgmii_rxc(sfp_b_rxc_int),
        .txp(sfp_b_tx_p),
        .txn(sfp_b_tx_n),
        .rxp(sfp_b_rx_p),
        .rxn(sfp_b_rx_n),
        .configuration_vector(sfp_config_vector),
        .status_vector(sfp_b_status_vector),
        .core_status(sfp_b_core_status),
        .tx_resetdone(),
        .rx_resetdone(),
        .signal_detect(1'b1),
        .tx_fault(1'b0),
        .drp_req(),
        .drp_gnt(1'b1),
        .drp_den_o(),
        .drp_dwe_o(),
        .drp_daddr_o(),
        .drp_di_o(),
        .drp_drdy_o(),
        .drp_drpdo_o(),
        .drp_den_i(1'b0),
        .drp_dwe_i(1'b0),
        .drp_daddr_i(16'd0),
        .drp_di_i(16'd0),
        .drp_drdy_i(1'b0),
        .drp_drpdo_i(16'd0),
        .pma_pmd_type(3'd0),
        .tx_disable()
    );




    assign leds[0] = sfp_a_rx_block_lock;
    assign leds[1] = sfp_a_rx_block_lock;
    assign leds[2] = led_int;

    fpga_core
    core_inst(
        /*
         * Clock: 156.25 MHz
         * Synchronous reset
         */
        .clk(clk_156mhz_int),
        .rst(rst_156mhz_int),
        /*
         * GPIO
         */
        .btn({1'b0, btn_int}),
        .sfp_1_led({1'b0, sfp_1_led_int}),
        .sfp_2_led({1'b0, sfp_2_led_int}),
        .led({1'b0, led_int}),
        /*
         * Ethernet: SFP+
         */
        .sfp_1_tx_clk(sfp_a_tx_clk_int),
        .sfp_1_tx_rst(sfp_a_tx_rst_int),
        .sfp_1_txd(sfp_a_txd_int),
        .sfp_1_txc(sfp_a_txc_int),
        .sfp_1_rx_clk(sfp_a_rx_clk_int),
        .sfp_1_rx_rst(sfp_a_rx_rst_int),
        .sfp_1_rxd(sfp_a_rxd_int),
        .sfp_1_rxc(sfp_a_rxc_int),
        .sfp_2_tx_clk(sfp_b_tx_clk_int),
        .sfp_2_tx_rst(sfp_b_tx_rst_int),
        .sfp_2_txd(sfp_b_txd_int),
        .sfp_2_txc(sfp_b_txc_int),
        .sfp_2_rx_clk(sfp_b_rx_clk_int),
        .sfp_2_rx_rst(sfp_b_rx_rst_int),
        .sfp_2_rxd(sfp_b_rxd_int),
        .sfp_2_rxc(sfp_b_rxc_int),
        .udp_rx_payload_tdata(udp_rx_payload_tdata),
        .udp_rx_payload_tvalid(udp_rx_payload_tvalid),
        .udp_rx_payload_tlast(udp_rx_payload_tlast)
    );

endmodule