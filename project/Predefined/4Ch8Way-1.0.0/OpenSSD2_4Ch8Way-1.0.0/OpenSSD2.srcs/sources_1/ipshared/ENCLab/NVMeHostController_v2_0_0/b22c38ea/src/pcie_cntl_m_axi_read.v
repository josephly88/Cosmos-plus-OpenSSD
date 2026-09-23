`timescale 1ns / 1ps

`include	"def_axi.vh"

module pcie_cntl_m_axi_read # (
	parameter	C_M_AXI_ADDR_WIDTH			= 32,
    parameter    C_M_AXI_DATA_WIDTH            = 64,
    parameter    C_M_AXI_ID_WIDTH            = 1,
    parameter    C_M_AXI_ARUSER_WIDTH        = 1,
    parameter    C_M_AXI_RUSER_WIDTH            = 1,
    parameter    C_M_AXI_BASSADDR           = 32'h0
)
(
////////////////////////////////////////////////////////////////
//AXI4 master read channel signals
	input									m_axi_aclk,
	input									m_axi_aresetn,

// Read address channel
	output	[C_M_AXI_ID_WIDTH-1:0]			m_axi_arid,
	output	[C_M_AXI_ADDR_WIDTH-1:0]		m_axi_araddr,
	output	[7:0]							m_axi_arlen,
	output	[2:0]							m_axi_arsize,
	output	[1:0]							m_axi_arburst,
	output	[1:0]							m_axi_arlock,
	output	[3:0]							m_axi_arcache,
	output	[2:0]							m_axi_arprot,
	output	[3:0]							m_axi_arregion,
	output	[3:0] 							m_axi_arqos,
	output	[C_M_AXI_ARUSER_WIDTH-1:0]		m_axi_aruser,
	output									m_axi_arvalid,
	input									m_axi_arready,

// Read data channel
	input	[C_M_AXI_ID_WIDTH-1:0]			m_axi_rid,
	input	[C_M_AXI_DATA_WIDTH-1:0]		m_axi_rdata,
	input	[1:0]							m_axi_rresp,
	input									m_axi_rlast,
	input	[C_M_AXI_RUSER_WIDTH-1:0]		m_axi_ruser,
	input									m_axi_rvalid,
	output 									m_axi_rready,

// Created port
    input   [31:0]                          ddr_addr,
	input                                   ddr_rd_wait,
	output                                  ddr_rd_done,
	input                                   ddr_rd_recv,
    output  [C_M_AXI_DATA_WIDTH-1:0]        ddr_rd_data
);

localparam  S_IDLE                          = 3'b001;
localparam  S_AR_REQ                        = 3'b010;
localparam  S_AR_DONE                       = 3'b100;

reg  [2:0]                                  cur_state;
reg  [2:0]                                  next_state;

reg                                         r_arvalid;
reg                                         rd_done;
reg  [C_M_AXI_DATA_WIDTH-1:0]               r_m_axi_rdata;

reg  [31:0]                                 r_ddr_addr;
reg  [31:0]                                 r_ddr_addr_p1;
reg                                         r_ddr_rd_wait;
reg                                         r_ddr_rd_wait_p1;
reg                                         r_ddr_rd_recv;
reg                                         r_ddr_rd_recv_p1;

// Read address channel
assign m_axi_arid = 0;
assign m_axi_araddr = {r_ddr_addr[31:2], 2'b0} + C_M_AXI_BASSADDR;
assign m_axi_arlen = 8'h0;
assign m_axi_arsize = `D_AXSIZE_008_BYTES;
assign m_axi_arburst = `D_AXBURST_INCR;
assign m_axi_arlock = `D_AXLOCK_NORMAL;
assign m_axi_arcache = `D_AXCACHE_NON_CACHE;
assign m_axi_arprot = `D_AXPROT_SECURE;
assign m_axi_arregion = 0;
assign m_axi_arqos = 0;
assign m_axi_aruser = 0;
assign m_axi_arvalid = r_arvalid;
assign m_axi_rready = 1;

assign ddr_rd_done = rd_done;
assign ddr_rd_data = r_m_axi_rdata;

always @ (posedge m_axi_aclk or negedge m_axi_aresetn)
begin
	if(m_axi_aresetn == 0)
		cur_state <= S_IDLE;
	else
		cur_state <= next_state;
end

// Double Flop input signal from pcie_cntl_reg.v
always @ (posedge m_axi_aclk or negedge m_axi_aresetn)
begin
	if(m_axi_aresetn == 0) begin
	    r_ddr_addr <= 32'b0;
	    r_ddr_addr_p1 <= 32'b0;
		r_ddr_rd_wait_p1 <= 0;
		r_ddr_rd_wait <= 0;
		r_ddr_rd_recv <= 0;
		r_ddr_rd_recv_p1 <= 0;
	end
	else begin
	    r_ddr_addr_p1 <= ddr_addr;
	    r_ddr_addr <= r_ddr_addr_p1;
	
		r_ddr_rd_wait_p1 <= ddr_rd_wait;
        r_ddr_rd_wait <= r_ddr_rd_wait_p1;
        
        r_ddr_rd_recv_p1 <= ddr_rd_recv;
        r_ddr_rd_recv <= r_ddr_rd_recv_p1;
    end
end

// TEST
always @ (*)
begin
    case(cur_state)
        S_IDLE: begin
            if(r_ddr_rd_wait == 1)
                next_state <= S_AR_REQ;
            else
                next_state <= S_IDLE;
        end
        S_AR_REQ: begin
            if(m_axi_rvalid == 1)
                next_state <= S_AR_DONE;
            else
                next_state <= S_AR_REQ;
        end
        S_AR_DONE: begin
            if(r_ddr_rd_recv == 1)
                next_state <= S_IDLE;
            else
                next_state <= S_AR_DONE;
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
            r_arvalid <= 0;
            rd_done <= 0;
        end
        S_AR_REQ: begin
            r_arvalid <= 1;
            rd_done <= 0;
        end
        S_AR_DONE: begin
            r_arvalid <= 0;
            rd_done <= 1;
        end
        default: begin
            r_arvalid <= 0;
            rd_done <= 0;
        end
    endcase
end

always @ (posedge m_axi_aclk)
begin
    if(m_axi_rvalid == 1)
        r_m_axi_rdata <= m_axi_rdata;
    else
        r_m_axi_rdata <= r_m_axi_rdata;
end

endmodule