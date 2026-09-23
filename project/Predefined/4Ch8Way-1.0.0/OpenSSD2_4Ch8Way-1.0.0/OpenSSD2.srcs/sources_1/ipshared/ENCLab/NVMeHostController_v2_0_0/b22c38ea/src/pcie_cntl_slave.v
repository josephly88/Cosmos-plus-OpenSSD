
/*
----------------------------------------------------------------------------------
Copyright (c) 2013-2014

  Embedded and Network Computing Lab.
  Open SSD Project
  Hanyang University

All rights reserved.

----------------------------------------------------------------------------------

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  1. Redistributions of source code must retain the above copyright
     notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright
     notice, this list of conditions and the following disclaimer in the
     documentation and/or other materials provided with the distribution.

  3. All advertising materials mentioning features or use of this source code
     must display the following acknowledgement:
     This product includes source code developed 
     by the Embedded and Network Computing Lab. and the Open SSD Project.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

----------------------------------------------------------------------------------

http://enclab.hanyang.ac.kr/
http://www.openssd-project.org/
http://www.hanyang.ac.kr/

----------------------------------------------------------------------------------
*/


`timescale 1ns / 1ps


module pcie_cntl_slave # (
	parameter	C_PCIE_DATA_WIDTH			= 128,
	parameter	C_PCIE_ADDR_WIDTH			= 36,
	
    parameter	 C_M_AXI_ADDR_WIDTH              = 32,
    parameter    C_M_AXI_DATA_WIDTH            = 64,
    parameter    C_M_AXI_ID_WIDTH              = 1,
    parameter    C_M_AXI_AWUSER_WIDTH          = 1,
    parameter    C_M_AXI_WUSER_WIDTH           = 1,
    parameter    C_M_AXI_BUSER_WIDTH           = 1,
    parameter    C_M_AXI_ARUSER_WIDTH          = 1,
    parameter    C_M_AXI_RUSER_WIDTH           = 1,
    parameter    C_M_AXI_BASSADDR              = 32'h0
)
(
	input									pcie_user_clk,
	input									pcie_user_rst_n,

	output									rx_np_ok,
	output									rx_np_req,

	input									mreq_fifo_wr_en,
	input	[C_PCIE_DATA_WIDTH+8-1:0]		mreq_fifo_wr_data,

	output									tx_cpld_req,
	output	[7:0]							tx_cpld_tag,
	output	[15:0]							tx_cpld_req_id,
	output	[11:2]							tx_cpld_len,
	output	[11:0]							tx_cpld_bc,
	output	[6:0]							tx_cpld_laddr,
	output	[63:0]							tx_cpld_data,
	input									tx_cpld_req_ack,

	output									nvme_cc_en,
	output	[1:0]							nvme_cc_shn,

	input	[1:0]							nvme_csts_shst,
	input									nvme_csts_rdy,

	output									nvme_intms_ivms,
	output									nvme_intmc_ivmc,

	input									cq_irq_status,

	input	[8:0]							sq_rst_n,
	input	[8:0]							cq_rst_n,
	output	[C_PCIE_ADDR_WIDTH-1:2]			admin_sq_bs_addr,
	output	[C_PCIE_ADDR_WIDTH-1:2]			admin_cq_bs_addr,
	output	[7:0]							admin_sq_size,
	output	[7:0]							admin_cq_size,

	output	[7:0]							admin_sq_tail_ptr,
	output	[7:0]							io_sq1_tail_ptr,
	output	[7:0]							io_sq2_tail_ptr,
	output	[7:0]							io_sq3_tail_ptr,
	output	[7:0]							io_sq4_tail_ptr,
	output	[7:0]							io_sq5_tail_ptr,
	output	[7:0]							io_sq6_tail_ptr,
	output	[7:0]							io_sq7_tail_ptr,
	output	[7:0]							io_sq8_tail_ptr,

	output	[7:0]							admin_cq_head_ptr,
	output	[7:0]							io_cq1_head_ptr,
	output	[7:0]							io_cq2_head_ptr,
	output	[7:0]							io_cq3_head_ptr,
	output	[7:0]							io_cq4_head_ptr,
	output	[7:0]							io_cq5_head_ptr,
	output	[7:0]							io_cq6_head_ptr,
	output	[7:0]							io_cq7_head_ptr,
	output	[7:0]							io_cq8_head_ptr,
	output	[8:0]							cq_head_update,
	
	input   [31:0]                          cfg_mgmt_do,
	
////////////////////////////////////////////////////////////////
//AXI4 master interface signals
    input                                    m_axi_aclk,
    input                                    m_axi_aresetn,

// Write address channel
    output    [C_M_AXI_ID_WIDTH-1:0]            m_axi_awid,
    output    [C_M_AXI_ADDR_WIDTH-1:0]        m_axi_awaddr,
    output    [7:0]                            m_axi_awlen,
    output    [2:0]                            m_axi_awsize,
    output    [1:0]                            m_axi_awburst,
    output    [1:0]                            m_axi_awlock,
    output    [3:0]                            m_axi_awcache,
    output    [2:0]                            m_axi_awprot,
    output    [3:0]                            m_axi_awregion,
    output    [3:0]                            m_axi_awqos,
    output    [C_M_AXI_AWUSER_WIDTH-1:0]        m_axi_awuser,
    output                                    m_axi_awvalid,
    input                                    m_axi_awready,

// Write data channel
    output    [C_M_AXI_ID_WIDTH-1:0]            m_axi_wid,
    output    [C_M_AXI_DATA_WIDTH-1:0]        m_axi_wdata,
    output    [(C_M_AXI_DATA_WIDTH/8)-1:0]    m_axi_wstrb,
    output                                    m_axi_wlast,
    output    [C_M_AXI_WUSER_WIDTH-1:0]        m_axi_wuser,
    output                                    m_axi_wvalid,
    input                                    m_axi_wready,

// Write response channel
    input    [C_M_AXI_ID_WIDTH-1:0]            m_axi_bid,
    input    [1:0]                            m_axi_bresp,
    input                                    m_axi_bvalid,
    input    [C_M_AXI_BUSER_WIDTH-1:0]        m_axi_buser,
    output                                    m_axi_bready,

// Read address channel
    output    [C_M_AXI_ID_WIDTH-1:0]            m_axi_arid,
    output    [C_M_AXI_ADDR_WIDTH-1:0]        m_axi_araddr,
    output    [7:0]                            m_axi_arlen,
    output    [2:0]                            m_axi_arsize,
    output    [1:0]                            m_axi_arburst,
    output    [1:0]                            m_axi_arlock,
    output    [3:0]                            m_axi_arcache,
    output    [2:0]                            m_axi_arprot,
    output    [3:0]                            m_axi_arregion,
    output    [3:0]                             m_axi_arqos,
    output    [C_M_AXI_ARUSER_WIDTH-1:0]        m_axi_aruser,
    output                                    m_axi_arvalid,
    input                                    m_axi_arready,

// Read data channel
    input    [C_M_AXI_ID_WIDTH-1:0]            m_axi_rid,
    input    [C_M_AXI_DATA_WIDTH-1:0]        m_axi_rdata,
    input    [1:0]                            m_axi_rresp,
    input                                    m_axi_rlast,
    input    [C_M_AXI_RUSER_WIDTH-1:0]        m_axi_ruser,
    input                                    m_axi_rvalid,
    output                                     m_axi_rready
);

wire										w_mreq_fifo_rd_en;
wire	[C_PCIE_DATA_WIDTH+8-1:0]			w_mreq_fifo_rd_data;
wire										w_mreq_fifo_empty_n;

// DRAM
wire    [31:0]                              ddr_addr;
wire                                        ddr_rd_wait;
wire                                        ddr_rd_done;
wire                                        ddr_rd_recv;
wire    [63:0]                              ddr_rd_data;

wire                                        ddr_wr_fifo_wr_en;
wire    [127:0]                             ddr_wr_fifo_wr_data;
wire                                        ddr_wr_fifo_full_n;                               

wire                                        ddr_wr_fifo_rd_en;
wire    [127:0]                             ddr_wr_fifo_rd_data;
wire                                        ddr_wr_fifo_empty_n;

pcie_cntl_reg # (
	.C_PCIE_DATA_WIDTH						(C_PCIE_DATA_WIDTH)
)
pcie_cntl_reg_inst0(

	.pcie_user_clk							(pcie_user_clk),
	.pcie_user_rst_n						(pcie_user_rst_n),

	.rx_np_ok								(),
	.rx_np_req								(rx_np_req),
	
	.mreq_fifo_rd_en						(w_mreq_fifo_rd_en),
	.mreq_fifo_rd_data						(w_mreq_fifo_rd_data),
	.mreq_fifo_empty_n						(w_mreq_fifo_empty_n),

	.tx_cpld_req							(tx_cpld_req),
	.tx_cpld_tag							(tx_cpld_tag),
	.tx_cpld_req_id							(tx_cpld_req_id),
	.tx_cpld_len							(tx_cpld_len),
	.tx_cpld_bc								(tx_cpld_bc),
	.tx_cpld_laddr							(tx_cpld_laddr),
	.tx_cpld_data							(tx_cpld_data),
	.tx_cpld_req_ack						(tx_cpld_req_ack),

	.nvme_cc_en								(nvme_cc_en),
	.nvme_cc_shn							(nvme_cc_shn),

	.nvme_csts_shst							(nvme_csts_shst),
	.nvme_csts_rdy							(nvme_csts_rdy),

	.nvme_intms_ivms						(nvme_intms_ivms),
	.nvme_intmc_ivmc						(nvme_intmc_ivmc),
	.cq_irq_status							(cq_irq_status),

	.sq_rst_n								(sq_rst_n),
	.cq_rst_n								(cq_rst_n),
	.admin_sq_bs_addr						(admin_sq_bs_addr),
	.admin_cq_bs_addr						(admin_cq_bs_addr),
	.admin_sq_size							(admin_sq_size),
	.admin_cq_size							(admin_cq_size),

	.admin_sq_tail_ptr						(admin_sq_tail_ptr),
	.io_sq1_tail_ptr						(io_sq1_tail_ptr),
	.io_sq2_tail_ptr						(io_sq2_tail_ptr),
	.io_sq3_tail_ptr						(io_sq3_tail_ptr),
	.io_sq4_tail_ptr						(io_sq4_tail_ptr),
	.io_sq5_tail_ptr						(io_sq5_tail_ptr),
	.io_sq6_tail_ptr						(io_sq6_tail_ptr),
	.io_sq7_tail_ptr						(io_sq7_tail_ptr),
	.io_sq8_tail_ptr						(io_sq8_tail_ptr),

	.admin_cq_head_ptr						(admin_cq_head_ptr),
	.io_cq1_head_ptr						(io_cq1_head_ptr),
	.io_cq2_head_ptr						(io_cq2_head_ptr),
	.io_cq3_head_ptr						(io_cq3_head_ptr),
	.io_cq4_head_ptr						(io_cq4_head_ptr),
	.io_cq5_head_ptr						(io_cq5_head_ptr),
	.io_cq6_head_ptr						(io_cq6_head_ptr),
	.io_cq7_head_ptr						(io_cq7_head_ptr),
	.io_cq8_head_ptr						(io_cq8_head_ptr),
	.cq_head_update							(cq_head_update),
	
	.bar3_addr									(cfg_mgmt_do),
    
    .ddr_addr                              (ddr_addr),
    .ddr_rd_wait                            (ddr_rd_wait),
    .ddr_rd_done                           (ddr_rd_done),
    .ddr_rd_recv                            (ddr_rd_recv),
    .ddr_rd_data                           (ddr_rd_data),
    
    .ddr_wr_fifo_wr_en                       (ddr_wr_fifo_wr_en),
    .ddr_wr_fifo_wr_data                     (ddr_wr_fifo_wr_data),
    .ddr_wr_fifo_full_n                      (ddr_wr_fifo_full_n)
);

pcie_cntl_rx_fifo
pcie_cntl_rx_fifo_inst0(
	.clk									(pcie_user_clk),
	.rst_n									(pcie_user_rst_n),

////////////////////////////////////////////////////////////////
//bram fifo write signals
	.wr_en									(mreq_fifo_wr_en),
	.wr_data								(mreq_fifo_wr_data),
	.full_n									(),
	.almost_full_n							(rx_np_ok),
////////////////////////////////////////////////////////////////
//bram fifo read signals
	.rd_en									(w_mreq_fifo_rd_en),
	.rd_data								(w_mreq_fifo_rd_data),
	.empty_n								(w_mreq_fifo_empty_n)
);

pcie_cntl_m_axi_read # (
    	.C_M_AXI_ADDR_WIDTH            (C_M_AXI_ADDR_WIDTH),
        .C_M_AXI_DATA_WIDTH            (C_M_AXI_DATA_WIDTH),
        .C_M_AXI_ID_WIDTH            (C_M_AXI_ID_WIDTH),
        .C_M_AXI_ARUSER_WIDTH            (C_M_AXI_ARUSER_WIDTH),
        .C_M_AXI_RUSER_WIDTH            (C_M_AXI_RUSER_WIDTH),
        .C_M_AXI_BASSADDR               (C_M_AXI_BASSADDR)
)
pcie_cntl_m_axi_read_inst0(
        .m_axi_aclk            (m_axi_aclk),
        .m_axi_aresetn            (m_axi_aresetn),
        
        .m_axi_arid            (m_axi_arid),
        .m_axi_araddr            (m_axi_araddr),
        .m_axi_arlen            (m_axi_arlen),
        .m_axi_arsize            (m_axi_arsize),
        .m_axi_arburst            (m_axi_arburst),
        .m_axi_arlock            (m_axi_arlock),
        .m_axi_arcache            (m_axi_arcache),
        .m_axi_arprot            (m_axi_arprot),
        .m_axi_arregion            (m_axi_arregion),
        .m_axi_arqos            (m_axi_arqos),
        .m_axi_aruser            (m_axi_aruser),
        .m_axi_arvalid            (m_axi_arvalid),
        .m_axi_arready            (m_axi_arready),
        
        .m_axi_rid            (m_axi_rid),
        .m_axi_rdata            (m_axi_rdata),
        .m_axi_rresp            (m_axi_rresp),
        .m_axi_rlast            (m_axi_rlast),
        .m_axi_ruser            (m_axi_ruser),
        .m_axi_rvalid            (m_axi_rvalid),
        .m_axi_rready            (m_axi_rready),
        
        .ddr_addr            (ddr_addr),
        .ddr_rd_wait             (ddr_rd_wait),
        .ddr_rd_done            (ddr_rd_done),
        .ddr_rd_recv            (ddr_rd_recv),
        .ddr_rd_data                   (ddr_rd_data) 
);

pcie_cntl_m_axi_write_fifo
pcie_cntl_m_axi_write_fifo_inst0(
        .wr_clk                  (pcie_user_clk),
        .wr_rst_n                (pcie_user_rst_n),

        .wr_en                   (ddr_wr_fifo_wr_en),
        .wr_data                 (ddr_wr_fifo_wr_data),
        .full_n                  (ddr_wr_fifo_full_n),

        .rd_clk                  (m_axi_aclk),
        .rd_rst_n                (m_axi_aresetn),

        .rd_en                   (ddr_wr_fifo_rd_en),
        .rd_data                 (ddr_wr_fifo_rd_data),
        .empty_n                 (ddr_wr_fifo_empty_n)
);

pcie_cntl_m_axi_write # (
    	.C_M_AXI_ADDR_WIDTH            (C_M_AXI_ADDR_WIDTH),
        .C_M_AXI_DATA_WIDTH            (C_M_AXI_DATA_WIDTH),
        .C_M_AXI_ID_WIDTH            (C_M_AXI_ID_WIDTH),
        .C_M_AXI_AWUSER_WIDTH            (C_M_AXI_AWUSER_WIDTH),
        .C_M_AXI_WUSER_WIDTH            (C_M_AXI_WUSER_WIDTH),
        .C_M_AXI_BUSER_WIDTH            (C_M_AXI_BUSER_WIDTH),
        .C_M_AXI_BASSADDR               (C_M_AXI_BASSADDR)
)
pcie_cntl_m_axi_write_inst0(
        .m_axi_aclk                                (m_axi_aclk),
        .m_axi_aresetn                            (m_axi_aresetn),

        .m_axi_awid                                (m_axi_awid),
        .m_axi_awaddr                            (m_axi_awaddr),
        .m_axi_awlen                            (m_axi_awlen),
        .m_axi_awsize                            (m_axi_awsize),
        .m_axi_awburst                            (m_axi_awburst),
        .m_axi_awlock                            (m_axi_awlock),
        .m_axi_awcache                            (m_axi_awcache),
        .m_axi_awprot                            (m_axi_awprot),
        .m_axi_awregion                            (m_axi_awregion),
        .m_axi_awqos                            (m_axi_awqos),
        .m_axi_awuser                            (m_axi_awuser),
        .m_axi_awvalid                            (m_axi_awvalid),
        .m_axi_awready                            (m_axi_awready),

        .m_axi_wid                                (m_axi_wid),
        .m_axi_wdata                            (m_axi_wdata),
        .m_axi_wstrb                            (m_axi_wstrb),
        .m_axi_wlast                            (m_axi_wlast),
        .m_axi_wuser                            (m_axi_wuser),
        .m_axi_wvalid                            (m_axi_wvalid),
        .m_axi_wready                            (m_axi_wready),

        .m_axi_bid                                (m_axi_bid),
        .m_axi_bresp                            (m_axi_bresp),
        .m_axi_bvalid                            (m_axi_bvalid),
        .m_axi_buser                            (m_axi_buser),
        .m_axi_bready                            (m_axi_bready),

        .ddr_wr_fifo_rd_en                       (ddr_wr_fifo_rd_en),
        .ddr_wr_fifo_rd_data                      (ddr_wr_fifo_rd_data),
        .ddr_wr_fifo_empty_n                     (ddr_wr_fifo_empty_n)
);

endmodule