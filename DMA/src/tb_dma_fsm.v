`timescale 1ns / 1ps

module tb_dma_fsm;

    reg         clk;
    reg         rst;
    reg         start_transfer;
    reg  [31:0] src_addr_init;
    reg  [31:0] dst_addr_init;
    reg  [31:0] length_init;
    reg         bus_op_done;
    reg  [31:0] read_data_buffer;

    wire [31:0] current_src_addr;
    wire [31:0] current_dst_addr;
    wire        bus_read_req;
    wire        bus_write_req;
    wire        transfer_done;
    wire        transfer_active;

    dma_fsm uut (
        .clk(clk),
        .rst(rst),
        .start_transfer(start_transfer),
        .src_addr_init(src_addr_init),
        .dst_addr_init(dst_addr_init),
        .length_init(length_init),
        .bus_op_done(bus_op_done),
        .current_src_addr(current_src_addr),
        .current_dst_addr(current_dst_addr),
        .bus_read_req(bus_read_req),
        .bus_write_req(bus_write_req),
        .transfer_done(transfer_done),
        .transfer_active(transfer_active),
        .read_data_buffer(read_data_buffer)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (bus_read_req || bus_write_req) begin
            #1;
            bus_op_done <= 1'b1;
        end else begin
            bus_op_done <= 1'b0;
        end
    end

    initial begin
        $dumpfile("dma_fsm.vcd");
        $dumpvars(0, tb_dma_fsm);

        clk = 0;
        rst = 0;
        start_transfer = 0;
        src_addr_init = 32'h00001000;
        dst_addr_init = 32'h00002000;
        length_init = 32'd4;
        bus_op_done = 0;
        read_data_buffer = 32'hA5A5A5A5;

        #20;
        rst = 1;

        #20;
        @(posedge clk);
        start_transfer <= 1'b1;

        @(posedge clk);
        start_transfer <= 1'b0;

        @(posedge transfer_done);
        #40;

        $finish;
    end

endmodule
