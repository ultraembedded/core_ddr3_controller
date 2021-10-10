`timescale 1 ns / 100ps

module testbench ;

`include "simulation.vh"

//-----------------------------------------------------------------
// Clock / Reset
//-----------------------------------------------------------------
`CLOCK_GEN(osc, 10)    // 100MHz
`RESET_GEN(rst, 1000)

//-----------------------------------------------------------------
// Misc
//-----------------------------------------------------------------
`TB_VCD(testbench, "waveform.vcd")

//-----------------------------------------------------------------
// PLL
//-----------------------------------------------------------------
wire clk;
wire clk_ddr;
wire clk_ddr_dqs;
wire clk_ref;

artix7_pll
u_pll
(
    .clkref_i(osc)

    // Outputs
    ,.clkout0_o(clk)         // 100
    ,.clkout1_o(clk_ddr)     // 400
    ,.clkout2_o(clk_ref)     // 200
    ,.clkout3_o(clk_ddr_dqs) // 400 (phase 90)
);

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------
wire          ddr3_clk_w;
wire          ddr3_cke_w;
wire          ddr3_reset_n_w;
wire          ddr3_ras_n_w;
wire          ddr3_cas_n_w;
wire          ddr3_we_n_w;
wire          ddr3_cs_n_w;
wire [  2:0]  ddr3_ba_w;
wire [ 13:0]  ddr3_addr_w;
wire          ddr3_odt_w;
wire [  1:0]  ddr3_dm_w;
wire [  1:0]  ddr3_dqs_w;
wire [ 15:0]  ddr3_dq_w;

wire  [ 14:0] dfi_address;
wire  [  2:0] dfi_bank;
wire          dfi_cas_n;
wire          dfi_cke;
wire          dfi_cs_n;
wire          dfi_odt;
wire          dfi_ras_n;
wire          dfi_reset_n;
wire          dfi_we_n;
wire  [ 31:0] dfi_wrdata;
wire          dfi_wrdata_en;
wire  [  3:0] dfi_wrdata_mask;
wire          dfi_rddata_en;
wire [ 31:0]  dfi_rddata;
wire          dfi_rddata_valid;

//-----------------------------------------------------------------
// DRAM Model
//-----------------------------------------------------------------
wire          ddr3_ck_p_w;
wire          ddr3_ck_n_w;
wire [  1:0]  ddr3_dqs_p_w;
wire [  1:0]  ddr3_dqs_n_w;

ddr3
u_ram
(
     .rst_n(ddr3_reset_n_w)
    ,.ck(ddr3_ck_p_w)
    ,.ck_n(ddr3_ck_n_w)
    ,.cke(ddr3_cke_w)
    ,.cs_n(ddr3_cs_n_w)
    ,.ras_n(ddr3_ras_n_w)
    ,.cas_n(ddr3_cas_n_w)
    ,.we_n(ddr3_we_n_w)
    ,.dm_tdqs(ddr3_dm_w)
    ,.ba(ddr3_ba_w)
    ,.addr(ddr3_addr_w)
    ,.dq(ddr3_dq_w)
    ,.dqs(ddr3_dqs_p_w)
    ,.dqs_n(ddr3_dqs_n_w)
    ,.tdqs_n()
    ,.odt(ddr3_odt_w)
);

//-----------------------------------------------------------------
// DDR PHY
//-----------------------------------------------------------------
ddr3_dfi_phy
#(
     .DQS_TAP_DELAY_INIT(27)
    ,.DQ_TAP_DELAY_INIT(0)
    ,.TPHY_RDLAT(5)
)
u_phy
(
     .clk_i(clk)
    ,.clk_ddr_i(clk_ddr)
    ,.clk_ddr90_i(clk_ddr_dqs)
    ,.clk_ref_i(clk_ref)
    ,.rst_i(rst)

    ,.dfi_address_i(dfi_address)
    ,.dfi_bank_i(dfi_bank)
    ,.dfi_cas_n_i(dfi_cas_n)
    ,.dfi_cke_i(dfi_cke)
    ,.dfi_cs_n_i(dfi_cs_n)
    ,.dfi_odt_i(dfi_odt)
    ,.dfi_ras_n_i(dfi_ras_n)
    ,.dfi_reset_n_i(dfi_reset_n)
    ,.dfi_we_n_i(dfi_we_n)

    ,.dfi_wrdata_i(dfi_wrdata)
    ,.dfi_wrdata_en_i(dfi_wrdata_en)
    ,.dfi_wrdata_mask_i(dfi_wrdata_mask)
    ,.dfi_rddata_en_i(dfi_rddata_en)

    ,.dfi_rddata_o(dfi_rddata)
    ,.dfi_rddata_valid_o(dfi_rddata_valid)
    ,.dfi_rddata_dnv_o()

    ,.ddr3_ck_p_o(ddr3_ck_p_w)
    ,.ddr3_ck_n_o(ddr3_ck_n_w)
    ,.ddr3_cke_o(ddr3_cke_w)
    ,.ddr3_reset_n_o(ddr3_reset_n_w)
    ,.ddr3_ras_n_o(ddr3_ras_n_w)
    ,.ddr3_cas_n_o(ddr3_cas_n_w)
    ,.ddr3_we_n_o(ddr3_we_n_w)
    ,.ddr3_cs_n_o(ddr3_cs_n_w)
    ,.ddr3_ba_o(ddr3_ba_w)
    ,.ddr3_addr_o(ddr3_addr_w)
    ,.ddr3_odt_o(ddr3_odt_w)
    ,.ddr3_dm_o(ddr3_dm_w)
    ,.ddr3_dqs_p_io(ddr3_dqs_p_w)
    ,.ddr3_dqs_n_io(ddr3_dqs_n_w)
    ,.ddr3_dq_io(ddr3_dq_w)
);

//-----------------------------------------------------------------
// DDR Core
//-----------------------------------------------------------------
reg  [ 15:0]  ram_wr;
reg           ram_rd;
reg  [ 31:0]  ram_addr;
reg  [127:0]  ram_write_data;
reg  [ 15:0]  ram_req_id;
wire          ram_accept;
wire          ram_ack;
wire          ram_error;
wire [ 15:0]  ram_resp_id;
wire [127:0]  ram_read_data;

ddr3_core
#(
     .DDR_WRITE_LATENCY(4)
    ,.DDR_READ_LATENCY(4)
    ,.DDR_MHZ(100)
)
u_ddr_core
(
     .clk_i(clk)
    ,.rst_i(rst)

    // Configuration (unused)
    ,.cfg_enable_i(1'b1)
    ,.cfg_stb_i(1'b0)
    ,.cfg_data_i(32'b0)
    ,.cfg_stall_o()

    ,.inport_wr_i(ram_wr)
    ,.inport_rd_i(ram_rd)
    ,.inport_addr_i(ram_addr)
    ,.inport_write_data_i(ram_write_data)
    ,.inport_req_id_i(ram_req_id)
    ,.inport_accept_o(ram_accept)
    ,.inport_ack_o(ram_ack)
    ,.inport_error_o(ram_error)
    ,.inport_resp_id_o(ram_resp_id)
    ,.inport_read_data_o(ram_read_data)

    ,.dfi_address_o(dfi_address)
    ,.dfi_bank_o(dfi_bank)
    ,.dfi_cas_n_o(dfi_cas_n)
    ,.dfi_cke_o(dfi_cke)
    ,.dfi_cs_n_o(dfi_cs_n)
    ,.dfi_odt_o(dfi_odt)
    ,.dfi_ras_n_o(dfi_ras_n)
    ,.dfi_reset_n_o(dfi_reset_n)
    ,.dfi_we_n_o(dfi_we_n)
    ,.dfi_wrdata_o(dfi_wrdata)
    ,.dfi_wrdata_en_o(dfi_wrdata_en)
    ,.dfi_wrdata_mask_o(dfi_wrdata_mask)
    ,.dfi_rddata_en_o(dfi_rddata_en)
    ,.dfi_rddata_i(dfi_rddata)
    ,.dfi_rddata_valid_i(dfi_rddata_valid)
    ,.dfi_rddata_dnv_i(dfi_rddata_dnv)
);

//-----------------------------------------------------------------
// ram_read: Perform read transfer (128-bit)
//-----------------------------------------------------------------
task ram_read;
    input  [31:0]  addr;
    output [127:0] data;
begin
    ram_rd     <= 1'b1;
    ram_addr   <= addr;
    ram_req_id <= ram_req_id + 1;
    @(posedge clk);

    while (!ram_accept)
    begin
        @(posedge clk);
    end
    ram_rd     <= 1'b0;

    while (!ram_ack)
    begin
        @(posedge clk);
    end

    data = ram_read_data;
end
endtask

//-----------------------------------------------------------------
// ram_write: Perform write transfer (128-bit)
//-----------------------------------------------------------------
task ram_write;
    input [31:0]  addr;
    input [127:0] data;
    input [15:0]  mask;
begin
    ram_wr         <= mask;
    ram_addr       <= addr;
    ram_write_data <= data;
    ram_req_id     <= ram_req_id + 1;
    @(posedge clk);

    while (!ram_accept)
    begin
        @(posedge clk);
    end
    ram_wr <= 16'b0;

    while (!ram_ack)
    begin
        @(posedge clk);
    end
end
endtask

//-----------------------------------------------------------------
// Initialisation
//-----------------------------------------------------------------
reg [127:0] data;
initial
begin
    ram_wr         = 0;
    ram_rd         = 0;
    ram_addr       = 0;
    ram_write_data = 0;
    ram_req_id     = 0;

    @(posedge clk);
    
    ram_write(0,  128'hffeeddccbbaa99887766554433221100, 16'hFFFF);
    ram_write(16, 128'hbeaffeadd0d0600d5555AAAA00000000, 16'hFFFF);
    ram_write(32, 128'hffffffff111111112222222233333333, 16'hFFFF);

    ram_read(0, data);
    if (data != 128'hffeeddccbbaa99887766554433221100)
    begin
        $fatal(1, "ERROR: Data mismatch!");
    end

    ram_read(16, data);
    if (data != 128'hbeaffeadd0d0600d5555AAAA00000000)
    begin
        $fatal(1, "ERROR: Data mismatch!");
    end

    ram_read(32, data);
    if (data != 128'hffffffff111111112222222233333333)
    begin
        $fatal(1, "ERROR: Data mismatch!");
    end
    
    #1000
    @(posedge clk);   
    $finish;

end

endmodule