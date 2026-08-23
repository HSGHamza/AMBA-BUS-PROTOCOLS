module AHB_MUX (
    input             HCLK,
    input             HRESETn,

    input             HRESP_Slave_1,
    input             HREADYOUT_1,
    input      [31:0] HRDATA_Slave_1,

    input             HRESP_Slave_2,
    input             HREADYOUT_2,
    input      [31:0] HRDATA_Slave_2,

    input      [1:0]  HSELx_Mux,
    input      [1:0]  HTRANS,

    output reg [31:0] HRDATA,
    output reg        HREADY,
    output reg        HRESP
);

    reg err_state;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            err_state <= 1'b0;
        else begin
            if (HSELx_Mux == 2'b10) begin
                if (!err_state)
                    err_state <= 1'b1;
                else
                    err_state <= 1'b0;
            end else begin
                err_state <= 1'b0;
            end
        end
    end

    always @(*) begin
        case (HSELx_Mux)
            2'b00: begin
                HRDATA = HRDATA_Slave_1;
                HREADY = HREADYOUT_1;
                HRESP  = HRESP_Slave_1;
            end

            2'b01: begin
                HRDATA = HRDATA_Slave_2;
                HREADY = HREADYOUT_2;
                HRESP  = HRESP_Slave_2;
            end

            default: begin
                HRDATA = 32'h00000000;
                if (!err_state) begin
                    HREADY = 1'b0;
                    HRESP  = 1'b1;
                end else begin
                    HREADY = 1'b1;
                    HRESP  = 1'b1;
                end
            end
        endcase
    end

endmodule
