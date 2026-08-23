module axi_top (
    input  wire        aclck,
    input  wire        aresetn,
    input  wire        start_read,
    input  wire        start_write,
    input  wire [31:0] address,
    input  wire [31:0] W_data,
    output wire [31:0] R
);

wire        awvalid;
wire        wvalid;
wire        bready;
wire        arvalid;
wire        rready;
wire        awready;
wire        wready;
wire        bvalid;
wire        arready;
wire        rvalid;
wire [31:0] AW;
wire [31:0] W;
wire [31:0] AR;
wire [31:0] R_data;

axi_master master (
    .aclck(aclck), .aresetn(aresetn),
    .start_read(start_read), .start_write(start_write),
    .address(address), .W_data(W_data),
    .awready(awready), .wready(wready), .bvalid(bvalid),
    .arready(arready), .rvalid(rvalid), .R_data(R_data),
    .awvalid(awvalid), .wvalid(wvalid), .bready(bready),
    .arvalid(arvalid), .rready(rready),
    .AW(AW), .W(W), .AR(AR), .R(R)
);

axi_slave slave (
    .aclck(aclck), .aresetn(aresetn),
    .AW(AW), .awvalid(awvalid), .W(W), .wvalid(wvalid),
    .bready(bready), .AR(AR), .arvalid(arvalid), .rready(rready),
    .awready(awready), .wready(wready), .bvalid(bvalid),
    .arready(arready), .rvalid(rvalid), .R_data(R_data)
);

endmodule
