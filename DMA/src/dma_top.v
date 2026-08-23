module dma_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        start_transfer,
    input  wire [31:0] src_addr_init,
    input  wire [31:0] dst_addr_init,
    input  wire [31:0] length_init,
    output wire        dma_busy,
    output wire        dma_done,
    output wire        dma_error,
    output wire        irq
);

    wire        mem_en;
    wire        mem_we;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [31:0] mem_rdata;
    wire        mem_ready;

    dma_engine u_dma (
        .clk(clk),
        .rst(rst),
        .start_transfer(start_transfer),
        .src_addr_init(src_addr_init),
        .dst_addr_init(dst_addr_init),
        .length_init(length_init),
        .dma_busy(dma_busy),
        .dma_done(dma_done),
        .dma_error(dma_error),
        .irq(irq),
        .mem_en(mem_en),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready)
    );

    ram u_ram (
        .clk(clk),
        .en(mem_en),
        .we(mem_we),
        .addr(mem_addr),
        .din(mem_wdata),
        .dout(mem_rdata),
        .ready(mem_ready)
    );

endmodule
