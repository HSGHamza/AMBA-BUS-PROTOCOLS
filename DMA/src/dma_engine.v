module dma_engine (
    input  wire        clk,
    input  wire        rst,
    input  wire        start_transfer,
    input  wire [31:0] src_addr_init,
    input  wire [31:0] dst_addr_init,
    input  wire [31:0] length_init,
    output wire        dma_busy,
    output wire        dma_done,
    output wire        dma_error,
    output wire        irq,
    output wire        mem_en,
    output wire        mem_we,
    output reg  [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    input  wire [31:0] mem_rdata,
    input  wire        mem_ready
);

    wire [31:0] current_src_addr;
    wire [31:0] current_dst_addr;
    wire        bus_read_req;
    wire        bus_write_req;
    wire        transfer_done;
    wire        transfer_active;
    reg  [31:0] read_data_buffer;

    dma_fsm u_fsm (
        .clk(clk),
        .rst(rst),
        .start_transfer(start_transfer),
        .src_addr_init(src_addr_init),
        .dst_addr_init(dst_addr_init),
        .length_init(length_init),
        .bus_op_done(mem_ready),
        .current_src_addr(current_src_addr),
        .current_dst_addr(current_dst_addr),
        .bus_read_req(bus_read_req),
        .bus_write_req(bus_write_req),
        .transfer_done(transfer_done),
        .transfer_active(transfer_active),
        .read_data_buffer(read_data_buffer)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            read_data_buffer <= 32'd0;
        end else if (bus_read_req && mem_ready) begin
            read_data_buffer <= mem_rdata;
        end
    end

    always @(*) begin
        if (bus_read_req)
            mem_addr = current_src_addr;
        else if (bus_write_req)
            mem_addr = current_dst_addr;
        else
            mem_addr = 32'd0;
    end

    assign mem_en    = bus_read_req | bus_write_req;
    assign mem_we    = bus_write_req;
    assign mem_wdata = read_data_buffer;

    assign dma_busy  = transfer_active;
    assign dma_done  = transfer_done;
    assign dma_error = 1'b0;
    assign irq       = transfer_done;

endmodule
