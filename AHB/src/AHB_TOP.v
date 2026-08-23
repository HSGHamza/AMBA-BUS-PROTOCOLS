module AHB_TOP (
    input             HCLK,
    input             HRESETn,

    input      [31:0] PADDR,
    input      [31:0] PWDATA,
    input             PWRITE,
    input      [2:0]  PSIZE,
    input      [1:0]  PTRANS,
    input      [2:0]  PBURST,

    input             i_insert_wait,

    output            PDONE,
    output            HRESP,
    output            HREADY,
    output     [31:0] HRDATA
);

    wire [31:0] HADDR;
    wire [31:0] HWDATA;
    wire        HWRITE;
    wire [2:0]  HSIZE;
    wire [1:0]  HTRANS;
    wire [2:0]  HBURST;

    wire [1:0]  HSELx_slaves;
    wire [1:0]  HSELx_Mux;

    wire        HREADYOUT_1;
    wire        HREADYOUT_2;
    wire        HRESP_Slave_1;
    wire        HRESP_Slave_2;
    wire [31:0] HRDATA_1;
    wire [31:0] HRDATA_2;

    AHB_Master master (
        .HCLK    (HCLK),
        .HRESETn (HRESETn),
        .PADDR   (PADDR),
        .PWDATA  (PWDATA),
        .PWRITE  (PWRITE),
        .PSIZE   (PSIZE),
        .PTRANS  (PTRANS),
        .PBURST  (PBURST),
        .HREADY  (HREADY),
        .HRESP   (HRESP),
        .HRDATA  (HRDATA),
        .HADDR   (HADDR),
        .HWDATA  (HWDATA),
        .HWRITE  (HWRITE),
        .HSIZE   (HSIZE),
        .HTRANS  (HTRANS),
        .HBURST  (HBURST),
        .PDONE   (PDONE)
    );

    AHB_Decoder decoder (
        .HCLK         (HCLK),
        .HRESETn      (HRESETn),
        .HREADY       (HREADY),
        .HADDR        (HADDR),
        .HSELx_slaves (HSELx_slaves),
        .HSELx_Mux    (HSELx_Mux)
    );

    AHB_Slave_1 #(
        .MEM_WIDTH(8),
        .MEM_DEPTH(1024)
    ) slave1 (
        .HCLK          (HCLK),
        .HRESETn       (HRESETn),
        .HADDR         (HADDR),
        .HWDATA        (HWDATA),
        .HSELx_slaves  (HSELx_slaves),
        .HWRITE        (HWRITE),
        .HSIZE         (HSIZE),
        .HTRANS        (HTRANS),
        .HBURST        (HBURST),
        .HREADY        (HREADY),
        .i_insert_wait (i_insert_wait),
        .HREADYOUT     (HREADYOUT_1),
        .HRESP         (HRESP_Slave_1),
        .HRDATA        (HRDATA_1)
    );

    AHB_Slave_2 #(
        .MEM_WIDTH(8),
        .MEM_DEPTH(64)
    ) slave2 (
        .HCLK          (HCLK),
        .HRESETn       (HRESETn),
        .HADDR         (HADDR),
        .HWDATA        (HWDATA),
        .HSELx_slaves  (HSELx_slaves),
        .HWRITE        (HWRITE),
        .HSIZE         (HSIZE),
        .HTRANS        (HTRANS),
        .HBURST        (HBURST),
        .HREADY        (HREADY),
        .HREADYOUT     (HREADYOUT_2),
        .HRESP         (HRESP_Slave_2),
        .HRDATA        (HRDATA_2)
    );

    AHB_MUX mux (
        .HCLK           (HCLK),
        .HRESETn        (HRESETn),
        .HRESP_Slave_1  (HRESP_Slave_1),
        .HREADYOUT_1    (HREADYOUT_1),
        .HRDATA_Slave_1 (HRDATA_1),
        .HRESP_Slave_2  (HRESP_Slave_2),
        .HREADYOUT_2    (HREADYOUT_2),
        .HRDATA_Slave_2 (HRDATA_2),
        .HSELx_Mux      (HSELx_Mux),
        .HTRANS         (HTRANS),
        .HRDATA         (HRDATA),
        .HREADY         (HREADY),
        .HRESP          (HRESP)
    );

endmodule
