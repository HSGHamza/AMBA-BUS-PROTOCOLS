module axi_master (
    input  wire        aclck,
    input  wire        aresetn,

    input  wire        start_read,
    input  wire        start_write,
    input  wire [31:0] address,
    input  wire [31:0] W_data,

    input  wire        awready,
    input  wire        wready,
    input  wire        bvalid,
    input  wire        arready,
    input  wire        rvalid,
    input  wire [31:0] R_data,

    output reg         awvalid,
    output reg         wvalid,
    output reg         bready,
    output reg         arvalid,
    output reg         rready,
    output reg [31:0]  AW,
    output reg [31:0]  W,
    output reg [31:0]  AR,
    output reg [31:0]  R
);

localparam IDLE          = 3'd0,
           RADDR_CHANNEL = 3'd1,
           RDATA_CHANNEL = 3'd2,
           WRITE_CHANNEL = 3'd3,
           WRESP_CHANNEL = 3'd4;

reg [2:0] state, next_state;
reg       aw_done, w_done;

always @(*) begin
    awvalid = 1'b0;
    wvalid  = 1'b0;
    bready  = 1'b0;
    arvalid = 1'b0;
    rready  = 1'b0;

    case (state)
        RADDR_CHANNEL: begin
            arvalid = 1'b1;
        end
        RDATA_CHANNEL: begin
            rready = 1'b1;
        end
        WRITE_CHANNEL: begin
            awvalid = !aw_done;
            wvalid  = !w_done;
        end
        WRESP_CHANNEL: begin
            bready = 1'b1;
        end
        default: begin
        end
    endcase
end

always @(*) begin
    next_state = state;

    case (state)
        IDLE: begin
            if (start_read)
                next_state = RADDR_CHANNEL;
            else if (start_write)
                next_state = WRITE_CHANNEL;
        end

        RADDR_CHANNEL: begin
            if (arvalid && arready)
                next_state = RDATA_CHANNEL;
        end

        RDATA_CHANNEL: begin
            if (rvalid && rready)
                next_state = IDLE;
        end

        WRITE_CHANNEL: begin
            if ((aw_done || (awvalid && awready)) &&
                (w_done  || (wvalid  && wready)))
                next_state = WRESP_CHANNEL;
        end

        WRESP_CHANNEL: begin
            if (bvalid && bready)
                next_state = IDLE;
        end

        default: next_state = IDLE;
    endcase
end

always @(posedge aclck or negedge aresetn) begin
    if (!aresetn) begin
        state   <= IDLE;
        aw_done <= 1'b0;
        w_done  <= 1'b0;
        AW      <= 32'b0;
        W       <= 32'b0;
        AR      <= 32'b0;
        R       <= 32'b0;
    end else begin
        state <= next_state;

        if (state == IDLE && start_read)
            AR <= address;
        else if (state == IDLE && start_write) begin
            AW <= address;
            W  <= W_data;
        end

        if (state == WRITE_CHANNEL) begin
            if (awvalid && awready)
                aw_done <= 1'b1;
            if (wvalid && wready)
                w_done <= 1'b1;
        end else begin
            aw_done <= 1'b0;
            w_done  <= 1'b0;
        end

        if (state == RDATA_CHANNEL && rvalid && rready)
            R <= R_data;
    end
end

endmodule
