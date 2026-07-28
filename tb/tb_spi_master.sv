`timescale 1ns/1ps

module tb_spi_master;

    // Configuration parameters
    localparam int DATA_WIDTH = 8;
    localparam int CLOCK_DIV  = 4;

    // Parameters for reference and timing
    localparam time CLOCK_PERIOD_NS    = 10ns;
    localparam int RANDOM_ITERATIONS   = 10000;
    localparam int CYCLES_PER_TRANSFER = (DATA_WIDTH * 2 * CLOCK_DIV) + 20;
    localparam int BASE_TEST_CYCLES    = 25 * CYCLES_PER_TRANSFER;
    localparam int TIMEOUT_CYCLES      = BASE_TEST_CYCLES+(RANDOM_ITERATIONS * CYCLES_PER_TRANSFER);
    localparam int RESET_CYCLES        = 3;

    // DUT signals
    logic                  clk;
    logic                  rst_n;
    logic                  start;
    logic [DATA_WIDTH-1:0] tx_data;
    logic                  miso;
    logic                  cpol;
    logic                  cpha;
    logic                  bit_order;
    logic                  mosi;
    logic                  sclk;
    logic                  cs_n;
    logic [DATA_WIDTH-1:0] rx_data;
    logic                  busy;
    logic                  done;

    // Verification statistics
    int tests_run    = 0;
    int tests_passed = 0;
    int tests_failed = 0;

    // Slave Reference Model signals
    logic [DATA_WIDTH-1:0] slave_tx_data;
    logic [DATA_WIDTH-1:0] slave_tx_shift;
    logic [DATA_WIDTH-1:0] slave_rx_data;
    logic [DATA_WIDTH-1:0] slave_rx_shift;
    logic                  slave_cpol;
    logic                  slave_cpha;
    logic                  slave_bit_order;
    logic                  slave_miso;

    // Connection
    assign miso = slave_miso;

    // Test variables

    // DUT instantiation
    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLOCK_DIV(CLOCK_DIV)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .miso(miso),
        .cpol(cpol),
        .cpha(cpha),
        .bit_order(bit_order),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),
        .rx_data(rx_data),
        .busy(busy),
        .done(done)
    );

    // Assertions
    sva_spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLOCK_DIV(CLOCK_DIV)
    ) sva (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(tx_data),
        .miso(miso),
        .cpol(cpol),
        .cpha(cpha),
        .bit_order(bit_order),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),
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
        $dumpfile("spi_master_waveform.vcd");
        $dumpvars(0, tb_spi_master);
    end

    // SPI Slave Behavioural Reference Model
    initial begin : spi_slave_model
        slave_miso = 1'b0;

        // Wait for reset to be released
        wait(rst_n === 1'b1);

        forever begin
            // Wait for slave selection
            wait (cs_n == 1'b0);

            // Latch transaction configuration
            slave_cpol      = cpol;
            slave_cpha      = cpha;
            slave_bit_order = bit_order;

            // Initialize transaction
            slave_tx_shift = slave_tx_data;
            slave_rx_shift = '0;

            for (int i = 0; i < DATA_WIDTH; i++) begin
                if (slave_cpha) begin
                    // CPHA = 1: Shift edge occurs BEFORE sample edge
                    wait_shift_edge();
                    slave_miso = slave_bit_order ? slave_tx_shift[DATA_WIDTH-1] : slave_tx_shift[0];
                    slave_tx_shift = slave_bit_order ? (slave_tx_shift << 1) :(slave_tx_shift >> 1);

                    wait_sample_edge();
                    if (slave_bit_order) begin
                        slave_rx_shift = {slave_rx_shift[DATA_WIDTH-2:0], mosi};
                    end else begin
                        slave_rx_shift = {mosi, slave_rx_shift[DATA_WIDTH-1:1]};
                    end
                end
                else begin
                    // CPHA = 0: Preload/Sample occurs BEFORE shift edge

                    // Pre-load the very first bit before the first sample edge
                    if (i == 0) begin
                        slave_miso = slave_bit_order?slave_tx_shift[DATA_WIDTH-1]:slave_tx_shift[0];
                        slave_tx_shift =slave_bit_order?(slave_tx_shift << 1):(slave_tx_shift >> 1);
                    end

                    wait_sample_edge();
                    if (slave_bit_order) begin
                        slave_rx_shift = {slave_rx_shift[DATA_WIDTH-2:0], mosi};
                    end else begin
                        slave_rx_shift = {mosi, slave_rx_shift[DATA_WIDTH-1:1]};
                    end

                    // Wait for the shift edge
                    wait_shift_edge();
                    if (i != DATA_WIDTH-1) begin
                        slave_miso = slave_bit_order?slave_tx_shift[DATA_WIDTH-1]:slave_tx_shift[0];
                        slave_tx_shift =slave_bit_order?(slave_tx_shift << 1):(slave_tx_shift >> 1);
                    end
                end
            end

            // Store received word
            slave_rx_data = slave_rx_shift;

            // Wait for transaction completion
            wait (cs_n == 1'b1);

            // Return MISO to idle
            slave_miso = 1'b0;
        end
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
    task automatic apply_reset;
        begin
            // Apply Reset
            rst_n     = 1'b0;
            start     = 1'b0;
            tx_data   = '0;
            cpol      = 1'b0;
            cpha      = 1'b0;
            bit_order = 1'b0;

            // Reset slave reference model
            slave_tx_data   = '0;
            slave_tx_shift  = '0;
            slave_rx_data   = '0;
            slave_rx_shift  = '0;
            slave_cpol      = 1'b0;
            slave_cpha      = 1'b0;
            slave_bit_order = 1'b0;
            slave_miso      = 1'b0;

            // Hold reset
            repeat(RESET_CYCLES) @(posedge clk);

            // Release reset
            rst_n = 1'b1;

            @(posedge clk);
        end
    endtask

    // Wait for done
    task automatic wait_for_done();
        begin
            @(posedge clk);

            wait(done);

            @(posedge clk);
        end
    endtask

    // Wait for sample edge
    task automatic wait_sample_edge;
    begin
        case ({slave_cpol, slave_cpha})
            2'b00: @(posedge sclk);
            2'b01: @(negedge sclk);
            2'b10: @(negedge sclk);
            2'b11: @(posedge sclk);
            default: $fatal(1,"Invalid SPI mode");
        endcase
    end
    endtask

    // Wait for shift edge
    task automatic wait_shift_edge;
    begin
        case ({slave_cpol, slave_cpha})
            2'b00: @(negedge sclk);
            2'b01: @(posedge sclk);
            2'b10: @(posedge sclk);
            2'b11: @(negedge sclk);
            default: $fatal(1,"Invalid SPI mode");
        endcase
    end
    endtask

    // Check received data at master
    task automatic check_master_rx(
        input logic [DATA_WIDTH-1:0] expected
    );
        begin
            record_test(
                $sformatf("Master RX = 0x%02h", expected), (rx_data === expected));
        end
    endtask

    // Check received data at slave
    task automatic check_slave_rx(
        input logic [DATA_WIDTH-1:0] expected
    );
        begin
            record_test(
                $sformatf("Slave RX = 0x%02h", expected), (slave_rx_data === expected));
        end
    endtask

    // Check SPI returns to idle after transaction
    task automatic check_idle_state;
        begin
            record_test(
                "Idle State",
                busy    == 1'b0 &&
                done    == 1'b0 &&
                cs_n    == 1'b1 &&
                sclk    == cpol &&
                start   == 1'b0
            );
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

    // Perform one SPI transaction
    task automatic spi_transfer(
        input  logic [DATA_WIDTH-1:0] master_tx,
        input  logic [DATA_WIDTH-1:0] slave_tx,
        input  logic                  cpol_mode,
        input  logic                  cpha_mode,
        input  logic                  bit_order_mode
    );
        begin
            // Configure transaction
            tx_data       = master_tx;
            slave_tx_data = slave_tx;
            cpol          = cpol_mode;
            cpha          = cpha_mode;
            bit_order     = bit_order_mode;

            // Start transaction
            @(posedge clk);
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            // Wait for completion
            wait_for_done();

            // Wait one cycle before returning
            @(posedge clk);
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
            $display("             SPI MASTER TEST SUMMARY");
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

    // Test mid transmission CPOL & CPHA change
    task automatic test_mid_transmission_change();
        begin
            $display("\n=== Mid-Transmission Mode Change Test ===");
            apply_reset();

            // Set initial configurations
            tx_data       = $urandom;
            slave_tx_data = $urandom;
            cpol          = 1'b0;
            cpha          = 1'b0;
            bit_order     = 1'b1;

            // Trigger start
            @(posedge clk);
            start = 1'b1;
            @(posedge clk);
            start = 1'b0;

            // Wait for transaction to begin
            wait(busy == 1'b1);

            // Toggle `cpol` and `cpha` dynamically mid-transmission
            repeat(4) @(posedge clk);
            cpol = 1'b1;
            cpha = 1'b1;

            // Wait for completion
            wait_for_done();

            // Check output
            check_transfer(slave_tx_data, tx_data);

            // Verify it returns safely to idle and adapts to the new configuration
            @(posedge clk);
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

        test_mid_transmission_change();

        test_all_zeros();

        test_all_ones();

        test_alternating_patterns();

        test_back_to_back_transfers();

        test_random_transfers();

        print_summary();

        $finish;
    end

endmodule
