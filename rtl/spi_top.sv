module spi_top #(
    parameter int DATA_WIDTH = 8,
    // Number of system clock cycles in one half-period of SCLK.
    // f_sclk = f_clk / (2 * CLOCK_DIV)
    parameter int CLOCK_DIV  = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  start,
    input  logic [DATA_WIDTH-1:0] master_tx_data,
    input  logic [DATA_WIDTH-1:0] slave_tx_data,

    input  logic                  cpol,
    input  logic                  cpha,
    input  logic                  bit_order,        // low for LSB first, high for MSB first

    output logic [DATA_WIDTH-1:0] master_rx_data,
    output logic [DATA_WIDTH-1:0] slave_rx_data,

    output logic                  master_busy,
    output logic                  master_done,
    output logic                  slave_busy,
    output logic                  slave_done
);

    // Internal signals
    logic mosi, miso;
    logic sclk;
    logic cs_n;

    // Instantiating SPI master
    spi_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLOCK_DIV(CLOCK_DIV)
    ) u_master (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .tx_data(master_tx_data),
        .miso(miso),
        .cpol(cpol),
        .cpha(cpha),
        .bit_order(bit_order),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),
        .rx_data(master_rx_data),
        .busy(master_busy),
        .done(master_done)
    );

    // Instantiating SPI slave
    spi_slave #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_slave (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data(slave_tx_data),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),
        .cpol(cpol),
        .cpha(cpha),
        .bit_order(bit_order),
        .miso(miso),
        .rx_data(slave_rx_data),
        .busy(slave_busy),
        .done(slave_done)
    );

    // synthesis translate_off

    // Parameter validation
    initial begin
        bit error_check;
        error_check = 0;
        if (DATA_WIDTH <= 0) begin
            $error("DATA_WIDTH must be greater than 0.");
            error_check = 1;
        end
        if (CLOCK_DIV <= 1) begin
            $error("CLOCK_DIV must be greater than 1.");
            error_check = 1;
        end
        if (error_check) begin
            $fatal(0);
        end
    end

    // synthesis translate_on

endmodule
