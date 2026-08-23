module AHB_Master (
    input             HCLK,
    input             HRESETn,

    input      [31:0] PADDR,
    input      [31:0] PWDATA,
    input             PWRITE,
    input      [2:0]  PSIZE,
    input      [1:0]  PTRANS,
    input      [2:0]  PBURST,

    input             HREADY,
    input             HRESP,
    input      [31:0] HRDATA,

    output reg [31:0] HADDR,
    output reg [31:0] HWDATA,
    output reg        HWRITE,
    output reg [2:0]  HSIZE,
    output reg [1:0]  HTRANS,
    output reg [2:0]  HBURST,

    output reg        PDONE
);

    localparam IDLE   = 2'b00,
               BUSY   = 2'b01,
               NONSEQ = 2'b10,
               SEQ    = 2'b11;

    reg [1:0]  cs, ns;
    reg [31:0] HWDATA_reg;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn)
            cs <= IDLE;
        else if (HREADY)
            cs <= ns;
    end

    always @(*) begin
        ns = cs;
        case (cs)
            IDLE: begin
                if (PTRANS == 2'b10)
                    ns = NONSEQ;
                else
                    ns = IDLE;
            end

            BUSY: begin
                if (PTRANS == 2'b11)
                    ns = SEQ;
                else if (PTRANS == 2'b10)
                    ns = NONSEQ;
                else if (PTRANS == 2'b00)
                    ns = IDLE;
                else
                    ns = BUSY;
            end

            NONSEQ: begin
                if (PTRANS == 2'b11)
                    ns = SEQ;
                else if (PTRANS == 2'b00)
                    ns = IDLE;
                else if (PTRANS == 2'b10)
                    ns = NONSEQ;
                else
                    ns = SEQ;
            end

            SEQ: begin
                if (PTRANS == 2'b00)
                    ns = IDLE;
                else if (PTRANS == 2'b10)
                    ns = NONSEQ;
                else
                    ns = SEQ;
            end
        endcase
    end

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            HADDR      <= 32'd0;
            HWDATA_reg <= 32'd0;
            HWDATA     <= 32'd0;
            HWRITE     <= 1'b0;
            HSIZE      <= 3'b000;
            HTRANS     <= 2'b00;
            HBURST     <= 3'b000;
        end else if (HREADY) begin
            HWDATA <= HWDATA_reg;

            case (ns)
                IDLE: begin
                    HADDR      <= 32'd0;
                    HWDATA_reg <= 32'd0;
                    HWRITE     <= 1'b0;
                    HSIZE      <= 3'b000;
                    HTRANS     <= 2'b00;
                    HBURST     <= 3'b000;
                end

                BUSY: begin
                    HADDR      <= PADDR;
                    HWDATA_reg <= PWDATA;
                    HWRITE     <= PWRITE;
                    HSIZE      <= PSIZE;
                    HTRANS     <= 2'b01;
                    HBURST     <= PBURST;
                end

                NONSEQ: begin
                    HADDR      <= PADDR;
                    HWDATA_reg <= PWDATA;
                    HWRITE     <= PWRITE;
                    HSIZE      <= PSIZE;
                    HTRANS     <= 2'b10;
                    HBURST     <= PBURST;
                end

                SEQ: begin
                    if (PBURST == 3'b001 || PBURST == 3'b011 || PBURST == 3'b010) begin
                        case (PSIZE)
                            3'b000:  HADDR <= HADDR + 32'd1;
                            3'b001:  HADDR <= HADDR + 32'd2;
                            3'b010:  HADDR <= HADDR + 32'd4;
                            default: HADDR <= HADDR + 32'd4;
                        endcase
                    end else begin
                        HADDR <= PADDR;
                    end
                    HWDATA_reg <= PWDATA;
                    HWRITE     <= PWRITE;
                    HSIZE      <= PSIZE;
                    HTRANS     <= 2'b11;
                    HBURST     <= PBURST;
                end
            endcase
        end
    end

    always @(*) begin
        if ((cs == NONSEQ || cs == SEQ) && (ns == IDLE) && HREADY)
            PDONE = 1'b1;
        else
            PDONE = 1'b0;
    end

endmodule
