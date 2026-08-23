module AHB_Slave_2 #(
    parameter MEM_WIDTH = 8,
    parameter MEM_DEPTH = 64
)(
    input             HCLK,
    input             HRESETn,

    input      [31:0] HADDR,
    input      [31:0] HWDATA,

    input      [1:0]  HSELx_slaves,

    input             HWRITE,
    input      [2:0]  HSIZE,
    input      [1:0]  HTRANS,
    input      [2:0]  HBURST,
    input             HREADY,

    output reg        HREADYOUT,
    output reg        HRESP,
    output reg [31:0] HRDATA
);

    reg [MEM_WIDTH-1:0] memory_2 [0:MEM_DEPTH-1];

    reg [31:0] HADDR_reg;
    reg        HWRITE_reg;
    reg [2:0]  HSIZE_reg;
    reg [1:0]  HTRANS_reg;
    reg [2:0]  HBURST_reg;
    reg [1:0]  HSEL_reg;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HREADYOUT <= 1'b1;
            HRESP     <= 1'b0;
        end else begin
            HREADYOUT <= 1'b1;
            HRESP     <= 1'b0;
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR_reg  <= 32'd0;
            HWRITE_reg <= 1'b0;
            HSIZE_reg  <= 3'b000;
            HTRANS_reg <= 2'b00;
            HBURST_reg <= 3'b000;
            HSEL_reg   <= 2'b11;
        end else if (HREADY) begin
            HADDR_reg  <= HADDR;
            HWRITE_reg <= HWRITE;
            HSIZE_reg  <= HSIZE;
            HTRANS_reg <= HTRANS;
            HBURST_reg <= HBURST;
            HSEL_reg   <= HSELx_slaves;
        end
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HRDATA <= 32'h00000000;
        end else if (HREADY && (HSEL_reg == 2'b01) && (HTRANS_reg == 2'b10 || HTRANS_reg == 2'b11)) begin
            if (HWRITE_reg) begin
                case (HSIZE_reg)
                    3'b000: begin
                        memory_2[HADDR_reg[5:0]] <= HWDATA[7:0];
                    end
                    3'b001: begin
                        memory_2[HADDR_reg[5:0]]     <= HWDATA[7:0];
                        memory_2[HADDR_reg[5:0] + 1] <= HWDATA[15:8];
                    end
                    3'b010: begin
                        memory_2[HADDR_reg[5:0]]     <= HWDATA[7:0];
                        memory_2[HADDR_reg[5:0] + 1] <= HWDATA[15:8];
                        memory_2[HADDR_reg[5:0] + 2] <= HWDATA[23:16];
                        memory_2[HADDR_reg[5:0] + 3] <= HWDATA[31:24];
                    end
                endcase
            end else begin
                case (HSIZE_reg)
                    3'b000: begin
                        HRDATA <= {24'h000000, memory_2[HADDR_reg[5:0]]};
                    end
                    3'b001: begin
                        HRDATA <= {16'h0000, memory_2[HADDR_reg[5:0] + 1], memory_2[HADDR_reg[5:0]]};
                    end
                    3'b010: begin
                        HRDATA <= {memory_2[HADDR_reg[5:0] + 3],
                                   memory_2[HADDR_reg[5:0] + 2],
                                   memory_2[HADDR_reg[5:0] + 1],
                                   memory_2[HADDR_reg[5:0]]};
                    end
                    default: HRDATA <= 32'h00000000;
                endcase
            end
        end
    end

endmodule
