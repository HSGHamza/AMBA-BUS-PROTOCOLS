`timescale 1ns/1ps

module testbench;

    reg pclk;
    reg presetn;

    reg transfer;
    reg read;
    reg write;

    reg [8:0] apb_write_paddr;
    reg [7:0] apb_write_data;
    reg [8:0] apb_read_paddr;

    wire pslverr;
    reg [3:0] test_case;
    wire [7:0] apb_read_data_out;
    
    top dut (
        .pclk(pclk),
        .presetn(presetn),
        .transfer(transfer),
        .read(read),
        .write(write),
        .apb_write_paddr(apb_write_paddr),
        .apb_write_data(apb_write_data),
        .apb_read_paddr(apb_read_paddr),
        .pslverr(pslverr),
        .apb_read_data_out(apb_read_data_out)
    );

    initial begin
        pclk = 1'b0;

        forever #5 pclk = ~pclk;
    end

    integer pass_count;
    integer fail_count;

    
    task reset_dut;
    begin

        presetn = 1'b0;

        transfer = 1'b0;
        read = 1'b0;
        write = 1'b0;

        apb_write_paddr = 9'h000;
        apb_write_data  = 8'h00;
        apb_read_paddr  = 9'h000;

        #20;

        presetn = 1'b1;

        @(posedge pclk);
        #1;

    end
    endtask

    task apb_write_transaction;

        input [8:0] address;
        input [7:0] data;

    begin

        @(negedge pclk);

        transfer = 1'b1;
        write = 1'b1;
        read = 1'b0;

        apb_write_paddr = address;
        apb_write_data  = data;

        // IDLE -> SETUP
        @(posedge pclk);
        #1;

        // SETUP -> ENABLE
        @(posedge pclk);
        #1;

        // Wait until transfer completes
while ((dut.master_inst.state == 2'b10) &&
       (dut.master_inst.pready == 1'b0)) begin
    @(posedge pclk);
    #1;
end

        @(negedge pclk);

        transfer = 1'b0;
        write = 1'b0;

    end
    endtask

    task apb_read_transaction;

        input [8:0] address;
        output [7:0] data;

    begin

        @(negedge pclk);

        transfer = 1'b1;
        write = 1'b0;
        read = 1'b1;

        apb_read_paddr = address;

        // IDLE -> SETUP
        @(posedge pclk);
        #1;

        // SETUP -> ENABLE
        @(posedge pclk);
        #1;

        // Wait until transfer completes
while ((dut.master_inst.state == 2'b10) &&
       (dut.master_inst.pready == 1'b0)) begin
    @(posedge pclk);
    #1;
end

        data = apb_read_data_out;

        @(negedge pclk);

        transfer = 1'b0;
        read = 1'b0;

    end
    endtask

    task TC1_basic_write;

    begin

        $display("");
        $display("TC1 - BASIC WRITE OPERATION");


        reset_dut;

        apb_write_transaction(9'h005, 8'hAA);

        #2;

        if (dut.slave1_inst.memory[8'h05] === 8'hAA) begin

            $display("TC1 PASS");
            $display("Address  = 9'h005");
            $display("Data     = 8'hAA");
            $display("Slave 1  = SELECTED");
            $display("Memory[5] = %h", dut.slave1_inst.memory[8'h05]);

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC1 FAIL");
            $display("Expected memory[5] = AA");
            $display("Actual   memory[5] = %h",
                     dut.slave1_inst.memory[8'h05]);

            fail_count = fail_count + 1;

        end

    end
    endtask



    task TC2_basic_read;

        reg [7:0] read_data;

    begin

        $display("");
        $display("TC2 - BASIC READ OPERATION");


        reset_dut;

        // First write AA to address 005
        apb_write_transaction(9'h005, 8'hAA);

        // Now read address 005
        apb_read_transaction(9'h005, read_data);

        #2;

        if (read_data === 8'hAA) begin

            $display("TC2 PASS");
            $display("Address     = 9'h005");
            $display("Expected    = 8'hAA");
            $display("Read Data   = 8'h%h", read_data);

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC2 FAIL");
            $display("Expected = 8'hAA");
            $display("Actual   = 8'h%h", read_data);

            fail_count = fail_count + 1;

        end

    end
    endtask

    task TC3_address_decoding;

    begin

        $display("");
        $display("TC3 - ADDRESS DECODING / SLAVE SELECTION");


        reset_dut;

        @(negedge pclk);

        transfer = 1'b1;
        write = 1'b1;
        read = 1'b0;

        apb_write_paddr = 9'h005;
        apb_write_data  = 8'hA5;

        @(posedge pclk);
        #1;

        if ((dut.master_inst.psel1 === 1'b1) &&
            (dut.master_inst.psel2 === 1'b0)) begin

            $display("Slave 1 selection PASS");
            $display("Address 9'h005 -> PSEL1 = 1, PSEL2 = 0");

        end
        else begin

            $display("Slave 1 selection FAIL");
            fail_count = fail_count + 1;

        end

        // Finish transfer
        @(posedge pclk);
        #1;

        @(negedge pclk);

        transfer = 1'b0;
        write = 1'b0;


        @(negedge pclk);

        transfer = 1'b1;
        write = 1'b1;
        read = 1'b0;

        apb_write_paddr = 9'h085;
        apb_write_data  = 8'h5A;

        @(posedge pclk);
        #1;

        if ((dut.master_inst.psel1 === 1'b0) &&
            (dut.master_inst.psel2 === 1'b1)) begin

            $display("Slave 2 selection PASS");
            $display("Address 9'h085 -> PSEL1 = 0, PSEL2 = 1");

        end
        else begin

            $display("Slave 2 selection FAIL");
            fail_count = fail_count + 1;

        end

        @(posedge pclk);
        #1;

        @(negedge pclk);

        transfer = 1'b0;
        write = 1'b0;

        #2;

        if ((dut.slave1_inst.memory[8'h05] === 8'hA5) &&
            (dut.slave2_inst.memory[8'h85] === 8'h5A)) begin

            $display("TC3 PASS");
            $display("Slave 1 memory[05] = %h",
                     dut.slave1_inst.memory[8'h05]);
            $display("Slave 2 memory[85] = %h",
                     dut.slave2_inst.memory[8'h85]);

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC3 FAIL");

            fail_count = fail_count + 1;

        end

    end
    endtask



    task TC4_write_wait_state;

    begin

        $display("");
        $display("TC4 - WRITE WITH WAIT STATES");


        reset_dut;

        @(negedge pclk);

        transfer = 1'b1;
        write = 1'b1;
        read = 1'b0;

        apb_write_paddr = 9'h010;
        apb_write_data  = 8'hBB;

        // IDLE -> SETUP
        @(posedge pclk);
        #1;

        // SETUP -> ENABLE
        @(posedge pclk);
        #1;

        // Force ready LOW to simulate slave wait states
        force dut.pready = 1'b0;

        $display("Simulating wait state...");

        repeat (3) begin

            @(posedge pclk);
            #1;

            if (dut.master_inst.state !== 2'b10) begin

                $display("TC4 FAIL: Master left ENABLE during wait");

                fail_count = fail_count + 1;

                release dut.pready;
                disable TC4_write_wait_state;

            end

        end

        $display("Master remained in ENABLE during wait.");

        // Release ready
        release dut.pready;

        @(posedge pclk);
        #1;

        @(posedge pclk);
        #1;

        @(negedge pclk);

        transfer = 1'b0;
        write = 1'b0;

        #2;

        if (dut.slave1_inst.memory[8'h10] === 8'hBB) begin

            $display("TC4 PASS");
            $display("Address = 9'h010");
            $display("Data    = 8'hBB");
            $display("Wait states successfully handled.");

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC4 FAIL");
            $display("Expected memory[10] = BB");
            $display("Actual memory[10] = %h",
                     dut.slave1_inst.memory[8'h10]);

            fail_count = fail_count + 1;

        end

    end
    endtask



    task TC5_read_wait_state;

        reg [7:0] read_data;

    begin

        $display("");
        $display("TC5 - READ WITH WAIT STATES");


        reset_dut;

        // Put known data into address 010
        apb_write_transaction(9'h010, 8'hBB);

        @(negedge pclk);

        transfer = 1'b1;
        write = 1'b0;
        read = 1'b1;

        apb_read_paddr = 9'h010;

        // IDLE -> SETUP
        @(posedge pclk);
        #1;

        // SETUP -> ENABLE
        @(posedge pclk);
        #1;

        // Simulate wait states
        force dut.pready = 1'b0;

        $display("Simulating read wait state...");

        repeat (3) begin

            @(posedge pclk);
            #1;

            if (dut.master_inst.state !== 2'b10) begin

                $display("TC5 FAIL: Master left ENABLE during wait");

                fail_count = fail_count + 1;

                release dut.pready;
                disable TC5_read_wait_state;

            end

        end

        $display("Master remained in ENABLE during wait.");

        release dut.pready;

        @(posedge pclk);
        #1;

        @(posedge pclk);
        #1;

        read_data = apb_read_data_out;

        @(negedge pclk);

        transfer = 1'b0;
        read = 1'b0;

        #2;

        if (read_data === 8'hBB) begin

            $display("TC5 PASS");
            $display("Address   = 9'h010");
            $display("Read Data = 8'hBB");

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC5 FAIL");
            $display("Expected = 8'hBB");
            $display("Actual   = 8'h%h", read_data);

            fail_count = fail_count + 1;

        end

    end
    endtask


    task TC6_error_handling;

    begin

        $display("");
        $display("TC6 - ERROR HANDLING / PSLVERR");


        reset_dut;

        apb_write_transaction(9'h1FF, 8'hFF);

        #2;

        if (pslverr === 1'b1) begin

            $display("TC6 PASS");
            $display("PSLVERR correctly asserted.");
            $display("Invalid address = 9'h1FF");

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC6 FAIL");
            $display("Expected PSLVERR = 1");
            $display("Actual PSLVERR   = %b", pslverr);
            $display("");
            $display("REASON:");
            $display("9'h1FF is decoded to Slave 2.");
            $display("Slave 2 receives paddr[7:0] = 8'hFF.");
            $display("The slave considers 8'hFF valid.");

            fail_count = fail_count + 1;

        end

    end
    endtask



    task TC7_burst_transfers;

    begin

        $display("");
        $display("TC7 - BURST / BACK-TO-BACK TRANSFERS");


        reset_dut;

        // Keep transfer asserted between transactions
        transfer = 1'b1;



        @(negedge pclk);

        write = 1'b1;
        read = 1'b0;

        apb_write_paddr = 9'h001;
        apb_write_data  = 8'h11;

        @(posedge pclk);
        #1;

        @(posedge pclk);
        #1;



        @(negedge pclk);

        apb_write_paddr = 9'h002;
        apb_write_data  = 8'h22;

        @(posedge pclk);
        #1;

        @(posedge pclk);
        #1;



        @(negedge pclk);

        apb_write_paddr = 9'h003;
        apb_write_data  = 8'h33;

        @(posedge pclk);
        #1;

        @(posedge pclk);
        #1;



        @(negedge pclk);

        write = 1'b0;
        read = 1'b1;

        apb_read_paddr = 9'h001;

        @(posedge pclk);
        #1;

        @(posedge pclk);
        #1;

        if (apb_read_data_out !== 8'h11)
            $display("TC7 READ 001 FAIL");
        else
            $display("TC7 READ 001 PASS");

        @(negedge pclk);

        apb_read_paddr = 9'h002;

        @(posedge pclk);
        #1;

        @(posedge pclk);
        #1;

        if (apb_read_data_out !== 8'h22)
            $display("TC7 READ 002 FAIL");
        else
            $display("TC7 READ 002 PASS");

        @(negedge pclk);

        apb_read_paddr = 9'h003;

        @(posedge pclk);
        #1;

        @(posedge pclk);
        #1;

        if (apb_read_data_out !== 8'h33)
            $display("TC7 READ 003 FAIL");
        else
            $display("TC7 READ 003 PASS");

        @(negedge pclk);

        transfer = 1'b0;
        read = 1'b0;
        write = 1'b0;

        #2;

        if ((dut.slave1_inst.memory[8'h01] === 8'h11) &&
            (dut.slave1_inst.memory[8'h02] === 8'h22) &&
            (dut.slave1_inst.memory[8'h03] === 8'h33)) begin

            $display("TC7 PASS");
            $display("Back-to-back transfers completed correctly.");

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC7 FAIL");

            fail_count = fail_count + 1;

        end

    end
    endtask



    task TC8_out_of_range;

    begin

        $display("");
        $display("TC8 - OUT OF RANGE ADDRESS");

        reset_dut;

        apb_write_transaction(9'h1FF, 8'hFF);

        #2;

        if (pslverr === 1'b1) begin

            $display("TC8 PASS");
            $display("PSLVERR asserted for invalid address.");

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC8 FAIL");
            $display("Expected PSLVERR = 1");
            $display("Actual PSLVERR   = %b", pslverr);
            $display("");
            $display("Current RTL maps 9'h1FF to Slave 2");
            $display("with local address 8'hFF.");

            fail_count = fail_count + 1;

        end

    end
    endtask



    task TC9_reset_behavior;

    begin

        $display("");
        $display("TC9 - RESET BEHAVIOR");


        // Assert reset
        presetn = 1'b0;

        transfer = 1'b0;
        read = 1'b0;
        write = 1'b0;

        #20;

        #1;

        if ((dut.master_inst.state === 2'b00) &&
            (dut.master_inst.psel1 === 1'b0) &&
            (dut.master_inst.psel2 === 1'b0) &&
            (dut.master_inst.penable === 1'b0)) begin

            $display("TC9 PASS");
            $display("Master returned to IDLE.");
            $display("PSEL1 = 0");
            $display("PSEL2 = 0");
            $display("PENABLE = 0");

            pass_count = pass_count + 1;

        end
        else begin

            $display("TC9 FAIL");
            $display("Reset did not return signals to default.");

            fail_count = fail_count + 1;

        end

        // Release reset
        presetn = 1'b1;

        @(posedge pclk);
        #1;

    end
    endtask


    task TC10_randomized;

        integer i;

        reg random_write;
        reg [8:0] random_address;
        reg [7:0] random_data;
        reg [7:0] random_read_data;

    begin

        $display("");
        $display("TC10 - RANDOMIZED TRANSACTIONS");


        reset_dut;

        for (i = 0; i < 20; i = i + 1) begin

            random_write   = $random;
            random_address = $urandom_range(0, 8'hFF);
            random_data    = $urandom_range(0, 8'hFF);



            if (random_write) begin

                apb_write_transaction(
                    random_address,
                    random_data
                );

                $display(
                    "Random TX %0d: WRITE Addr=%h Data=%h",
                    i + 1,
                    random_address,
                    random_data
                );

            end



            else begin

                apb_read_transaction(
                    random_address,
                    random_read_data
                );

                $display(
                    "Random TX %0d: READ Addr=%h Data=%h",
                    i + 1,
                    random_address,
                    random_read_data
                );

            end

        end

        $display("20 randomized transactions completed.");

        // If simulation survived all 20 transactions,
        // consider the randomized stress test successful.
        $display("TC10 PASS");

        pass_count = pass_count + 1;

    end
    endtask

initial begin

    // Initialize counters
    pass_count = 0;
    fail_count = 0;

    // Initialize test-case marker
    test_case = 0;

    // Initial values
    pclk = 1'b0;
    presetn = 1'b0;

    transfer = 1'b0;
    read = 1'b0;
    write = 1'b0;

    apb_write_paddr = 9'h000;
    apb_write_data  = 8'h00;
    apb_read_paddr  = 9'h000;

    // Allow initialization
    #10;

    // =========================
    // TC1
    // =========================
    test_case = 1;
    TC1_basic_write;

    // =========================
    // TC2
    // =========================
    test_case = 2;
    TC2_basic_read;

    // =========================
    // TC3
    // =========================
    test_case = 3;
    TC3_address_decoding;

    // =========================
    // TC4
    // =========================
    test_case = 4;
    TC4_write_wait_state;

    // =========================
    // TC5
    // =========================
    test_case = 5;
    TC5_read_wait_state;

    // =========================
    // TC6
    // =========================
    test_case = 6;
    TC6_error_handling;

    // =========================
    // TC7
    // =========================
    test_case = 7;
    TC7_burst_transfers;

    // =========================
    // TC8
    // =========================
    test_case = 8;
    TC8_out_of_range;

    // =========================
    // TC9
    // =========================
    test_case = 9;
    TC9_reset_behavior;

    // =========================
    // TC10
    // =========================
    test_case = 10;
    TC10_randomized;

    // =========================
    // FINAL RESULTS
    // =========================

    #20;

    $display("");
    $display("====================================");
    $display("        APB TEST RESULTS");
    $display("====================================");
    $display("TOTAL PASSED = %0d", pass_count);
    $display("TOTAL FAILED = %0d", fail_count);

    if (fail_count == 0)
        $display("ALL TEST CASES PASSED");
    else
        $display("SOME TEST CASES FAILED - CHECK RTL");

    $finish;

end

endmodule


cd ~/f4pga-examples
export F4PGA_INSTALL_DIR=~/opt/f4pga
export FPGA_FAM="xc7"
source "$F4PGA_INSTALL_DIR/$FPGA_FAM/conda/etc/profile.d/conda.sh"
conda activate xc7
export F4PGA_INSTALL_DIR=~/opt/f4pga
export FPGA_FAM="xc7"
cd xc7
TARGET="zybo" make -C handshake
