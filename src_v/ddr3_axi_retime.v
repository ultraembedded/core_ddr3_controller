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

module ddr3_axi_retime
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter AXI4_RETIME_WR_REQ = 1
    ,parameter AXI4_RETIME_WR_RESP = 1
    ,parameter AXI4_RETIME_RD_REQ = 1
    ,parameter AXI4_RETIME_RD_RESP = 1
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
    ,input           outport_awready_i
    ,input           outport_wready_i
    ,input           outport_bvalid_i
    ,input  [  1:0]  outport_bresp_i
    ,input  [  3:0]  outport_bid_i
    ,input           outport_arready_i
    ,input           outport_rvalid_i
    ,input  [ 31:0]  outport_rdata_i
    ,input  [  1:0]  outport_rresp_i
    ,input  [  3:0]  outport_rid_i
    ,input           outport_rlast_i

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
    ,output          outport_awvalid_o
    ,output [ 31:0]  outport_awaddr_o
    ,output [  3:0]  outport_awid_o
    ,output [  7:0]  outport_awlen_o
    ,output [  1:0]  outport_awburst_o
    ,output          outport_wvalid_o
    ,output [ 31:0]  outport_wdata_o
    ,output [  3:0]  outport_wstrb_o
    ,output          outport_wlast_o
    ,output          outport_bready_o
    ,output          outport_arvalid_o
    ,output [ 31:0]  outport_araddr_o
    ,output [  3:0]  outport_arid_o
    ,output [  7:0]  outport_arlen_o
    ,output [  1:0]  outport_arburst_o
    ,output          outport_rready_o
);



//-----------------------------------------------------------------
// Write Command Request
//-----------------------------------------------------------------
localparam WRITE_CMD_REQ_W = 32 + 4 + 8 + 2;

generate
if (AXI4_RETIME_WR_REQ)
begin
    wire [WRITE_CMD_REQ_W-1:0] write_cmd_req_out_w;

    ddr3_axi_retime_fifo
    #( .WIDTH(WRITE_CMD_REQ_W) )
    u_write_cmd_req
    (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .push_i(inport_awvalid_i),
        .data_in_i({inport_awaddr_i, inport_awid_i, inport_awlen_i, inport_awburst_i}),
        .accept_o(inport_awready_o),

        .valid_o(outport_awvalid_o),
        .data_out_o(write_cmd_req_out_w),
        .pop_i(outport_awready_i)
    );

    assign {outport_awaddr_o, outport_awid_o, outport_awlen_o, outport_awburst_o} = write_cmd_req_out_w;
end
else
begin
    assign outport_awvalid_o = inport_awvalid_i;
    assign {outport_awaddr_o, outport_awid_o, outport_awlen_o, outport_awburst_o} = {inport_awaddr_i, inport_awid_i, inport_awlen_i, inport_awburst_i};
    assign inport_awready_o = outport_awready_i;
end
endgenerate

//-----------------------------------------------------------------
// Write Data Request
//-----------------------------------------------------------------
localparam WRITE_DATA_REQ_W = 32 + 4 + 1;

generate
if (AXI4_RETIME_WR_REQ)
begin
    wire [WRITE_DATA_REQ_W-1:0] write_data_req_out_w;

    ddr3_axi_retime_fifo
    #( .WIDTH(WRITE_DATA_REQ_W) )
    u_write_data_req
    (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .push_i(inport_wvalid_i),
        .data_in_i({inport_wlast_i, inport_wstrb_i, inport_wdata_i}),
        .accept_o(inport_wready_o),

        .valid_o(outport_wvalid_o),
        .data_out_o(write_data_req_out_w),
        .pop_i(outport_wready_i)
    );

    assign {outport_wlast_o, outport_wstrb_o, outport_wdata_o} = write_data_req_out_w;
end
else
begin
    assign outport_wvalid_o = inport_wvalid_i;
    assign {outport_wlast_o, outport_wstrb_o, outport_wdata_o} = {inport_wlast_i, inport_wstrb_i, inport_wdata_i};
    assign inport_wready_o = outport_wready_i;
end
endgenerate
//-----------------------------------------------------------------
// Write Response
//-----------------------------------------------------------------
localparam WRITE_RESP_W = 2 + 4;

generate
if (AXI4_RETIME_WR_RESP)
begin
    wire [WRITE_RESP_W-1:0] write_resp_out_w;

    ddr3_axi_retime_fifo
    #( .WIDTH(WRITE_RESP_W) )
    u_write_resp
    (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .push_i(outport_bvalid_i),
        .data_in_i({outport_bresp_i, outport_bid_i}),
        .accept_o(outport_bready_o),

        .valid_o(inport_bvalid_o),
        .data_out_o(write_resp_out_w),
        .pop_i(inport_bready_i)
    );

    assign {inport_bresp_o, inport_bid_o} = write_resp_out_w;
end
else
begin
    assign inport_bvalid_o = outport_bvalid_i;
    assign {inport_bresp_o, inport_bid_o} = {outport_bresp_i, outport_bid_i};
    assign outport_bready_o = inport_bready_i;
end
endgenerate

//-----------------------------------------------------------------
// Read Request
//-----------------------------------------------------------------
localparam READ_REQ_W = 32 + 4 + 8 + 2;

generate
if (AXI4_RETIME_RD_REQ)
begin
    wire [READ_REQ_W-1:0] read_req_out_w;

    ddr3_axi_retime_fifo
    #( .WIDTH(READ_REQ_W) )
    u_read_req
    (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .push_i(inport_arvalid_i),
        .data_in_i({inport_araddr_i, inport_arid_i, inport_arlen_i, inport_arburst_i}),
        .accept_o(inport_arready_o),

        .valid_o(outport_arvalid_o),
        .data_out_o(read_req_out_w),
        .pop_i(outport_arready_i)
    );

    assign {outport_araddr_o, outport_arid_o, outport_arlen_o, outport_arburst_o} = read_req_out_w;
end
else
begin
    assign outport_arvalid_o = inport_arvalid_i;
    assign {outport_araddr_o, outport_arid_o, outport_arlen_o, outport_arburst_o} = {inport_araddr_i, inport_arid_i, inport_arlen_i, inport_arburst_i};
    assign inport_arready_o = outport_arready_i;
end
endgenerate

//-----------------------------------------------------------------
// Read Response
//-----------------------------------------------------------------
localparam READ_RESP_W = 32 + 2 + 4 + 1;

generate
if (AXI4_RETIME_RD_RESP)
begin
    wire [READ_RESP_W-1:0] read_resp_out_w;

    ddr3_axi_retime_fifo
    #( .WIDTH(READ_RESP_W) )
    u_read_resp
    (
        .clk_i(clk_i),
        .rst_i(rst_i),

        .push_i(outport_rvalid_i),
        .data_in_i({outport_rdata_i, outport_rresp_i, outport_rid_i, outport_rlast_i}),
        .accept_o(outport_rready_o),

        .valid_o(inport_rvalid_o),
        .data_out_o(read_resp_out_w),
        .pop_i(inport_rready_i)
    );

    assign {inport_rdata_o, inport_rresp_o, inport_rid_o, inport_rlast_o} = read_resp_out_w;
end
else
begin
    assign inport_rvalid_o = outport_rvalid_i;
    assign {inport_rdata_o, inport_rresp_o, inport_rid_o, inport_rlast_o} = {outport_rdata_i, outport_rresp_i, outport_rid_i, outport_rlast_i};
    assign outport_rready_o = inport_rready_i;
end
endgenerate

endmodule

//-----------------------------------------------------------------
//                       FIFO modules
//-----------------------------------------------------------------
module ddr3_axi_retime_fifo
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH   = 8,
    parameter DEPTH   = 2,
    parameter ADDR_W  = 1
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input               clk_i
    ,input               rst_i
    ,input  [WIDTH-1:0]  data_in_i
    ,input               push_i
    ,input               pop_i

    // Outputs
    ,output [WIDTH-1:0]  data_out_o
    ,output              accept_o
    ,output              valid_o
);

//-----------------------------------------------------------------
// Local Params
//-----------------------------------------------------------------
localparam COUNT_W = ADDR_W + 1;

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [WIDTH-1:0]   ram_q[DEPTH-1:0];
reg [ADDR_W-1:0]  rd_ptr_q;
reg [ADDR_W-1:0]  wr_ptr_q;
reg [COUNT_W-1:0] count_q;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};
end
else
begin
    // Push
    if (push_i & accept_o)
    begin
        ram_q[wr_ptr_q] <= data_in_i;
        wr_ptr_q        <= wr_ptr_q + 1;
    end

    // Pop
    if (pop_i & valid_o)
        rd_ptr_q      <= rd_ptr_q + 1;

    // Count up
    if ((push_i & accept_o) & ~(pop_i & valid_o))
        count_q <= count_q + 1;
    // Count down
    else if (~(push_i & accept_o) & (pop_i & valid_o))
        count_q <= count_q - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign valid_o       = (count_q != 0);
assign accept_o      = (count_q != DEPTH);
/* verilator lint_on WIDTH */

assign data_out_o    = ram_q[rd_ptr_q];



endmodule
