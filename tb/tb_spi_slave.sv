`timescale 1ns/1ps

module tb_spi_slave;

    // Configuration parameters
    localparam int DATA_WIDTH = 8;

    // Parameters for reference and timing
    localparam time CLOCK_PERIOD_NS    = 10ns;
    localparam int RANDOM_ITERATIONS   = 10000;
    localparam int CYCLES_PER_TRANSFER = (DATA_WIDTH * 5) + 20;
    localparam int BASE_TEST_CYCLES    = 25 * CYCLES_PER_TRANSFER;
    localparam int TIMEOUT_CYCLES      = BASE_TEST_CYCLES+(RANDOM_ITERATIONS * CYCLES_PER_TRANSFER);
    localparam int RESET_CYCLES        = 3;

    // DUT signals
    logic                  clk;
    logic                  rst_n;
    logic [DATA_WIDTH-1:0] tx_data;
    logic                  mosi;
    logic                  sclk;
    logic                  cs_n;
    logic                  cpol;
    logic                  cpha;
    logic                  bit_order;
    logic                  miso;
    logic [DATA_WIDTH-1:0] rx_data;
    logic                  busy;
    logic                  done;

    // Verification statistics
    int tests_run    = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    // Master Reference Model signals
    logic [DATA_WIDTH-1:0] master_tx_data;
    logic [DATA_WIDTH-1:0] master_tx_shift;
    logic [DATA_WIDTH-1:0] master_rx_data;
    logic [DATA_WIDTH-1:0] master_rx_shift;
    logic                  master_cpol;
    logic                  master_cpha;
    logic                  master_sclk;
    logic                  master_cs_n;
    logic                  master_bit_order;
    logic                  master_mosi;

    // Connection
    assign mosi = master_mosi;
    assign sclk = master_sclk;
    assign cs_n = master_cs_n;

    // DUT instantiation
    spi_slave #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),
        .cpol(cpol),
        .cpha(cpha),
        .bit_order(bit_order),
        .miso(miso),
        .rx_data(rx_data),
        .busy(busy),
        .done(done)
    );

    // Assertions
    sva_spi_slave #(
        .DATA_WIDTH(DATA_WIDTH)
    ) sva (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(tx_data),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),
        .cpol(cpol),
        .cpha(cpha),
        .bit_order(bit_order),
        .miso(miso),
        .rx_data(rx_data),
        .busy(busy),
        .done(done)
    );

    // Clock generation
    initial clk = 1'b0;
    always #(CLOCK_PERIOD_NS/2.0) clk = ~clk;

    // Timeout watchdog
    initial begin
        repeat(TIMEOUT_CYCLES) @(posedge clk);
        $fatal(1,"[TIMEOUT] Simulation hung! Watchdog triggered after %0d cycles.", TIMEOUT_CYCLES);
    end

    // Waveform generation
    initial begin
        $dumpfile("spi_slave_waveform.vcd");
        $dumpvars(0, tb_spi_slave);
    end

    // Helper tasks

    // Record test results
    task automatic record_test(input string test_name, input bit passed);
        begin
            tests_run++;
            if (passed) begin
                tests_passed++;
                $display("[PASS] %s", test_name);
            end else begin
                tests_failed++;
                $error("[FAIL] %s", test_name);
            end
        end
    endtask

    // Apply reset
    task automatic apply_reset();
        begin
            // Apply Reset
            rst_n     = 1'b0;
            tx_data   = '0;
            cpol      = 1'b0;
            cpha      = 1'b0;
            bit_order = 1'b0;

            // Reset slave reference model
            master_tx_data   = '0;
            master_tx_shift  = '0;
            master_rx_data   = '0;
            master_rx_shift  = '0;
            master_cs_n      = 1'b1;
            master_cpol      = 1'b0;
            master_cpha      = 1'b0;
            master_bit_order = 1'b0;
            master_sclk      = 1'b0;
            master_mosi      = 1'b0;

            // Hold reset
            repeat(RESET_CYCLES) @(posedge clk);

            // Release reset
            rst_n = 1'b1;

            @(posedge clk);
        end
    endtask

    // Check received data at slave
    task automatic check_slave_rx(
        input logic [DATA_WIDTH-1:0] expected
    );
        begin
            record_test(
                $sformatf("Slave RX = 0x%02h", expected), (rx_data === expected));
        end
    endtask

    // Check received data at master
    task automatic check_master_rx(
        input logic [DATA_WIDTH-1:0] expected
    );
        begin
            record_test(
                $sformatf("Master RX = 0x%02h", expected), (master_rx_data === expected));
        end
    endtask

    // Check SPI returns to idle after transaction
    task automatic check_idle_state();
        begin
            record_test(
                "Idle State",
                busy    == 1'b0 &&
                done    == 1'b0 &&
                cs_n    == 1'b1 &&
                sclk    == cpol
            );
        end
    endtask

    // Wait for synchronizer latency
    task automatic wait_sync(int i);
    begin
        repeat (i) @(posedge clk);
    end
    endtask

    // Initialize SPI master for a new transaction
    task automatic master_initialize(
        input logic [DATA_WIDTH-1:0] tx
    );
    begin
        master_tx_data  = tx;
        master_tx_shift = tx;
        master_rx_data  = '0;
        master_rx_shift = '0;
        master_cs_n     = 1'b0;
        master_sclk     = master_cpol;
        master_mosi     = 1'b0;
    end
    endtask

    // Preload first transmit bit for CPHA = 0
    task automatic master_preload();
    begin
        if (!master_cpha) begin
            master_mosi     = master_bit_order ? master_tx_shift[DATA_WIDTH-1] : master_tx_shift[0];
            master_tx_shift = master_bit_order ? (master_tx_shift << 1) : (master_tx_shift >> 1);
        end
    end
    endtask

    // Drive next transmit bit
    task automatic drive_next_bit();
    begin
        master_mosi     = master_bit_order ? master_tx_shift[DATA_WIDTH-1] : master_tx_shift[0];
        master_tx_shift = master_bit_order ? (master_tx_shift << 1) : (master_tx_shift >> 1);
    end
    endtask

    // Sample slave output
    task automatic sample_slave_bit();
    begin
        master_rx_shift = master_bit_order ? {master_rx_shift[DATA_WIDTH-2:0], miso} :
                                              {miso, master_rx_shift[DATA_WIDTH-1:1]};
    end
    endtask

    // Finish SPI transaction
    task automatic master_finish();
    begin
        master_rx_data = master_rx_shift;
        master_cs_n    = 1'b1;
        master_sclk    = master_cpol;
    end
    endtask

    // Check complete SPI transfer
    task automatic check_transfer(
        input logic [DATA_WIDTH-1:0] expected_master_rx,
        input logic [DATA_WIDTH-1:0] expected_slave_rx
    );
        begin
            check_master_rx(expected_master_rx);
            check_slave_rx(expected_slave_rx);
        end
    endtask

    // Perform one SPI Transfer
    task automatic spi_transfer(
        input logic [DATA_WIDTH-1:0] master_tx,
        input logic [DATA_WIDTH-1:0] slave_tx,
        input logic                  cpol_mode,
        input logic                  cpha_mode,
        input logic                  bit_order_mode
    );
        int i;
    begin
        // Configure DUT
        tx_data   = slave_tx;
        cpol      = cpol_mode;
        cpha      = cpha_mode;
        bit_order = bit_order_mode;

        // Configure reference model
        master_cpol      = cpol_mode;
        master_cpha      = cpha_mode;
        master_bit_order = bit_order_mode;

        master_initialize(master_tx);

        master_preload();

        // Allow CS_N and initial MOSI to synchronize
        wait_sync(5);

        for (i = 0; i < DATA_WIDTH; i++) begin
            // Shift edge
            master_sclk = ~master_sclk;
            wait_sync(2);
            if (master_cpha)
                drive_next_bit();

            // Sample edge
            master_sclk = ~master_sclk;
            wait_sync(2); #1;
            sample_slave_bit();
            if (!master_cpha && (i != DATA_WIDTH-1))
                drive_next_bit();
        end

        // Terminate transaction
        master_finish();

        // Wait for synchronization
        wait_sync(5);
    end
    endtask

    // Run and verify transfer
    task automatic run_transfer(
        input logic [DATA_WIDTH-1:0] master_tx,
        input logic [DATA_WIDTH-1:0] slave_tx,
        input logic                  cpol_mode,
        input logic                  cpha_mode,
        input logic                  bit_order_mode
    );
    begin
        spi_transfer(master_tx, slave_tx, cpol_mode, cpha_mode, bit_order_mode);

        check_transfer(slave_tx, master_tx);

        check_idle_state();
    end
    endtask

    // Print Summary
    task automatic print_summary;
        begin

            $display("\n==================================================");
            $display("             SPI SLAVE TEST SUMMARY");
            $display("==================================================");

            $display("Tests Run    : %0d", tests_run);
            $display("Tests Passed : %0d", tests_passed);
            $display("Tests Failed : %0d", tests_failed);

            if (tests_failed == 0)
                $display("OVERALL RESULT : PASS");
            else
                $display("OVERALL RESULT : FAIL");

            $display("==================================================");

        end
    endtask

    // Helper tasks end

    // Test tasks

    // Test reset behaviour
    task automatic test_reset();
    begin
        $display("\n=== Reset Behaviour Test ===");

        apply_reset();

        check_idle_state();
    end
    endtask

    // Test SPI modes
    task automatic test_spi_mode(
        input logic        cpol_mode,
        input logic        cpha_mode,
        input logic        bit_order_mode
    );
        begin
            $display("\n=== SPI Mode Test ===");
            $display("CPOL=%0b CPHA=%0b %s First",
                    cpol_mode,
                    cpha_mode,
                    bit_order_mode ? "MSB" : "LSB");

            run_transfer(8'hA5, 8'h3C, cpol_mode, cpha_mode, bit_order_mode);
        end
    endtask

    // Initiate SPI mode tests
    task automatic test_all_spi_modes();
        begin
            apply_reset();
            test_spi_mode(1'b0, 1'b0, 1'b1);
            apply_reset();
            test_spi_mode(1'b0, 1'b0, 1'b0);

            apply_reset();
            test_spi_mode(1'b0, 1'b1, 1'b1);
            apply_reset();
            test_spi_mode(1'b0, 1'b1, 1'b0);

            apply_reset();
            test_spi_mode(1'b1, 1'b0, 1'b1);
            apply_reset();
            test_spi_mode(1'b1, 1'b0, 1'b0);

            apply_reset();
            test_spi_mode(1'b1, 1'b1, 1'b1);
            apply_reset();
            test_spi_mode(1'b1, 1'b1, 1'b0);
        end
    endtask

    // Test early transaction abort
    task automatic test_early_cs_abort();
    begin
        $display("\n=== Early CS Abort Test ===");
        apply_reset();

        // Configure transfer
        tx_data          = 8'h3C;
        cpol             = 1'b0;
        cpha             = 1'b0;
        bit_order        = 1'b1;
        master_cpol      = 1'b0;
        master_cpha      = 1'b0;
        master_bit_order = 1'b1;

        master_initialize(8'hA5);
        master_preload();

        wait_sync(5);

        // Only a few clocks
        repeat (3) begin
            master_sclk = ~master_sclk;
            wait_sync(2);

            master_sclk = ~master_sclk;
            wait_sync(2);
        end

        // Abort transaction
        master_cs_n = 1'b1;
        wait_sync(5);
        record_test("Abort clears busy", busy == 1'b0);
        record_test("Abort does not assert done", done == 1'b0);
    end
    endtask

    // Test CS glitch (CS asserted then immediately deasserted without SCLK)
    task automatic test_cs_glitch();
    begin
        $display("\n=== CS Glitch Test ===");
        apply_reset();

        // Configure slave and master
        tx_data          = 8'h3C;
        cpol             = 1'b0;
        cpha             = 1'b0;
        bit_order        = 1'b1;

        master_cpol      = 1'b0;
        master_cpha      = 1'b0;
        master_bit_order = 1'b1;

        // Assert CS
        master_initialize(8'hA5);
        wait_sync(2);

        // Immediately deassert CS
        master_cs_n = 1'b1;
        wait_sync(5);

        // Verify no transaction occurred
        record_test("CS Glitch: Busy remains low", busy == 1'b0);
        record_test("CS Glitch: Done remains low", done == 1'b0);
        record_test("CS Glitch: RX data unchanged", rx_data == '0);
        check_idle_state();
    end
    endtask

    // Test transmitting all zeros
    task automatic test_all_zeros();
        begin
            $display("\n=== All Zeros Test ===");
            apply_reset();
            run_transfer('0, '0, 1'b0, 1'b0, 1'b1);
        end
    endtask

    // Test transmitting all ones
    task automatic test_all_ones();
        begin
            $display("\n=== All Ones Test ===");
            apply_reset();
            run_transfer('1, '1, 1'b0, 1'b0, 1'b1);
        end
    endtask

    // Test transmitting same value alternately
    task automatic test_alternating_patterns();
        begin
            $display("\n=== Alternating Pattern Test ===");
            apply_reset();
            run_transfer(8'hAA, 8'h55, 1'b0, 1'b0, 1'b1);
            run_transfer(8'h55, 8'hAA, 1'b0, 1'b0, 1'b1);
        end
    endtask

    // Test back to back transfers
    task automatic test_back_to_back_transfers();
        begin
            $display("\n=== Back-to-Back Transfer Test ===");
            apply_reset();
            run_transfer(8'h12, 8'h34, 1'b0, 1'b0, 1'b1);
            run_transfer(8'h56, 8'h78, 1'b0, 1'b0, 1'b1);
            run_transfer(8'h9A, 8'hBC, 1'b0, 1'b0, 1'b1);
            run_transfer(8'hDE, 8'hF0, 1'b0, 1'b0, 1'b1);
        end
    endtask

    // Random transfer stress test
    task automatic test_random_transfers();
        logic [DATA_WIDTH-1:0] master_data;
        logic [DATA_WIDTH-1:0] slave_data;

        logic rand_cpol;
        logic rand_cpha;
        logic rand_bit_order;

        begin
            $display("\n=== Random Transfer Test (%0d iterations) ===", RANDOM_ITERATIONS);
            apply_reset();

            for (int i = 0; i < RANDOM_ITERATIONS; i++) begin
                master_data     = $urandom;
                slave_data      = $urandom;
                rand_cpol       = $urandom;
                rand_cpha       = $urandom;
                rand_bit_order  = $urandom;

                run_transfer(master_data, slave_data, rand_cpol, rand_cpha, rand_bit_order);
            end
        end
    endtask

    // Test tasks end

    // Main test sequence
    initial begin
        test_reset();

        test_all_spi_modes();

        test_early_cs_abort();

        test_cs_glitch();

        test_all_zeros();

        test_all_ones();

        test_alternating_patterns();

        test_back_to_back_transfers();

        test_random_transfers();

        print_summary();

        $finish;
    end

endmodule
