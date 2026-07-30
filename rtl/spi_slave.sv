module spi_slave #(
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
    input  logic                  bit_order,            // low for LSB first, high for MSB first

    output logic                  miso,
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  busy,
    output logic                  done
);

    // Local parameters
    localparam int BIT_CNT_WIDTH = (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);

    // State encoding
    typedef enum logic [1:0] {
        IDLE,
        START,
        TRANSFER,
        STOP
    } state_t;
    state_t state, next_state;

    // Configuration registers
    logic                     cpol_reg, next_cpol_reg;
    logic                     cpha_reg, next_cpha_reg;
    logic                     bit_order_reg, next_bit_order_reg;

    // Datapath registers
    logic [DATA_WIDTH-1:0]    tx_shift_reg, next_tx_shift_reg;
    logic [DATA_WIDTH-1:0]    rx_shift_reg, next_rx_shift_reg;
    logic [DATA_WIDTH-1:0]    rx_data_reg, next_rx_data_reg;

    // Control registers
    logic [BIT_CNT_WIDTH-1:0] bit_count, next_bit_count;

    // Synchronizer
    logic sclk_sync_ff1, sclk_sync_ff2;
    logic sclk_sync;
    logic cs_sync_ff1, cs_sync_ff2;
    logic cs_sync;
    logic mosi_sync_ff1, mosi_sync_ff2;
    logic mosi_sync;

    // Output registers
    logic                     miso_reg, next_miso_reg;
    logic                     busy_reg, next_busy_reg;
    logic                     done_reg, next_done_reg;

    // Previous synchronized SCLK
    logic sclk_prev;

    // Edge detection
    logic sclk_rise;
    logic sclk_fall;

    // Internal signals
    logic sample_edge, shift_edge;
    logic transfer_finish;
    logic final_edge;

    // Signal assignment
    assign sclk_rise       = ~sclk_prev &  sclk_sync;
    assign sclk_fall       =  sclk_prev & ~sclk_sync;
    assign transfer_finish = (bit_count == DATA_WIDTH - 1);
    assign final_edge      = (cpha_reg == 1'b0) ? shift_edge : sample_edge;

    // Synchronization
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            sclk_sync_ff1 <= 1'b0;
            sclk_sync_ff2 <= 1'b0;
            sclk_prev     <= 1'b0;
            sclk_sync     <= 1'b0;
            cs_sync_ff1   <= 1'b1;
            cs_sync_ff2   <= 1'b1;
            cs_sync       <= 1'b1;
            mosi_sync_ff1 <= 1'b0;
            mosi_sync_ff2 <= 1'b0;
            mosi_sync     <= 1'b0;
        end
        else begin
            // Synchronize sclk
            sclk_sync_ff1 <= sclk;
            sclk_sync_ff2 <= sclk_sync_ff1;
            sclk_prev     <= sclk_sync;
            sclk_sync     <= sclk_sync_ff2;
            // Synchronize cs_n
            cs_sync_ff1   <= cs_n;
            cs_sync_ff2   <= cs_sync_ff1;
            cs_sync       <= cs_sync_ff2;
            // Synchronize mosi
            mosi_sync_ff1 <= mosi;
            mosi_sync_ff2 <= mosi_sync_ff1;
            mosi_sync     <= mosi_sync_ff2;
        end
    end

    // State transition logic
    always_comb begin
        next_state           = state;
        next_cpol_reg        = cpol_reg;
        next_cpha_reg        = cpha_reg;
        next_bit_order_reg   = bit_order_reg;
        next_tx_shift_reg    = tx_shift_reg;
        next_rx_shift_reg    = rx_shift_reg;
        next_rx_data_reg     = rx_data_reg;
        next_bit_count       = bit_count;
        next_miso_reg        = miso_reg;
        next_busy_reg        = busy_reg;
        next_done_reg        = done_reg;
        sample_edge          = 1'b0;
        shift_edge           = 1'b0;
        case (state)
            IDLE: begin
                next_busy_reg = 1'b0;
                next_done_reg = 1'b0;
                if (!cs_sync) begin
                    next_state = START;
                end
            end

            START: begin
                next_state           = TRANSFER;
                next_cpol_reg        = cpol;
                next_cpha_reg        = cpha;
                next_bit_order_reg   = bit_order;
                next_tx_shift_reg    = tx_data;
                next_rx_shift_reg    = '0;
                next_busy_reg        = 1'b1;
                next_done_reg        = 1'b0;
                next_bit_count       = '0;
                // Pre-loading MISO for CPHA = 0
                if (!cpha) begin
                    next_miso_reg     = bit_order ? tx_data[DATA_WIDTH-1] : tx_data[0];
                    next_tx_shift_reg = bit_order ? tx_data << 1 : tx_data >> 1;
                end
            end

            TRANSFER: begin
                // SPI Mode Decoding
                case ({cpol_reg, cpha_reg})
                    // Mode 0
                    2'b00: begin
                        sample_edge = sclk_rise;
                        shift_edge  = sclk_fall;
                    end
                    // Mode 1
                    2'b01: begin
                        sample_edge = sclk_fall;
                        shift_edge  = sclk_rise;
                    end
                    // Mode 2
                    2'b10: begin
                        sample_edge = sclk_fall;
                        shift_edge  = sclk_rise;
                    end
                    // Mode 3
                    2'b11: begin
                        sample_edge = sclk_rise;
                        shift_edge  = sclk_fall;
                    end
                    default: begin
                        sample_edge = sclk_rise;
                        shift_edge  = sclk_fall;
                    end
                endcase

                // Transfer
                // Transmission
                if (shift_edge) begin
                    next_miso_reg     = bit_order_reg ? tx_shift_reg[DATA_WIDTH-1] :tx_shift_reg[0];
                    next_tx_shift_reg = bit_order_reg ? tx_shift_reg << 1 : tx_shift_reg >> 1;
                end
                // Reception
                else if (sample_edge) begin
                    next_rx_shift_reg = bit_order_reg ?
                                        {rx_shift_reg[DATA_WIDTH-2:0], mosi_sync} :
                                        {mosi_sync, rx_shift_reg[DATA_WIDTH-1:1]};
                end

                // Counter update
                if (final_edge && !transfer_finish) begin
                    next_bit_count = bit_count + 1'b1;
                end

                // Check if master aborts transfer
                if (cs_sync) begin
                    next_state    = STOP;
                    next_busy_reg = 1'b0;
                    next_done_reg = 1'b0;
                end
                // Transfer status check
                else if (transfer_finish && final_edge) begin
                    next_state       = STOP;
                    next_busy_reg    = 1'b0;
                    next_done_reg    = 1'b1;
                    next_rx_data_reg = next_rx_shift_reg;
                end
                else begin
                    next_state = TRANSFER;
                end
            end

            STOP: begin
                next_done_reg = 1'b0;
                if (cs_sync) begin
                    next_state           = IDLE;
                end
                else begin
                    // Delaying STOP
                    next_state           = STOP;
                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Registers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state           <= IDLE;
            cpol_reg        <= '0;
            cpha_reg        <= '0;
            bit_order_reg   <= '0;
            tx_shift_reg    <= '0;
            rx_shift_reg    <= '0;
            rx_data_reg     <= '0;
            bit_count       <= '0;
            miso_reg        <= '0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
        end
        else begin
            state           <= next_state;
            cpol_reg        <= next_cpol_reg;
            cpha_reg        <= next_cpha_reg;
            bit_order_reg   <= next_bit_order_reg;
            tx_shift_reg    <= next_tx_shift_reg;
            rx_shift_reg    <= next_rx_shift_reg;
            rx_data_reg     <= next_rx_data_reg;
            bit_count       <= next_bit_count;
            miso_reg        <= next_miso_reg;
            busy_reg        <= next_busy_reg;
            done_reg        <= next_done_reg;
        end
    end

    // Output logic
    assign miso    = miso_reg;
    assign rx_data = rx_data_reg;
    assign busy    = busy_reg;
    assign done    = done_reg;

    // synthesis translate_off

    // Parameter validation
    initial begin
        bit error_check;
        error_check = 0;
        if (DATA_WIDTH <= 0) begin
            $error("DATA_WIDTH must be greater than 0.");
            error_check = 1;
        end
        if (error_check) begin
            $fatal(0);
        end
    end

    // synthesis translate_on

endmodule
