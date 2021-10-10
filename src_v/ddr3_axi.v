//-----------------------------------------------------------------
//              Lightweight DDR3 Memory Controller
//                            V0.5
//                     Ultra-Embedded.com
//                     Copyright 2020-21
//
//                   admin@ultra-embedded.com
//
//                     License: Apache 2.0
//-----------------------------------------------------------------
// Copyright 2020-21 Ultra-Embedded.com
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//-----------------------------------------------------------------

module ddr3_axi
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter DDR_MHZ          = 100
    ,parameter DDR_WRITE_LATENCY = 4
    ,parameter DDR_READ_LATENCY = 4
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           inport_awvalid_i
    ,input  [ 31:0]  inport_awaddr_i
    ,input  [  3:0]  inport_awid_i
    ,input  [  7:0]  inport_awlen_i
    ,input  [  1:0]  inport_awburst_i
    ,input           inport_wvalid_i
    ,input  [ 31:0]  inport_wdata_i
    ,input  [  3:0]  inport_wstrb_i
    ,input           inport_wlast_i
    ,input           inport_bready_i
    ,input           inport_arvalid_i
    ,input  [ 31:0]  inport_araddr_i
    ,input  [  3:0]  inport_arid_i
    ,input  [  7:0]  inport_arlen_i
    ,input  [  1:0]  inport_arburst_i
    ,input           inport_rready_i
    ,input  [ 31:0]  dfi_rddata_i
    ,input           dfi_rddata_valid_i
    ,input  [  1:0]  dfi_rddata_dnv_i

    // Outputs
    ,output          inport_awready_o
    ,output          inport_wready_o
    ,output          inport_bvalid_o
    ,output [  1:0]  inport_bresp_o
    ,output [  3:0]  inport_bid_o
    ,output          inport_arready_o
    ,output          inport_rvalid_o
    ,output [ 31:0]  inport_rdata_o
    ,output [  1:0]  inport_rresp_o
    ,output [  3:0]  inport_rid_o
    ,output          inport_rlast_o
    ,output [ 14:0]  dfi_address_o
    ,output [  2:0]  dfi_bank_o
    ,output          dfi_cas_n_o
    ,output          dfi_cke_o
    ,output          dfi_cs_n_o
    ,output          dfi_odt_o
    ,output          dfi_ras_n_o
    ,output          dfi_reset_n_o
    ,output          dfi_we_n_o
    ,output [ 31:0]  dfi_wrdata_o
    ,output          dfi_wrdata_en_o
    ,output [  3:0]  dfi_wrdata_mask_o
    ,output          dfi_rddata_en_o
);



//-----------------------------------------------------------------
// AXI Retiming Stage (optional)
//-----------------------------------------------------------------
wire          axi_awvalid_w;
wire [ 31:0]  axi_awaddr_w;
wire [  3:0]  axi_awid_w;
wire [  7:0]  axi_awlen_w;
wire [  1:0]  axi_awburst_w;
wire          axi_wvalid_w;
wire [ 31:0]  axi_wdata_w;
wire [  3:0]  axi_wstrb_w;
wire          axi_wlast_w;
wire          axi_bready_w;
wire          axi_arvalid_w;
wire [ 31:0]  axi_araddr_w;
wire [  3:0]  axi_arid_w;
wire [  7:0]  axi_arlen_w;
wire [  1:0]  axi_arburst_w;
wire          axi_rready_w;
wire          axi_awready_w;
wire          axi_wready_w;
wire          axi_bvalid_w;
wire [  1:0]  axi_bresp_w;
wire [  3:0]  axi_bid_w;
wire          axi_arready_w;
wire          axi_rvalid_w;
wire [ 31:0]  axi_rdata_w;
wire [  1:0]  axi_rresp_w;
wire [  3:0]  axi_rid_w;
wire          axi_rlast_w;

ddr3_axi_retime
#(
     .AXI4_RETIME_WR_REQ(0)
    ,.AXI4_RETIME_WR_RESP(0)
    ,.AXI4_RETIME_RD_REQ(0)
    ,.AXI4_RETIME_RD_RESP(0)
)
u_retime
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.inport_awvalid_i(inport_awvalid_i)
    ,.inport_awaddr_i(inport_awaddr_i)
    ,.inport_awid_i(inport_awid_i)
    ,.inport_awlen_i(inport_awlen_i)
    ,.inport_awburst_i(inport_awburst_i)
    ,.inport_wvalid_i(inport_wvalid_i)
    ,.inport_wdata_i(inport_wdata_i)
    ,.inport_wstrb_i(inport_wstrb_i)
    ,.inport_wlast_i(inport_wlast_i)
    ,.inport_bready_i(inport_bready_i)
    ,.inport_arvalid_i(inport_arvalid_i)
    ,.inport_araddr_i(inport_araddr_i)
    ,.inport_arid_i(inport_arid_i)
    ,.inport_arlen_i(inport_arlen_i)
    ,.inport_arburst_i(inport_arburst_i)
    ,.inport_rready_i(inport_rready_i)
    ,.inport_awready_o(inport_awready_o)
    ,.inport_wready_o(inport_wready_o)
    ,.inport_bvalid_o(inport_bvalid_o)
    ,.inport_bresp_o(inport_bresp_o)
    ,.inport_bid_o(inport_bid_o)
    ,.inport_arready_o(inport_arready_o)
    ,.inport_rvalid_o(inport_rvalid_o)
    ,.inport_rdata_o(inport_rdata_o)
    ,.inport_rresp_o(inport_rresp_o)
    ,.inport_rid_o(inport_rid_o)
    ,.inport_rlast_o(inport_rlast_o)

    ,.outport_awvalid_o(axi_awvalid_w)
    ,.outport_awaddr_o(axi_awaddr_w)
    ,.outport_awid_o(axi_awid_w)
    ,.outport_awlen_o(axi_awlen_w)
    ,.outport_awburst_o(axi_awburst_w)
    ,.outport_wvalid_o(axi_wvalid_w)
    ,.outport_wdata_o(axi_wdata_w)
    ,.outport_wstrb_o(axi_wstrb_w)
    ,.outport_wlast_o(axi_wlast_w)
    ,.outport_bready_o(axi_bready_w)
    ,.outport_arvalid_o(axi_arvalid_w)
    ,.outport_araddr_o(axi_araddr_w)
    ,.outport_arid_o(axi_arid_w)
    ,.outport_arlen_o(axi_arlen_w)
    ,.outport_arburst_o(axi_arburst_w)
    ,.outport_rready_o(axi_rready_w)
    ,.outport_awready_i(axi_awready_w)
    ,.outport_wready_i(axi_wready_w)
    ,.outport_bvalid_i(axi_bvalid_w)
    ,.outport_bresp_i(axi_bresp_w)
    ,.outport_bid_i(axi_bid_w)
    ,.outport_arready_i(axi_arready_w)
    ,.outport_rvalid_i(axi_rvalid_w)
    ,.outport_rdata_i(axi_rdata_w)
    ,.outport_rresp_i(axi_rresp_w)
    ,.outport_rid_i(axi_rid_w)
    ,.outport_rlast_i(axi_rlast_w)
);

//-----------------------------------------------------------------
// AXI Interface
//-----------------------------------------------------------------
wire [ 31:0]  ram_addr_w;
wire [ 15:0]  ram_wr_w;
wire          ram_rd_w;
wire          ram_accept_w;
wire [127:0]  ram_write_data_w;
wire [127:0]  ram_read_data_w;
wire [ 15:0]  ram_req_id_w;
wire [ 15:0]  ram_resp_id_w;
wire          ram_ack_w;
wire          ram_error_w;

ddr3_axi_pmem
u_axi
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // AXI port
    .axi_awvalid_i(axi_awvalid_w),
    .axi_awaddr_i(axi_awaddr_w),
    .axi_awid_i(axi_awid_w),
    .axi_awlen_i(axi_awlen_w),
    .axi_awburst_i(axi_awburst_w),
    .axi_wvalid_i(axi_wvalid_w),
    .axi_wdata_i(axi_wdata_w),
    .axi_wstrb_i(axi_wstrb_w),
    .axi_wlast_i(axi_wlast_w),
    .axi_bready_i(axi_bready_w),
    .axi_arvalid_i(axi_arvalid_w),
    .axi_araddr_i(axi_araddr_w),
    .axi_arid_i(axi_arid_w),
    .axi_arlen_i(axi_arlen_w),
    .axi_arburst_i(axi_arburst_w),
    .axi_rready_i(axi_rready_w),
    .axi_awready_o(axi_awready_w),
    .axi_wready_o(axi_wready_w),
    .axi_bvalid_o(axi_bvalid_w),
    .axi_bresp_o(axi_bresp_w),
    .axi_bid_o(axi_bid_w),
    .axi_arready_o(axi_arready_w),
    .axi_rvalid_o(axi_rvalid_w),
    .axi_rdata_o(axi_rdata_w),
    .axi_rresp_o(axi_rresp_w),
    .axi_rid_o(axi_rid_w),
    .axi_rlast_o(axi_rlast_w),
    
    // RAM interface
    .ram_addr_o(ram_addr_w),
    .ram_accept_i(ram_accept_w),
    .ram_wr_o(ram_wr_w),
    .ram_rd_o(ram_rd_w),
    .ram_req_id_o(ram_req_id_w),
    .ram_write_data_o(ram_write_data_w),
    .ram_ack_i(ram_ack_w),
    .ram_error_i(ram_error_w),
    .ram_read_data_i(ram_read_data_w),
    .ram_resp_id_i(ram_resp_id_w)
);

//-----------------------------------------------------------------
// DDR3 Controller
//-----------------------------------------------------------------
ddr3_core
#(
     .DDR_MHZ(DDR_MHZ)
    ,.DDR_WRITE_LATENCY(DDR_WRITE_LATENCY)
    ,.DDR_READ_LATENCY(DDR_READ_LATENCY)
)
u_core
(
     .clk_i(clk_i)
    ,.rst_i(rst_i)

    ,.inport_wr_i(ram_wr_w)
    ,.inport_rd_i(ram_rd_w)
    ,.inport_req_id_i(ram_req_id_w)
    ,.inport_addr_i(ram_addr_w)
    ,.inport_write_data_i(ram_write_data_w)
    ,.inport_accept_o(ram_accept_w)
    ,.inport_ack_o(ram_ack_w)
    ,.inport_error_o(ram_error_w)
    ,.inport_read_data_o(ram_read_data_w)
    ,.inport_resp_id_o(ram_resp_id_w)

    ,.cfg_enable_i(1'b1)
    ,.cfg_stb_i(1'b0)
    ,.cfg_data_i(32'b0)
    ,.cfg_stall_o()

    ,.dfi_address_o(dfi_address_o)
    ,.dfi_bank_o(dfi_bank_o)
    ,.dfi_cas_n_o(dfi_cas_n_o)
    ,.dfi_cke_o(dfi_cke_o)
    ,.dfi_cs_n_o(dfi_cs_n_o)
    ,.dfi_odt_o(dfi_odt_o)
    ,.dfi_ras_n_o(dfi_ras_n_o)
    ,.dfi_reset_n_o(dfi_reset_n_o)
    ,.dfi_we_n_o(dfi_we_n_o)
    ,.dfi_wrdata_o(dfi_wrdata_o)
    ,.dfi_wrdata_en_o(dfi_wrdata_en_o)
    ,.dfi_wrdata_mask_o(dfi_wrdata_mask_o)
    ,.dfi_rddata_en_o(dfi_rddata_en_o)
    ,.dfi_rddata_i(dfi_rddata_i)
    ,.dfi_rddata_valid_i(dfi_rddata_valid_i)
    ,.dfi_rddata_dnv_i(dfi_rddata_dnv_i)
);



endmodule
