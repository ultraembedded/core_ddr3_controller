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

module ddr3_axi_pmem
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           axi_awvalid_i
    ,input  [ 31:0]  axi_awaddr_i
    ,input  [  3:0]  axi_awid_i
    ,input  [  7:0]  axi_awlen_i
    ,input  [  1:0]  axi_awburst_i
    ,input           axi_wvalid_i
    ,input  [ 31:0]  axi_wdata_i
    ,input  [  3:0]  axi_wstrb_i
    ,input           axi_wlast_i
    ,input           axi_bready_i
    ,input           axi_arvalid_i
    ,input  [ 31:0]  axi_araddr_i
    ,input  [  3:0]  axi_arid_i
    ,input  [  7:0]  axi_arlen_i
    ,input  [  1:0]  axi_arburst_i
    ,input           axi_rready_i
    ,input           ram_accept_i
    ,input           ram_ack_i
    ,input           ram_error_i
    ,input  [ 15:0]  ram_resp_id_i
    ,input  [127:0]  ram_read_data_i

    // Outputs
    ,output          axi_awready_o
    ,output          axi_wready_o
    ,output          axi_bvalid_o
    ,output [  1:0]  axi_bresp_o
    ,output [  3:0]  axi_bid_o
    ,output          axi_arready_o
    ,output          axi_rvalid_o
    ,output [ 31:0]  axi_rdata_o
    ,output [  1:0]  axi_rresp_o
    ,output [  3:0]  axi_rid_o
    ,output          axi_rlast_o
    ,output [ 15:0]  ram_wr_o
    ,output          ram_rd_o
    ,output [ 31:0]  ram_addr_o
    ,output [127:0]  ram_write_data_o
    ,output [ 15:0]  ram_req_id_o
);



//-------------------------------------------------------------
// Assertions
//-------------------------------------------------------------
localparam AXI4_BURST_FIXED = 2'd0;
localparam AXI4_BURST_INCR  = 2'd1;
localparam AXI4_BURST_WRAP  = 2'd2;

`ifdef SIMULATION
wire [31:0] awlen_ext_w   = {24'b0, axi_awlen_i};
wire [31:0] arlen_ext_w   = {24'b0, axi_arlen_i};
wire [31:0] awaddr_mask_w = ((awlen_ext_w + 1) * 4) - 1;
wire [31:0] araddr_mask_w = ((arlen_ext_w + 1) * 4) - 1;

always @ (posedge clk_i )
if (rst_i)
    ;
else 
begin
    if (axi_awvalid_i && axi_awburst_i == AXI4_BURST_FIXED)
    begin
        $display("ERROR: Fixed bursts not supported");
        $fatal;
    end
    if (axi_arvalid_i && axi_arburst_i == AXI4_BURST_FIXED)
    begin
        $display("ERROR: Fixed bursts not supported yet");
        $fatal;
    end
    if (axi_awvalid_i && axi_awlen_i != 8'd0 && ((axi_awaddr_i & awaddr_mask_w) != 32'b0))
    begin
        $display("ERROR: Non-aligned bursts not supported yet");
        $fatal;
    end
    if (axi_arvalid_i && axi_arlen_i != 8'd0 && ((axi_araddr_i & araddr_mask_w) != 32'b0))
    begin
        $display("ERROR: Non-aligned bursts not supported yet");
        $fatal;
    end
end
`endif

//-------------------------------------------------------------
// Request Counter
//-------------------------------------------------------------
reg [3:0]   read_pending_q;
reg [3:0]   read_pending_r;

wire read_incr_w = (axi_arvalid_i && axi_arready_o);
wire read_decr_w = (axi_rvalid_o  && axi_rlast_o && axi_rready_i);

always @ *
begin
    read_pending_r = read_pending_q;

    if (read_incr_w && !read_decr_w)
        read_pending_r = read_pending_r + 4'd1;
    else if (!read_incr_w && read_decr_w)
        read_pending_r = read_pending_r - 4'd1;
end

always @ (posedge clk_i )
if (rst_i)
    read_pending_q <= 4'b0;
else 
    read_pending_q <= read_pending_r;


reg [3:0]   write_pending_q;
reg [3:0]   write_pending_r;

wire write_incr_w = (axi_wvalid_i && axi_wlast_i && axi_wready_o);
wire write_decr_w = (axi_bvalid_o && axi_bready_i);

always @ *
begin
    write_pending_r = write_pending_q;

    if (write_incr_w && !write_decr_w)
        write_pending_r = write_pending_r + 4'd1;
    else if (!write_incr_w && write_decr_w)
        write_pending_r = write_pending_r - 4'd1;
end

always @ (posedge clk_i )
if (rst_i)
    write_pending_q <= 4'b0;
else 
    write_pending_q <= write_pending_r;

wire read_limit_w  = (read_pending_q > 4'd6);
wire write_limit_w = (write_pending_q > 4'd6);

//-------------------------------------------------------------
// Read / Write arbitration
//-------------------------------------------------------------
reg prio_rd_q;

// Round robin priority between read and write
wire write_prio_w   = ~prio_rd_q || !axi_arvalid_i;
wire read_prio_w    = prio_rd_q  || !awvalid_w;

always @ (posedge clk_i )
if (rst_i)
    prio_rd_q <= 1'b0;
// Start of write accepted
else if (axi_awvalid_i && axi_awready_o && (!axi_wvalid_i || !axi_wlast_i || !axi_wready_o))
    prio_rd_q <= 1'b0;
// Command complete - toggle priority
else if ((axi_wvalid_i && axi_wlast_i && axi_wready_o) || (axi_arvalid_i && axi_arready_o))
    prio_rd_q <= ~prio_rd_q;

wire write_enable_w = write_prio_w & ~write_limit_w;
wire read_enable_w  = read_prio_w  & ~read_limit_w;

//-------------------------------------------------------------
// Write Buffer
//-------------------------------------------------------------
reg        awvalid_q;
reg [31:0] awaddr_q;
reg [7:0]  awlen_q;
reg [3:0]  awid_q;
reg        wfirst_q;

wire wr_cmd_accepted_w  = (axi_awvalid_i && axi_awready_o) || awvalid_q;
wire wr_data_accepted_w = (axi_wvalid_i  && axi_wready_o);
wire wr_data_last_w     = (axi_wvalid_i && axi_wready_o && axi_wlast_i);

always @ (posedge clk_i )
if (rst_i)
    awvalid_q <= 1'b0;
else if (axi_awvalid_i && axi_awready_o && (!wr_data_accepted_w || !wr_data_last_w))
    awvalid_q <= 1'b1;
else if (wr_data_accepted_w && wr_data_last_w)
    awvalid_q <= 1'b0;

always @ (posedge clk_i )
if (rst_i)
    wfirst_q <= 1'b1;
else if (wr_cmd_accepted_w && wr_data_accepted_w && !wr_data_last_w)
    wfirst_q <= 1'b0;
else if (wr_data_accepted_w && wr_data_last_w)
    wfirst_q <= 1'b1;

always @ (posedge clk_i )
if (rst_i)
begin
    awaddr_q  <= 32'b0;
    awlen_q   <= 8'b0;
    awid_q    <= 4'b0;
end
else if (axi_awvalid_i && axi_awready_o)
begin
    awaddr_q  <= axi_awaddr_i;
    awlen_q   <= axi_awlen_i;
    awid_q    <= axi_awid_i;
end

wire        awvalid_w = axi_awvalid_i | awvalid_q;
wire [31:0] awaddr_w  = awvalid_q ? awaddr_q : axi_awaddr_i;
wire [7:0]  awlen_w   = awvalid_q ? awlen_q  : axi_awlen_i;
wire [3:0]  awid_w    = awvalid_q ? awid_q   : axi_awid_i;

wire   inport_accept_w;
assign axi_awready_o = write_enable_w & ~awvalid_q;
assign axi_wready_o  = write_enable_w & awvalid_w & inport_accept_w;
assign axi_arready_o = read_enable_w & inport_accept_w;

//-----------------------------------------------------------------
// Valids
//-----------------------------------------------------------------
wire write_valid_w = write_enable_w & awvalid_w & axi_wvalid_i;
wire read_valid_w  = axi_arvalid_i & read_enable_w;

//-----------------------------------------------------------------
// Request
//-----------------------------------------------------------------
reg [1:0]   wdata_idx_q;
reg [127:0] wdata_q;
reg [15:0]  wstrb_q;
reg [7:0]   rd_remain_q;

wire [1:0]  wdata_idx_w = wfirst_q ? awaddr_w[3:2] : wdata_idx_q;

reg [127:0] wdata_r;
reg [15:0]  wstrb_r;

always @ *
begin
    wdata_r = wdata_q;
    wstrb_r = wstrb_q;

    if (axi_wvalid_i)
    begin
        if (wfirst_q)
        begin
            wstrb_r = 16'b0;
        end

        case (wdata_idx_w)
        default: wdata_r[31:0]   = axi_wdata_i;
        2'd1:    wdata_r[63:32]  = axi_wdata_i;
        2'd2:    wdata_r[95:64]  = axi_wdata_i;
        2'd3:    wdata_r[127:96] = axi_wdata_i;
        endcase

        case (wdata_idx_w)
        default: wstrb_r[3:0]    = axi_wstrb_i;
        2'd1:    wstrb_r[7:4]    = axi_wstrb_i;
        2'd2:    wstrb_r[11:8]   = axi_wstrb_i;
        2'd3:    wstrb_r[15:12]  = axi_wstrb_i;
        endcase
    end
end

always @ (posedge clk_i )
if (rst_i)
begin
    wdata_q     <= 128'b0;
    wstrb_q     <= 16'b0;
end
else if (axi_wvalid_i && axi_wready_o)
begin
    wdata_q     <= wdata_r;
    wstrb_q     <= wstrb_r;
end


reg [31:0]  addr_q;
reg [127:0] write_data_q;
reg [15:0]  write_mask_q;
reg         wr_q;
reg         rd_q;
reg         wr_last_q;
reg [7:0]   len_q;
reg [3:0]   id_q;
wire        ram_accept_w;

always @ (posedge clk_i )
if (rst_i)
begin
    addr_q       <= 32'b0;
    wr_q         <= 1'b0;
    rd_q         <= 1'b0;
    write_data_q <= 128'b0;
    write_mask_q <= 16'b0;
    wdata_idx_q  <= 2'b0;
    rd_remain_q  <= 8'b0;
    len_q        <= 8'b0;
    id_q         <= 4'b0;
    wr_last_q    <= 1'b1;
end
else if ((wr_q || rd_q) && !ram_accept_w)
    ;
else if (read_valid_w && inport_accept_w)
begin
    addr_q      <= axi_araddr_i;
    rd_remain_q <= {2'b0, axi_arlen_i[7:2]};
    len_q       <= axi_arlen_i;
    id_q        <= axi_arid_i;
    rd_q        <= 1'b1;
    wr_q        <= 1'b0;
    wr_last_q   <= 1'b0;
end
else if (rd_q && rd_remain_q != 8'd0)
begin
    addr_q      <= addr_q + 32'd16;
    rd_q        <= 1'b1;
    rd_remain_q <= rd_remain_q - 8'd1;
end
else if (write_valid_w && inport_accept_w)
begin
    addr_q      <= wfirst_q ? awaddr_w : addr_q + 32'd4;
    write_data_q<= wdata_r;
    write_mask_q<= wstrb_r;
    wdata_idx_q <= wdata_idx_w + 2'd1;
    wr_q        <= axi_wlast_i || wdata_idx_w == 2'd3;
    wr_last_q   <= axi_wlast_i;
    id_q        <= awid_w;
    len_q       <= awlen_w;
    rd_q        <= 1'b0;
end
else
begin
    wr_q        <= 1'b0;
    rd_q        <= 1'b0;
    wr_last_q   <= 1'b0;
end

wire [15:0]  ram_wr_w         = {16{wr_q}} & write_mask_q;
wire         ram_rd_w         = rd_q;
wire [31:0]  ram_addr_w       = {addr_q[31:4], 4'b0};
wire [127:0] ram_write_data_w = write_data_q;
wire [15:0]  ram_req_id_w     = {id_q, len_q, addr_q[3:2], rd_q, rd_q | wr_last_q};

assign inport_accept_w      = ((!wr_q && !rd_q) || ram_accept_w) && (rd_remain_q == 8'b0);

//-----------------------------------------------------------------
// Request FIFO - decouple AXI logic from RAM port
//-----------------------------------------------------------------
wire        ram_rd_out_w;
wire [15:0] ram_wr_out_w;
wire        ram_valid_out_w;

ddr3_axi_pmem_fifo
#( 
     .WIDTH(16 + 128 + 32 + 1 + 16)
    ,.DEPTH(2)
    ,.ADDR_W(1)
)
u_request
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Input
    .data_in_i({ram_req_id_w, ram_write_data_w, ram_addr_w, ram_rd_w, ram_wr_w}),
    .push_i((|ram_wr_w) || ram_rd_w),
    .accept_o(ram_accept_w),

    // Output
    .pop_i(ram_accept_i),
    .data_out_o({ram_req_id_o, ram_write_data_o, ram_addr_o, ram_rd_out_w, ram_wr_out_w}),
    .valid_o(ram_valid_out_w)
);

assign ram_rd_o = ram_valid_out_w       & ram_rd_out_w;
assign ram_wr_o = {16{ram_valid_out_w}} & ram_wr_out_w;

//-----------------------------------------------------------------
// Response state
//-----------------------------------------------------------------
wire         resp_valid_w;
wire         resp_last_w;
wire         resp_rd_w;
wire [1:0]   resp_offset_w;
wire [7:0]   resp_len_w;
wire [3:0]   resp_id_w;

wire         resp_accept_w;

reg [7:0] resp_cnt_q;

always @ (posedge clk_i )
if (rst_i)
    resp_cnt_q <= 8'b0;
else if (resp_valid_w && resp_rd_w && resp_accept_w)
begin
    if (resp_cnt_q < resp_len_w)
        resp_cnt_q <= resp_cnt_q + 8'd1;
    else
        resp_cnt_q <= 8'b0;    
end

wire req_pop_w = resp_valid_w && ((resp_cnt_q == resp_len_w) || (!resp_rd_w && resp_last_w));

reg [1:0]  resp_idx_q;
wire [1:0] resp_idx_w = (resp_cnt_q == 8'd0) ? resp_offset_w : resp_idx_q;

always @ (posedge clk_i )
if (rst_i)
    resp_idx_q <= 2'b0;
else if (resp_valid_w && resp_rd_w && resp_accept_w)
begin
    if (resp_cnt_q == 8'd0)
        resp_idx_q <= resp_idx_w + 2'd1;
    else if (resp_cnt_q < resp_len_w)
        resp_idx_q <= resp_idx_q + 2'd1;
    else
        resp_idx_q <= resp_idx_w + 2'd1;
end

//-----------------------------------------------------------------
// Response
//-----------------------------------------------------------------
wire [127:0] resp_data_w;

ddr3_axi_pmem_fifo
#( 
     .WIDTH(128 + 2 + 2 + 8 + 4)
    ,.DEPTH(8)      // TODO: Overkill
    ,.ADDR_W(3)
)
u_response
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Input
    .data_in_i({ram_resp_id_i, ram_read_data_i}),
    .push_i(ram_ack_i & (ram_resp_id_i[1] || ram_resp_id_i[0])),
    .accept_o(),

    // Output
    .pop_i(resp_accept_w & (req_pop_w || resp_idx_w == 2'd3)),
    .data_out_o({resp_id_w, resp_len_w, resp_offset_w, resp_rd_w, resp_last_w, resp_data_w}),
    .valid_o(resp_valid_w)
);

reg [31:0] resp_rdata_r;

always @ *
begin
    resp_rdata_r = 32'b0;
    case (resp_idx_w)
    default: resp_rdata_r = resp_data_w[31:0];
    2'd1:    resp_rdata_r = resp_data_w[63:32];
    2'd2:    resp_rdata_r = resp_data_w[95:64];
    2'd3:    resp_rdata_r = resp_data_w[127:96];
    endcase
end

assign resp_accept_w    = (axi_rvalid_o & axi_rready_i) ||
                          (axi_bvalid_o & axi_bready_i);


assign axi_bvalid_o  = resp_valid_w & ~resp_rd_w;
assign axi_bresp_o   = 2'b0;
assign axi_bid_o     = resp_id_w;

assign axi_rvalid_o  = resp_valid_w & resp_rd_w;
assign axi_rresp_o   = 2'b0;
assign axi_rid_o     = resp_id_w;
assign axi_rdata_o   = resp_rdata_r;
assign axi_rlast_o   = resp_last_w && (resp_cnt_q >= resp_len_w);

endmodule

//-----------------------------------------------------------------
// FIFO
//-----------------------------------------------------------------
module ddr3_axi_pmem_fifo

//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2
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
reg [WIDTH-1:0]         ram [DEPTH-1:0];
reg [ADDR_W-1:0]        rd_ptr;
reg [ADDR_W-1:0]        wr_ptr;
reg [COUNT_W-1:0]       count;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i )
if (rst_i)
begin
    count   <= {(COUNT_W) {1'b0}};
    rd_ptr  <= {(ADDR_W) {1'b0}};
    wr_ptr  <= {(ADDR_W) {1'b0}};
end
else
begin
    // Push
    if (push_i & accept_o)
    begin
        ram[wr_ptr] <= data_in_i;
        wr_ptr      <= wr_ptr + 1;
    end

    // Pop
    if (pop_i & valid_o)
        rd_ptr      <= rd_ptr + 1;

    // Count up
    if ((push_i & accept_o) & ~(pop_i & valid_o))
        count <= count + 1;
    // Count down
    else if (~(push_i & accept_o) & (pop_i & valid_o))
        count <= count - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign accept_o   = (count != DEPTH);
assign valid_o    = (count != 0);
/* verilator lint_on WIDTH */

assign data_out_o = ram[rd_ptr];



endmodule
