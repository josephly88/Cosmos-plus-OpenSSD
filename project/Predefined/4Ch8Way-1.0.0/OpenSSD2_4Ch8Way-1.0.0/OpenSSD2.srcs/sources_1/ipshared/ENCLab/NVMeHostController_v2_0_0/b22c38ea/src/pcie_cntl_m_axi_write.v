`timescale 1ns / 1ps

`include	"def_axi.vh"

module pcie_cntl_m_axi_write # (
	parameter	C_M_AXI_ADDR_WIDTH			= 32,
    parameter    C_M_AXI_DATA_WIDTH            = 64,
    parameter    C_M_AXI_ID_WIDTH            = 1,
    parameter    C_M_AXI_AWUSER_WIDTH        = 1,
    parameter    C_M_AXI_WUSER_WIDTH            = 1,
    parameter    C_M_AXI_BUSER_WIDTH            = 1,
    parameter    C_M_AXI_BASSADDR            = 32'h0
)
(
////////////////////////////////////////////////////////////////
//AXI4 master write channel signal
	input									m_axi_aclk,
	input									m_axi_aresetn,

	// Write address channel
	output	[C_M_AXI_ID_WIDTH-1:0]			m_axi_awid,
	output	[C_M_AXI_ADDR_WIDTH-1:0]		m_axi_awaddr,
	output	[7:0]							m_axi_awlen,
	output	[2:0]							m_axi_awsize,
	output	[1:0]							m_axi_awburst,
	output	[1:0]							m_axi_awlock,
	output	[3:0]							m_axi_awcache,
	output	[2:0]							m_axi_awprot,
	output	[3:0]							m_axi_awregion,
	output	[3:0]							m_axi_awqos,
	output	[C_M_AXI_AWUSER_WIDTH-1:0]		m_axi_awuser,
	output									m_axi_awvalid,
	input									m_axi_awready,

// Write data channel
	output	[C_M_AXI_ID_WIDTH-1:0]			m_axi_wid,
	output	[C_M_AXI_DATA_WIDTH-1:0]		m_axi_wdata,
	output	[(C_M_AXI_DATA_WIDTH/8)-1:0]	m_axi_wstrb,
	output									m_axi_wlast,
	output	[C_M_AXI_WUSER_WIDTH-1:0]		m_axi_wuser,
	output									m_axi_wvalid,
	input									m_axi_wready,

// Write response channel
	input	[C_M_AXI_ID_WIDTH-1:0]			m_axi_bid,
	input	[1:0]							m_axi_bresp,
	input									m_axi_bvalid,
	input	[C_M_AXI_BUSER_WIDTH-1:0]		m_axi_buser,
	output									m_axi_bready,

// Created port	
	output                                  ddr_wr_fifo_rd_en,
	input   [127:0]                         ddr_wr_fifo_rd_data,
	input                                   ddr_wr_fifo_empty_n
);

localparam  S_IDLE                          = 5'b00001;
localparam  S_FIFO_DATA                     = 5'b00010;
localparam  S_AW_REQ                        = 5'b00100;
localparam  S_W_DATA                        = 5'b01000;
localparam  S_W_DONE                        = 5'b10000;

reg [4:0]                                   cur_state;
reg [4:0]                                   next_state;

reg                                         r_m_axi_awvalid;
reg		[C_M_AXI_DATA_WIDTH-1:0]            r_m_axi_wdata;
reg                                         r_m_axi_wlast;
reg                                         r_m_axi_wvalid;

wire	[63:0]								w_one_padding;

reg                                         r_ddr_wr_fifo_rd_en;
reg     [127:0]                             r_ddr_wr_fifo_rd_data;

wire    [31:0]                              w_ddr_addr;
wire    [63:0]                              w_ddr_wr_data;
wire    [7:0]                               w_ddr_wr_we;

assign m_axi_awid = 0;
assign m_axi_awaddr = {w_ddr_addr[31:2], 2'b0} + C_M_AXI_BASSADDR;
assign m_axi_awlen = 8'h0;
assign m_axi_awsize = `D_AXSIZE_008_BYTES;
assign m_axi_awburst = `D_AXBURST_INCR;
assign m_axi_awlock = `D_AXLOCK_NORMAL;
assign m_axi_awcache = `D_AXCACHE_NON_CACHE;
assign m_axi_awprot = `D_AXPROT_SECURE;
assign m_axi_awregion = 0;
assign m_axi_awqos = 0;
assign m_axi_awuser = 0;
assign m_axi_awvalid = r_m_axi_awvalid;

assign m_axi_wid = 0;
assign m_axi_wdata = w_ddr_wr_data;
assign m_axi_wstrb = w_ddr_wr_we;
assign m_axi_wlast = r_m_axi_wlast;
assign m_axi_wuser = 0;
assign m_axi_wvalid = r_m_axi_wvalid;

assign m_axi_bready = 1;

assign ddr_wr_fifo_rd_en = r_ddr_wr_fifo_rd_en;

assign w_ddr_wr_data = r_ddr_wr_fifo_rd_data[127:64];
assign w_ddr_addr = r_ddr_wr_fifo_rd_data[63:32];
assign w_ddr_wr_we = r_ddr_wr_fifo_rd_data[7:0];

always @ (posedge m_axi_aclk or negedge m_axi_aresetn)
begin
	if(m_axi_aresetn == 0)
		cur_state <= S_IDLE;
	else
		cur_state <= next_state;
end

always @ (*)
begin
    case(cur_state)
        S_IDLE: begin
            if(ddr_wr_fifo_empty_n == 1)
                next_state <= S_FIFO_DATA;
            else
                next_state <= S_IDLE;
        end
        S_FIFO_DATA: begin
            next_state <= S_AW_REQ;
        end
        S_AW_REQ: begin
            if(m_axi_awready == 1)
                next_state <= S_W_DATA;
            else
                next_state <= S_AW_REQ;
        end
        S_W_DATA: begin
            if(m_axi_wready == 1)
                next_state <= S_W_DONE;
            else
                next_state <= S_W_DATA;
        end
        S_W_DONE: begin
            next_state <= S_IDLE;
        end
        default: begin
            next_state <= S_IDLE;
        end
    endcase
end

always @ (*)
begin
    case(cur_state)
        S_IDLE: begin
            r_m_axi_awvalid <= 0;
            r_m_axi_wlast <= 0;
            r_m_axi_wvalid <= 0;
            r_ddr_wr_fifo_rd_en <= 0;
        end
        S_FIFO_DATA: begin
            r_m_axi_awvalid <= 0;
            r_m_axi_wlast <= 0;
            r_m_axi_wvalid <= 0;
            r_ddr_wr_fifo_rd_en <= 1;
        end
        S_AW_REQ: begin
            r_m_axi_awvalid <= 1;
            r_m_axi_wlast <= 0;
            r_m_axi_wvalid <= 0;
            r_ddr_wr_fifo_rd_en <= 0;
        end
        S_W_DATA: begin
            r_m_axi_awvalid <= 0;
            r_m_axi_wlast <= 1;
            r_m_axi_wvalid <= 1;
            r_ddr_wr_fifo_rd_en <= 0;
        end
        S_W_DONE: begin
            r_m_axi_awvalid <= 0;
            r_m_axi_wlast <= 0;
            r_m_axi_wvalid <= 0;
            r_ddr_wr_fifo_rd_en <= 0;
        end
        default: begin
            r_m_axi_awvalid <= 0;
            r_m_axi_wlast <= 0;
            r_m_axi_wvalid <= 0;
            r_ddr_wr_fifo_rd_en <= 0;
        end
    endcase
end

always @ (posedge m_axi_aclk)
begin
    case(cur_state)
        S_IDLE: begin
        
        end
        S_FIFO_DATA: begin
            r_ddr_wr_fifo_rd_data <= ddr_wr_fifo_rd_data;
        end
        S_AW_REQ: begin
        
        end
        S_W_DATA: begin
        
        end
        S_W_DONE: begin
        
        end
        default: begin
        
        end
    endcase
end

endmodule