module axi_slave (
    input  wire        aclck,
    input  wire        aresetn,
    input  wire [31:0] AW,
    input  wire        awvalid,
    input  wire [31:0] W,
    input  wire        wvalid,
    input  wire        bready,
    input  wire [31:0] AR,
    input  wire        arvalid,
    input  wire        rready,
    output reg         awready,
    output reg         wready,
    output reg         bvalid,
    output reg         arready,
    output reg         rvalid,
    output reg [31:0]  R_data
);

reg [31:0] memory [0:15];
reg        aw_received;
reg        w_received;
reg [3:0]  aw_index;
reg [31:0] w_buffer;

always @(posedge aclck or negedge aresetn) begin
    if (!aresetn) begin
        awready     <= 1'b0;
        wready      <= 1'b0;
        bvalid      <= 1'b0;
        arready     <= 1'b0;
        rvalid      <= 1'b0;
        R_data      <= 32'b0;
        aw_received <= 1'b0;
        w_received  <= 1'b0;
        aw_index    <= 4'b0;
        w_buffer    <= 32'b0;
    end else begin
        awready <= !aw_received && !bvalid;
        wready  <= !w_received && !bvalid;
        arready <= !rvalid;

        if (awvalid && awready) begin
            aw_index    <= AW[5:2];
            aw_received <= 1'b1;
        end

        if (wvalid && wready) begin
            w_buffer   <= W;
            w_received <= 1'b1;
        end

        if (aw_received && w_received && !bvalid) begin
            memory[aw_index] <= w_buffer;
            bvalid           <= 1'b1;
            aw_received      <= 1'b0;
            w_received       <= 1'b0;
        end

        if (bvalid && bready)
            bvalid <= 1'b0;

        if (arvalid && arready) begin
            R_data <= memory[AR[5:2]];
            rvalid <= 1'b1;
        end

        if (rvalid && rready)
            rvalid <= 1'b0;
    end
end

endmodule
