`timescale 1ns / 1ps

module tb_dma_top;

    reg         clk;
    reg         rst;
    reg         start_transfer;
    reg  [31:0] src_addr_init;
    reg  [31:0] dst_addr_init;
    reg  [31:0] length_init;

    wire        dma_busy;
    wire        dma_done;
    wire        dma_error;
    wire        irq;

    dma_top uut (
        .clk(clk),
        .rst(rst),
        .start_transfer(start_transfer),
        .src_addr_init(src_addr_init),
        .dst_addr_init(dst_addr_init),
        .length_init(length_init),
        .dma_busy(dma_busy),
        .dma_done(dma_done),
        .dma_error(dma_error),
        .irq(irq)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("dma_top.vcd");
        $dumpvars(0, tb_dma_top);

        clk = 0;
        rst = 0;
        start_transfer = 0;
        src_addr_init = 32'h00000000;
        dst_addr_init = 32'h00000040;
        length_init = 32'd4;

        uut.u_ram.mem[0] = 32'hDEADBEEF;
        uut.u_ram.mem[1] = 32'hCAFEBABE;
        uut.u_ram.mem[2] = 32'h12345678;
        uut.u_ram.mem[3] = 32'hAABBCCDD;

        uut.u_ram.mem[16] = 32'h00000000;
        uut.u_ram.mem[17] = 32'h00000000;
        uut.u_ram.mem[18] = 32'h00000000;
        uut.u_ram.mem[19] = 32'h00000000;

        #20;
        rst = 1;

        #20;
        @(posedge clk);
        start_transfer <= 1'b1;

        @(posedge clk);
        start_transfer <= 1'b0;

        @(posedge irq);
        #40;

        $finish;
    end

endmodule
