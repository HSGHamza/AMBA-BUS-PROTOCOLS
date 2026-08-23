module master(
    input clk,
    input rst,
    input start,
    input ready,

    input [1:0] addr_in,
    input rw_in,
    input [7:0] data_in,

    output reg valid,
    output reg [1:0] addr,
    output reg rw,
    output reg [7:0] datain
);

parameter IDLE = 2'b00,
          SEND = 2'b01,
          WAIT = 2'b10;

reg [1:0] state;
reg [1:0] next_state;


always @(posedge clk or posedge rst)
begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end



always @(*)
begin
    next_state = IDLE;

    case (state)

        IDLE:
        begin
            if (start)
                next_state = SEND;
            else
                next_state = IDLE;
        end

        SEND:
        begin
            next_state = WAIT;
        end

        WAIT:
        begin
            if (ready)
                next_state = IDLE;
            else
                next_state = WAIT;
        end

        default:
        begin
            next_state = IDLE;
        end

    endcase
end



always @(*)
begin

    valid  = 1'b0;
    addr   = 2'b00;
    rw     = 1'b0;
    datain = 8'b0;

    case (state)

        IDLE:
        begin
            valid = 1'b0;
        end

        SEND:
        begin
            valid  = 1'b1;
            addr   = addr_in;
            rw     = rw_in;
            datain = data_in;
        end

        WAIT:
        begin
            valid  = 1'b1;
            addr   = addr_in;
            rw     = rw_in;
            datain = data_in;
        end

        default:
        begin
            valid  = 1'b0;
            addr   = 2'b00;
            rw     = 1'b0;
            datain = 8'b0;
        end

    endcase

end

endmodule
