module AHB_Decoder (
    input             HCLK,
    input             HRESETn,
    input             HREADY,
    input      [31:0] HADDR,
    output reg [1:0]  HSELx_slaves,
    output reg [1:0]  HSELx_Mux
);

    always @(*) begin
        case (HADDR[31:30])
            2'b00:   HSELx_slaves = 2'b00;
            2'b01:   HSELx_slaves = 2'b01;
            default: HSELx_slaves = 2'b10;
        endcase
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            HSELx_Mux <= 2'b00;
        else if (HREADY)
            HSELx_Mux <= HSELx_slaves;
    end

endmodule
