module top(

    input clk,
    input rst,
    input start,
    input rw,

    output [3:0] dataFpga,
    output valid,
    output ready

);

reg [7:0] dataout ;
reg [1:0] addr = 2'd1;
reg [7:0] datain = 8'd10;

wire valid_wire;
wire ready_wire;

wire [1:0] addr_wire;
wire rw_wire;
wire [7:0] data_wire;

master M1(

    .clk(clk),
    .rst(rst),
    .start(start),
    .ready(ready_wire),

    .addr_in(addr),
    .rw_in(rw),
    .data_in(datain),

    .valid(valid_wire),
    .addr(addr_wire),
    .rw(rw_wire),
    .datain(data_wire)

);

slave S1(

    .clk(clk),
    .rst(rst),

    .valid(valid_wire),
    .rw(rw_wire),

    .addr(addr_wire),
    .datain(data_wire),

    .ready(ready_wire),
    .dataout(dataout)

);

assign valid = valid_wire;
assign ready = ready_wire;
assign dataFpga = dataout[3:0];

endmodule
