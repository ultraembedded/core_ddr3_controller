//-----------------------------------------------------------------
// TOP
//-----------------------------------------------------------------
module top
(
     input          clk

    ,output [14:0]  ddram_a
    ,output [2:0]   ddram_ba
    ,output         ddram_ras_n
    ,output         ddram_cas_n
    ,output         ddram_we_n
    ,output [1:0]   ddram_dm
    ,inout [15:0]   ddram_dq
    ,inout [1:0]    ddram_dqs_p
    ,output         ddram_clk_p
    ,output         ddram_cke
    ,output         ddram_odt
);

//-----------------------------------------------------------------
// Clocking / Reset
//-----------------------------------------------------------------
wire [3:0] clk_pll_w;

ecp5pll
#(
   .in_hz(100000000)
  ,.out0_hz(50000000)
  ,.out1_hz(50000000)
  ,.out1_deg(90)
)
u_pll
(
     .clk_i(clk)
    ,.clk_o(clk_pll_w)
    ,.reset(1'b0)
    ,.standby(1'b0)
    ,.phasesel(2'b0)
    ,.phasedir(1'b0) 
    ,.phasestep(1'b0)
    ,.phaseloadreg(1'b0)
    ,.locked()
);

wire clk_w;
wire clk_ddr_w;
wire rst_w;

assign clk_w     = clk_pll_w[0]; // 50MHz
assign clk_ddr_w = clk_pll_w[1]; // 50MHz (90 degree phase shift)

reset_gen
u_rst
(
     .clk_i(clk_w)
    ,.rst_o(rst_w)
);

//-----------------------------------------------------------------
// DDR Core + PHY
//-----------------------------------------------------------------
wire [ 14:0]   dfi_address_w;
wire [  2:0]   dfi_bank_w;
wire           dfi_cas_n_w;
wire           dfi_cke_w;
wire           dfi_cs_n_w;
wire           dfi_odt_w;
wire           dfi_ras_n_w;
wire           dfi_reset_n_w;
wire           dfi_we_n_w;
wire [ 31:0]   dfi_wrdata_w;
wire           dfi_wrdata_en_w;
wire [  3:0]   dfi_wrdata_mask_w;
wire           dfi_rddata_en_w;
wire [ 31:0]   dfi_rddata_w;
wire           dfi_rddata_valid_w;
wire [  1:0]   dfi_rddata_dnv_w;

wire           axi4_awready_w;
wire           axi4_arready_w;
wire  [  7:0]  axi4_arlen_w;
wire           axi4_wvalid_w;
wire  [ 31:0]  axi4_araddr_w;
wire  [  1:0]  axi4_bresp_w;
wire  [ 31:0]  axi4_wdata_w;
wire           axi4_rlast_w;
wire           axi4_awvalid_w;
wire  [  3:0]  axi4_rid_w;
wire  [  1:0]  axi4_rresp_w;
wire           axi4_bvalid_w;
wire  [  3:0]  axi4_wstrb_w;
wire  [  1:0]  axi4_arburst_w;
wire           axi4_arvalid_w;
wire  [  3:0]  axi4_awid_w;
wire  [  3:0]  axi4_bid_w;
wire  [  3:0]  axi4_arid_w;
wire           axi4_rready_w;
wire  [  7:0]  axi4_awlen_w;
wire           axi4_wlast_w;
wire  [ 31:0]  axi4_rdata_w;
wire           axi4_bready_w;
wire  [ 31:0]  axi4_awaddr_w;
wire           axi4_wready_w;
wire  [  1:0]  axi4_awburst_w;
wire           axi4_rvalid_w;

ddr3_axi
#(
     .DDR_WRITE_LATENCY(3)
    ,.DDR_READ_LATENCY(3)
    ,.DDR_MHZ(50)
)
u_ddr
(
    // Inputs
     .clk_i(clk_w)
    ,.rst_i(rst_w)
    ,.inport_awvalid_i(axi4_awvalid_w)
    ,.inport_awaddr_i(axi4_awaddr_w)
    ,.inport_awid_i(axi4_awid_w)
    ,.inport_awlen_i(axi4_awlen_w)
    ,.inport_awburst_i(axi4_awburst_w)
    ,.inport_wvalid_i(axi4_wvalid_w)
    ,.inport_wdata_i(axi4_wdata_w)
    ,.inport_wstrb_i(axi4_wstrb_w)
    ,.inport_wlast_i(axi4_wlast_w)
    ,.inport_bready_i(axi4_bready_w)
    ,.inport_arvalid_i(axi4_arvalid_w)
    ,.inport_araddr_i(axi4_araddr_w)
    ,.inport_arid_i(axi4_arid_w)
    ,.inport_arlen_i(axi4_arlen_w)
    ,.inport_arburst_i(axi4_arburst_w)
    ,.inport_rready_i(axi4_rready_w)
    ,.dfi_rddata_i(dfi_rddata_w)
    ,.dfi_rddata_valid_i(dfi_rddata_valid_w)
    ,.dfi_rddata_dnv_i(dfi_rddata_dnv_w)

    // Outputs
    ,.inport_awready_o(axi4_awready_w)
    ,.inport_wready_o(axi4_wready_w)
    ,.inport_bvalid_o(axi4_bvalid_w)
    ,.inport_bresp_o(axi4_bresp_w)
    ,.inport_bid_o(axi4_bid_w)
    ,.inport_arready_o(axi4_arready_w)
    ,.inport_rvalid_o(axi4_rvalid_w)
    ,.inport_rdata_o(axi4_rdata_w)
    ,.inport_rresp_o(axi4_rresp_w)
    ,.inport_rid_o(axi4_rid_w)
    ,.inport_rlast_o(axi4_rlast_w)
    ,.dfi_address_o(dfi_address_o)
    ,.dfi_bank_o(dfi_bank_w)
    ,.dfi_cas_n_o(dfi_cas_n_w)
    ,.dfi_cke_o(dfi_cke_w)
    ,.dfi_cs_n_o(dfi_cs_n_w)
    ,.dfi_odt_o(dfi_odt_w)
    ,.dfi_ras_n_o(dfi_ras_n_w)
    ,.dfi_reset_n_o(dfi_reset_n_w)
    ,.dfi_we_n_o(dfi_we_n_w)
    ,.dfi_wrdata_o(dfi_wrdata_w)
    ,.dfi_wrdata_en_o(dfi_wrdata_en_w)
    ,.dfi_wrdata_mask_o(dfi_wrdata_mask_w)
    ,.dfi_rddata_en_o(dfi_rddata_en_w)
);

ddr3_dfi_phy
u_phy
(
     .clk_i(clk_w)
    ,.rst_i(rst_w)

    ,.clk_ddr_i(clk_ddr_w)

    ,.dfi_address_i(dfi_address_w)
    ,.dfi_bank_i(dfi_bank_w)
    ,.dfi_cas_n_i(dfi_cas_n_w)
    ,.dfi_cke_i(dfi_cke_w)
    ,.dfi_cs_n_i(dfi_cs_n_w)
    ,.dfi_odt_i(dfi_odt_w)
    ,.dfi_ras_n_i(dfi_ras_n_w)
    ,.dfi_reset_n_i(dfi_reset_n_w)
    ,.dfi_we_n_i(dfi_we_n_w)
    ,.dfi_wrdata_i(dfi_wrdata_w)
    ,.dfi_wrdata_en_i(dfi_wrdata_en_w)
    ,.dfi_wrdata_mask_i(dfi_wrdata_mask_w)
    ,.dfi_rddata_en_i(dfi_rddata_en_w)
    ,.dfi_rddata_o(dfi_rddata_w)
    ,.dfi_rddata_valid_o(dfi_rddata_valid_w)
    ,.dfi_rddata_dnv_o(dfi_rddata_dnv_w)
    
    ,.ddr3_ck_p_o(ddram_clk_p)
    ,.ddr3_cke_o(ddram_cke)
    ,.ddr3_reset_n_o()
    ,.ddr3_ras_n_o(ddram_ras_n)
    ,.ddr3_cas_n_o(ddram_cas_n)
    ,.ddr3_we_n_o(ddram_we_n)
    ,.ddr3_cs_n_o()
    ,.ddr3_ba_o(ddram_ba)
    ,.ddr3_addr_o(ddram_a)
    ,.ddr3_odt_o(ddram_odt)
    ,.ddr3_dm_o(ddram_dm)
    ,.ddr3_dqs_p_io(ddram_dqs_p)
    ,.ddr3_dq_io(ddram_dq)
);

//-----------------------------------------------------------------
// User design
//-----------------------------------------------------------------

...

endmodule
