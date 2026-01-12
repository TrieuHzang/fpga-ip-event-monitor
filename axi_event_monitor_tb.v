`timescale 1ns / 1ps

module axi_event_monitor_tb;

    /* ================= CLOCK / RESET ================= */
    reg clk;
    reg resetn;

    always #5 clk = ~clk;   // 100 MHz

    /* ================= EVENT ================= */
    reg  event_in;
    wire irq;

    /* ================= AXI SIGNALS ================= */
    reg  [5:0]  awaddr;
    reg         awvalid;
    wire        awready;

    reg  [31:0] wdata;
    reg         wvalid;
    wire        wready;

    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;

    reg  [5:0]  araddr;
    reg         arvalid;
    wire        arready;

    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;

    /* ================= DUT ================= */
    axi_event_monitor_v1_0_S_AXI dut (
        .event_in(event_in),
        .irq(irq),

        .S_AXI_ACLK(clk),
        .S_AXI_ARESETN(resetn),

        .S_AXI_AWADDR(awaddr),
        .S_AXI_AWVALID(awvalid),
        .S_AXI_AWREADY(awready),

        .S_AXI_WDATA(wdata),
        .S_AXI_WVALID(wvalid),
        .S_AXI_WREADY(wready),

        .S_AXI_BRESP(bresp),
        .S_AXI_BVALID(bvalid),
        .S_AXI_BREADY(bready),

        .S_AXI_ARADDR(araddr),
        .S_AXI_ARVALID(arvalid),
        .S_AXI_ARREADY(arready),

        .S_AXI_RDATA(rdata),
        .S_AXI_RRESP(rresp),
        .S_AXI_RVALID(rvalid),
        .S_AXI_RREADY(rready)
    );

    /* ================= AXI WRITE TASK ================= */
    task axi_write;
        input [5:0] addr;
        input [31:0] data;
        begin
            @(posedge clk);
            awaddr  <= addr;
            awvalid <= 1;
            wdata   <= data;
            wvalid  <= 1;
            bready  <= 1;

            wait (awready && wready);
            @(posedge clk);
            awvalid <= 0;
            wvalid  <= 0;

            wait (bvalid);
            @(posedge clk);
            bready <= 0;
        end
    endtask

    /* ================= AXI READ TASK ================= */
    task axi_read;
        input  [5:0] addr;
        begin
            @(posedge clk);
            araddr  <= addr;
            arvalid <= 1;
            rready  <= 1;

            wait (arready);
            @(posedge clk);
            arvalid <= 0;

            wait (rvalid);
            @(posedge clk);
            rready <= 0;
        end
    endtask

    /* ================= EVENT GEN (SYNC CLOCK) ================= */
    task gen_event;
        begin
            @(posedge clk);
            event_in <= 1;
            @(posedge clk);
            event_in <= 0;
        end
    endtask

    /* ================= TEST SEQUENCE ================= */
    initial begin
        /* init */
        clk     = 0;
        resetn = 0;
        event_in = 0;

        awaddr = 0; awvalid = 0;
        wdata  = 0; wvalid  = 0;
        araddr = 0; arvalid = 0;
        bready = 0; rready  = 0;

        /* reset */
        #50;
        resetn = 1;

        /* ================= CONFIG IP ================= */
        axi_write(6'h00, 32'h1);  // reg_ctrl enable
        axi_write(6'h08, 32'h1);  // event enable
        axi_write(6'h0C, 32'h1);  // irq enable
        axi_write(6'h20, 32'd3);  // threshold = 3

        /* ================= GENERATE EVENTS ================= */
        gen_event;  // event 1
        gen_event;  // event 2
        gen_event;  // event 3 -> IRQ HIGH HERE

        /* ================= READ BACK ================= */
        axi_read(6'h10); // event count
        axi_read(6'h18); // timestamp low
        axi_read(6'h1C); // timestamp high
        axi_read(6'h24); // irq status

        #200;
        $finish;
    end

endmodule
