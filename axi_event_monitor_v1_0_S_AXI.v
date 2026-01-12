`timescale 1 ns / 1 ps

module axi_event_monitor_v1_0_S_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 6
)
(
    input  wire                     event_in,
    output wire                     irq,

    input  wire                     S_AXI_ACLK,
    input  wire                     S_AXI_ARESETN,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire                     S_AXI_AWVALID,
    output reg                      S_AXI_AWREADY,

    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire                     S_AXI_WVALID,
    output reg                      S_AXI_WREADY,

    output reg  [1:0]               S_AXI_BRESP,
    output reg                      S_AXI_BVALID,
    input  wire                     S_AXI_BREADY,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire                     S_AXI_ARVALID,
    output reg                      S_AXI_ARREADY,

    output reg  [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg  [1:0]               S_AXI_RRESP,
    output reg                      S_AXI_RVALID,
    input  wire                     S_AXI_RREADY
);

    localparam ADDR_LSB = 2;

    /* ================= AXI WRITE ================= */
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 0;
            S_AXI_WREADY  <= 0;
        end else begin
            S_AXI_AWREADY <= S_AXI_AWVALID;
            S_AXI_WREADY  <= S_AXI_WVALID;
        end
    end

    wire wr_en = S_AXI_AWVALID & S_AXI_WVALID & S_AXI_AWREADY & S_AXI_WREADY;

    /* ================= REGISTERS ================= */
    reg [31:0] reg_ctrl;       // 0x00 bit0: enable
    reg [31:0] reg_evt_en;     // 0x08
    reg [31:0] reg_irq_en;     // 0x0C
    reg [31:0] reg_evt_cnt;    // 0x10
    reg [31:0] reg_time_l;     // 0x18
    reg [31:0] reg_time_h;     // 0x1C
    reg [31:0] reg_threshold;  // 0x20
    reg        irq_reg;

    /* ================= WRITE REG ================= */
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            reg_ctrl      <= 0;
            reg_evt_en    <= 0;
            reg_irq_en    <= 0;
            reg_threshold <= 0;
        end else if (wr_en) begin
            case (S_AXI_AWADDR[ADDR_LSB +: 4])
                4'h0: reg_ctrl      <= S_AXI_WDATA;
                4'h2: reg_evt_en    <= S_AXI_WDATA;
                4'h3: reg_irq_en    <= S_AXI_WDATA;
                4'h8: reg_threshold <= S_AXI_WDATA;
                default: ;
            endcase
        end
    end

    /* ================= WRITE RESP ================= */
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 0;
            S_AXI_BRESP  <= 2'b00;
        end else if (wr_en) begin
            S_AXI_BVALID <= 1;
        end else if (S_AXI_BREADY) begin
            S_AXI_BVALID <= 0;
        end
    end

    /* ================= READ ================= */
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 0;
            S_AXI_RVALID  <= 0;
        end else begin
            S_AXI_ARREADY <= S_AXI_ARVALID;
            if (S_AXI_ARVALID && !S_AXI_RVALID) begin
                S_AXI_RVALID <= 1;
                S_AXI_RRESP  <= 2'b00;
                case (S_AXI_ARADDR[ADDR_LSB +: 4])
                    4'h0: S_AXI_RDATA <= reg_ctrl;
                    4'h2: S_AXI_RDATA <= reg_evt_en;
                    4'h3: S_AXI_RDATA <= reg_irq_en;
                    4'h4: S_AXI_RDATA <= reg_evt_cnt;
                    4'h6: S_AXI_RDATA <= reg_time_l;
                    4'h7: S_AXI_RDATA <= reg_time_h;
                    4'h8: S_AXI_RDATA <= reg_threshold;
                    4'h9: S_AXI_RDATA <= {31'd0, irq_reg};
                    default: S_AXI_RDATA <= 0;
                endcase
            end else if (S_AXI_RREADY) begin
                S_AXI_RVALID <= 0;
            end
        end
    end

    /* ================= EVENT LOGIC ================= */
    reg event_d;
    reg [63:0] timestamp;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            event_d   <= 0;
            timestamp <= 0;
        end else begin
            event_d   <= event_in;
            if (reg_ctrl[0])
                timestamp <= timestamp + 1;
        end
    end

    wire event_rise = event_in & ~event_d;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            reg_evt_cnt <= 0;
            irq_reg     <= 0;
        end else if (!reg_ctrl[0]) begin
            reg_evt_cnt <= 0;
            irq_reg     <= 0;
        end else if (event_rise && reg_evt_en[0]) begin
            reg_evt_cnt <= reg_evt_cnt + 1;
            reg_time_l  <= timestamp[31:0];
            reg_time_h  <= timestamp[63:32];

            if ((reg_evt_cnt + 1) >= reg_threshold && reg_irq_en[0])
                irq_reg <= 1;
        end
    end

    assign irq = irq_reg;

endmodule
