module sva_spi_master #(
    parameter int DATA_WIDTH = 8,
    parameter int CLOCK_DIV  = 4
)(
    input logic                  clk,
    input logic                  rst_n,
    input logic                  start,
    input logic [DATA_WIDTH-1:0] tx_data,
    input logic                  miso,
    input logic                  cpol,
    input logic                  cpha,
    input logic                  bit_order,
    input logic                  mosi,
    input logic                  sclk,
    input logic                  cs_n,
    input logic [DATA_WIDTH-1:0] rx_data,
    input logic                  busy,
    input logic                  done
);

// CS_N and Busy should always be perfectly inverted in this design
always @(posedge clk) begin
    if (rst_n) begin
        assert (cs_n == ~busy)
            else $error("CS_N and BUSY are not properly synchronized inverses");
    end
end

// The master cannot be busy and done at the exact same time
always @(posedge clk) begin
    if (rst_n) begin
        assert (!(busy && done))
            else $error("SPI Master is both BUSY and DONE simultaneously");
    end
end

// Outputs should never contain unknowns (X or Z values)
always @(posedge clk) begin
    if (rst_n) begin
        assert (!$isunknown(mosi))
            else $error("mosi contains X");

        assert (!$isunknown(sclk))
            else $error("sclk contains X");

        assert (!$isunknown(cs_n))
            else $error("cs_n contains X");

        assert (!$isunknown(rx_data))
            else $error("rx_data contains X");

        assert (!$isunknown(busy))
            else $error("busy contains X");

        assert (!$isunknown(done))
            else $error("done contains X");
    end
end

endmodule
