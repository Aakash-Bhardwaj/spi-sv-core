module sva_spi_slave #(
    parameter int DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [DATA_WIDTH-1:0] tx_data,
    input  logic                  mosi,
    input  logic                  sclk,
    input  logic                  cs_n,
    input  logic                  cpol,
    input  logic                  cpha,
    input  logic                  bit_order,
    input  logic                  miso,
    input  logic [DATA_WIDTH-1:0] rx_data,
    input  logic                  busy,
    input  logic                  done
);

// The slave cannot be busy and done at the exact same time
always @(posedge clk) begin
    if (rst_n) begin
        assert (!(busy && done))
            else $error("SPI Slave is both BUSY and DONE simultaneously");
    end
end

// Outputs should never contain unknowns (X or Z values)
always @(posedge clk) begin
    if (rst_n) begin
        assert (!$isunknown(miso))
            else $error("miso contains X");

        assert (!$isunknown(rx_data))
            else $error("rx_data contains X");

        assert (!$isunknown(busy))
            else $error("busy contains X");

        assert (!$isunknown(done))
            else $error("done contains X");
    end
end

// Done signal should be a strict one-cycle pulse
logic done_prev;

always @(posedge clk) begin
    if (!rst_n) begin
        done_prev <= 1'b0;
    end else begin
        done_prev <= done;
        if (done_prev) begin
            assert (!done)
                else $error("DONE signal remained asserted for more than 1 clock cycle");
        end
    end
end

endmodule
