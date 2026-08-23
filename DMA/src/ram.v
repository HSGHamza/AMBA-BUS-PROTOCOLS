module ram (
    input  wire        clk,
    input  wire        en,
    input  wire        we,
    input  wire [31:0] addr,
    input  wire [31:0] din,
    output reg  [31:0] dout,
    output reg         ready
);

    reg [31:0] mem [0:255];

    always @(posedge clk) begin
        if (en) begin
            if (we) begin
                mem[addr[9:2]] <= din;
            end
            dout  <= mem[addr[9:2]];
            ready <= 1'b1;
        end else begin
            ready <= 1'b0;
        end
    end

endmodule
