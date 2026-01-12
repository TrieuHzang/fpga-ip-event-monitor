`timescale 1 ns / 1 ps

module axi_event_monitor_v1_0 #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6
)
(
    input  wire event_in,
    output wire irq,

    input  wire s_axi_aclk,
    input  wire s_axi_aresetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire s_axi_awvalid,
    output wire s_axi_awready,

    input  wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire s_axi_wvalid,
    output wire s_axi_wready,

    output wire [1:0] s_axi_bresp,
    output wire s_axi_bvalid,
    input  wire s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire s_axi_arvalid,
    output wire s_axi_arready,

    output wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rvalid,
    input  wire s_axi_rready
);

axi_event_monitor_v1_0_S_AXI #(
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) axi_event_monitor_v1_0_S_AXI_inst (
    .event_in      (event_in),
    .irq           (irq),

    .S_AXI_ACLK    (s_axi_aclk),
    .S_AXI_ARESETN (s_axi_aresetn),

    .S_AXI_AWADDR  (s_axi_awaddr),
    .S_AXI_AWVALID (s_axi_awvalid),
    .S_AXI_AWREADY (s_axi_awready),

    .S_AXI_WDATA   (s_axi_wdata),
    .S_AXI_WVALID  (s_axi_wvalid),
    .S_AXI_WREADY  (s_axi_wready),

    .S_AXI_BRESP   (s_axi_bresp),
    .S_AXI_BVALID  (s_axi_bvalid),
    .S_AXI_BREADY  (s_axi_bready),

    .S_AXI_ARADDR  (s_axi_araddr),
    .S_AXI_ARVALID (s_axi_arvalid),
    .S_AXI_ARREADY (s_axi_arready),

    .S_AXI_RDATA   (s_axi_rdata),
    .S_AXI_RRESP   (s_axi_rresp),
    .S_AXI_RVALID  (s_axi_rvalid),
    .S_AXI_RREADY  (s_axi_rready)
);

endmodule
