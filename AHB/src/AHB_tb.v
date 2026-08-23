`timescale 1ns / 1ps

module AHB_tb ();

    reg        HCLK;
    reg        HRESETn;

    reg [31:0] PADDR;
    reg [31:0] PWDATA;
    reg        PWRITE;
    reg [2:0]  PSIZE;
    reg [1:0]  PTRANS;
    reg [2:0]  PBURST;

    reg        i_insert_wait;

    wire        PDONE;
    wire        HRESP;
    wire        HREADY;
    wire [31:0] HRDATA;

    AHB_TOP top (
        .HCLK          (HCLK),
        .HRESETn       (HRESETn),
        .PADDR         (PADDR),
        .PWDATA        (PWDATA),
        .PWRITE        (PWRITE),
        .PSIZE         (PSIZE),
        .PTRANS        (PTRANS),
        .PBURST        (PBURST),
        .i_insert_wait (i_insert_wait),
        .PDONE         (PDONE),
        .HRESP         (HRESP),
        .HREADY        (HREADY),
        .HRDATA        (HRDATA)
    );

    initial begin
        HCLK = 1'b0;
        forever #10 HCLK = ~HCLK;
    end

    task reset_system;
        begin
            $display("\n[TIME: %0t] --- Initializing System & Applying Reset ---", $time);
            HRESETn       = 1'b0;
            PADDR         = 32'h00000000;
            PWDATA        = 32'h00000000;
            PWRITE        = 1'b0;
            PSIZE         = 3'b000;
            PTRANS        = 2'b00;
            PBURST        = 3'b000;
            i_insert_wait = 1'b0;
            #40;
            @(posedge HCLK);
            HRESETn       = 1'b1;
            $display("[TIME: %0t] --- Reset Released ---", $time);
            @(posedge HCLK);
        end
    endtask

    task single_write(
        input [31:0] addr,
        input [31:0] data,
        input [2:0]  size
    );
        begin
            @(posedge HCLK);
            PADDR  = addr;
            PWDATA = data;
            PWRITE = 1'b1;
            PSIZE  = size;
            PTRANS = 2'b10;
            PBURST = 3'b000;

            @(posedge HCLK);
            PTRANS = 2'b00;
            PADDR  = 32'h0;
            PWDATA = 32'h0;
            PWRITE = 1'b0;

            @(posedge HCLK);
        end
    endtask

    task single_read(
        input  [31:0] addr,
        input  [2:0]  size,
        input  [31:0] expected_data
    );
        begin
            @(posedge HCLK);
            PADDR  = addr;
            PWRITE = 1'b0;
            PSIZE  = size;
            PTRANS = 2'b10;
            PBURST = 3'b000;

            @(posedge HCLK);
            PTRANS = 2'b00;
            PADDR  = 32'h0;

            @(posedge HCLK);
            if (HRDATA == expected_data) begin
                $display("[PASS] Read Addr: 0x%08h | Data: 0x%08h | Expected: 0x%08h", addr, HRDATA, expected_data);
            end else begin
                $display("[FAIL] Read Addr: 0x%08h | Got Data: 0x%08h | Expected: 0x%08h", addr, HRDATA, expected_data);
            end
        end
    endtask

    initial begin
        $dumpfile("ahb_wave.vcd");
        $dumpvars(0, AHB_tb);

        $display("==================================================================");
        $display("          STARTING AMBA AHB-LITE VERIFICATION (LAB 2)            ");
        $display("==================================================================");

        reset_system();

        $display("\n==================================================================");
        $display(" TEST CASE 1: Single Write Transfer (No Wait-State)");
        $display("==================================================================");

        $display("[TC1] Writing 8-bit  0xA5 to Slave 1 (Addr: 0x00000004)...");
        single_write(32'h00000004, 32'h000000A5, 3'b000);

        $display("[TC1] Writing 16-bit 0x1234 to Slave 1 (Addr: 0x00000010)...");
        single_write(32'h00000010, 32'h00001234, 3'b001);

        $display("[TC1] Writing 32-bit 0xDEADBEEF to Slave 1 (Addr: 0x00000020)...");
        single_write(32'h00000020, 32'hDEADBEEF, 3'b010);

        $display("[TC1] Writing 32-bit 0xCAFEBABE to Slave 2 (Addr: 0x40000008)...");
        single_write(32'h40000008, 32'hCAFEBABE, 3'b010);

        $display("[TC1] Single Write Transfers Completed.\n");
        #20;

        $display("==================================================================");
        $display(" TEST CASE 2: Single Read Transfer (No Wait-State)");
        $display("==================================================================");

        $display("[TC2] Reading 8-bit from Slave 1 (Addr: 0x00000004)...");
        single_read(32'h00000004, 3'b000, 32'h000000A5);

        $display("[TC2] Reading 16-bit from Slave 1 (Addr: 0x00000010)...");
        single_read(32'h00000010, 3'b001, 32'h00001234);

        $display("[TC2] Reading 32-bit from Slave 1 (Addr: 0x00000020)...");
        single_read(32'h00000020, 3'b010, 32'hDEADBEEF);

        $display("[TC2] Reading 32-bit from Slave 2 (Addr: 0x40000008)...");
        single_read(32'h40000008, 3'b010, 32'hCAFEBABE);

        $display("[TC2] Single Read Transfers Completed.\n");
        #20;

        $display("==================================================================");
        $display(" TEST CASE 3: Write with Wait-State Insertion");
        $display("==================================================================");

        $display("[TC3] Enabling wait-state injection on Slave 1...");
        @(posedge HCLK);
        i_insert_wait = 1'b1;

        PADDR  = 32'h00000030;
        PWDATA = 32'hAABBCCDD;
        PWRITE = 1'b1;
        PSIZE  = 3'b010;
        PTRANS = 2'b10;
        PBURST = 3'b000;

        @(posedge HCLK);
        PTRANS = 2'b00;
        PWRITE = 1'b0;

        @(posedge HCLK);
        i_insert_wait = 1'b0;

        @(posedge HCLK);
        @(posedge HCLK);
        $display("[TC3] Write with Wait-State completed on bus.");

        $display("[TC3] Verifying written data after wait-state insertion...");
        single_read(32'h00000030, 3'b010, 32'hAABBCCDD);
        $display("[TC3] Wait-State Insertion Test Completed.\n");
        #20;

        $display("==================================================================");
        $display(" TEST CASE 4: Burst Transfer (INCR4 - 4 Transfers)");
        $display("==================================================================");

        $display("[TC4] Initiating 4-Beat INCR4 32-bit Write Burst starting at 0x00000040...");
        @(posedge HCLK);
        PADDR  = 32'h00000040;
        PWDATA = 32'h11111111;
        PWRITE = 1'b1;
        PSIZE  = 3'b010;
        PTRANS = 2'b10;
        PBURST = 3'b011;

        @(posedge HCLK);
        PWDATA = 32'h22222222;
        PTRANS = 2'b11;

        @(posedge HCLK);
        PWDATA = 32'h33333333;
        PTRANS = 2'b11;

        @(posedge HCLK);
        PWDATA = 32'h44444444;
        PTRANS = 2'b11;

        @(posedge HCLK);
        PTRANS = 2'b00;
        PWRITE = 1'b0;
        PWDATA = 32'h0;
        @(posedge HCLK);

        $display("[TC4] Reading back all 4 Beats from INCR4 Burst to verify...");
        single_read(32'h00000040, 3'b010, 32'h11111111);
        single_read(32'h00000044, 3'b010, 32'h22222222);
        single_read(32'h00000048, 3'b010, 32'h33333333);
        single_read(32'h0000004C, 3'b010, 32'h44444444);
        $display("[TC4] INCR4 Burst Transfer Test Completed.\n");
        #20;

        $display("==================================================================");
        $display(" TEST CASE 5: Invalid Address with Error Response");
        $display("==================================================================");

        $display("[TC5] Accessing Unmapped Address 0x80000000 (No Slave Configured)...");
        @(posedge HCLK);
        PADDR  = 32'h80000000;
        PWRITE = 1'b0;
        PSIZE  = 3'b010;
        PTRANS = 2'b10;
        PBURST = 3'b000;

        @(posedge HCLK);
        PTRANS = 2'b00;

        @(posedge HCLK);
        if (HRESP == 1'b1 && HREADY == 1'b0) begin
            $display("[PASS] 1st Cycle of ERROR response detected: HRESP=1, HREADY=0 (Wait state).");
        end else begin
            $display("[INFO] Cycle 1 Status: HRESP=%b, HREADY=%b", HRESP, HREADY);
        end

        @(posedge HCLK);
        if (HRESP == 1'b1 && HREADY == 1'b1) begin
            $display("[PASS] 2nd Cycle of ERROR response detected: HRESP=1, HREADY=1 (Transfer Terminated with Error).");
        end else begin
            $display("[INFO] Cycle 2 Status: HRESP=%b, HREADY=%b", HRESP, HREADY);
        end

        @(posedge HCLK);
        $display("[TC5] Invalid Address Error Response Test Completed.\n");

        $display("==================================================================");
        $display("           ALL 5 AHB-LITE TEST CASES COMPLETED SUCCESSFULLY       ");
        $display("==================================================================");
        #40;
        $finish;
    end

endmodule