module sva_spi_top #(
    parameter int DATA_WIDTH = 8,
    parameter int CLOCK_DIV  = 8
)(
    input logic                  clk,
    input logic                  rst_n,
    input logic                  start,
    input logic [DATA_WIDTH-1:0] master_tx_data,
    input logic [DATA_WIDTH-1:0] slave_tx_data,
    input logic                  cpol,
    input logic                  cpha,
    input logic                  bit_order,
    input logic [DATA_WIDTH-1:0] master_rx_data,
    input logic [DATA_WIDTH-1:0] slave_rx_data,
    input logic                  master_busy,
    input logic                  master_done,
    input logic                  slave_busy,
    input logic                  slave_done
);

// Neither the master nor the slave should be busy and done at the exact same time
always @(posedge clk) begin
    if (rst_n) begin
        assert (!(master_busy && master_done))
            else $error("SPI Top: Master is both BUSY and DONE simultaneously");

        assert (!(slave_busy && slave_done))
            else $error("SPI Top: Slave is both BUSY and DONE simultaneously");
    end
end

// Top-level outputs should never contain unknowns (X or Z values)
always @(posedge clk) begin
    if (rst_n) begin
        assert (!$isunknown(master_rx_data))
            else $error("master_rx_data contains X");

        assert (!$isunknown(slave_rx_data))
            else $error("slave_rx_data contains X");

        assert (!$isunknown(master_busy))
            else $error("master_busy contains X");

        assert (!$isunknown(master_done))
            else $error("master_done contains X");

        assert (!$isunknown(slave_busy))
            else $error("slave_busy contains X");

        assert (!$isunknown(slave_done))
            else $error("slave_done contains X");
    end
end

// Master and Slave DONE signals should be strict one-cycle pulses
logic master_done_prev;
logic slave_done_prev;

always @(posedge clk) begin
    if (!rst_n) begin
        master_done_prev <= 1'b0;
        slave_done_prev  <= 1'b0;
    end else begin
        master_done_prev <= master_done;
        slave_done_prev  <= slave_done;

        if (master_done_prev) begin
            assert (!master_done)
                else $error("master_done signal remained asserted for more than 1 clock cycle");
        end

        if (slave_done_prev) begin
            assert (!slave_done)
                else $error("slave_done signal remained asserted for more than 1 clock cycle");
        end
    end
end

endmodule
