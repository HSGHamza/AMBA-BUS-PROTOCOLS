module slave(

    input clk,
    input rst,

    input valid,
    input rw,

    input [1:0] addr,
    input [7:0] datain,

    output reg ready,
    output reg [7:0] dataout

);

parameter IDLE   = 2'b00,
          ACCESS = 2'b01,
          DONE   = 2'b10;

reg [1:0] state,next_state;

reg [7:0] mem [3:0];

always @(posedge clk or posedge rst)
begin
    if(rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @(*)
begin

    case(state)

    IDLE:
        if(valid)
            next_state = ACCESS;
        else
            next_state = IDLE;

    ACCESS:
        next_state = DONE;

    DONE:
        if(valid)
            next_state = DONE;
        else
            next_state = IDLE;

    default:
        next_state = IDLE;

    endcase

end

always @(posedge clk)
begin

    if(state==ACCESS)
    begin

        if(rw)
            mem[addr] <= datain;
        else
            dataout <= mem[addr];

    end

end

always @(*)
begin

    ready = 0;

    case(state)

    IDLE:
        ready = 0;

    ACCESS:
        ready = 0;

    DONE:
        ready = 1;

    endcase

end

endmodule
