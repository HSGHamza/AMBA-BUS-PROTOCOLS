`timescale 1ns/1ps

module axi_tb;

reg        aclck;
reg        aresetn;
reg        start_read;
reg        start_write;
reg [31:0] address;
reg [31:0] W_data;
wire [31:0] R;

axi_top dut (
    .aclck(aclck), .aresetn(aresetn),
    .start_read(start_read), .start_write(start_write),
    .address(address), .W_data(W_data), .R(R)
);

always #5 aclck = ~aclck;

initial begin
    aclck       = 1'b0;
    aresetn     = 1'b0;
    start_read  = 1'b0;
    start_write = 1'b0;
    address     = 32'b0;
    W_data      = 32'b0;

    #12;
    aresetn = 1'b1;

    @(posedge aclck);
    address     = 32'h00000000;
    W_data      = 32'h5A5AA5A5;
    start_write = 1'b1;

    @(posedge aclck);
    start_write = 1'b0;

    repeat (8) @(posedge aclck);

    start_read = 1'b1;

    @(posedge aclck);
    start_read = 1'b0;

    repeat (6) @(posedge aclck);

    if (R == 32'h5A5AA5A5)
        $display("TEST PASSED: R = %h", R);
    else
        $display("TEST FAILED: R = %h", R);

    $finish;
end

endmodule
