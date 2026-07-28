module spi_master #(
    parameter int DATA_WIDTH = 8,
    // Number of system clock cycles in one half-period of SCLK.
    // f_sclk = f_clk / (2 * CLOCK_DIV)
    parameter int CLOCK_DIV  = 4
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  start,
    input  logic [DATA_WIDTH-1:0] tx_data,

    input  logic                  miso,

    input  logic                  cpol,
    input  logic                  cpha,
    input  logic                  bit_order,        // low for LSB first, high for MSB first

    output logic                  mosi,
    output logic                  sclk,
    output logic                  cs_n,

    output logic [DATA_WIDTH-1:0] rx_data,

    output logic                  busy,
    output logic                  done
);

    // Local parameters
    localparam int DIV_WIDTH     = (CLOCK_DIV <= 1) ? 1 : $clog2(CLOCK_DIV);
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
    logic [DIV_WIDTH-1:0]     clk_div_counter, next_clk_div_counter;
    logic [BIT_CNT_WIDTH-1:0] bit_count, next_bit_count;

    // Output registers
    logic                     mosi_reg, next_mosi_reg;
    logic                     sclk_reg, next_sclk_reg;
    logic                     cs_n_reg, next_cs_n_reg;
    logic                     busy_reg, next_busy_reg;
    logic                     done_reg, next_done_reg;

    // Internal signals
    logic sclk_toggle;
    logic sclk_rise, sclk_fall;
    logic sample_edge, shift_edge;
    logic transfer_finish, toggle_now;
    logic final_edge;

    // Signal assignment
    assign transfer_finish = (bit_count == DATA_WIDTH - 1);
    assign toggle_now      = (clk_div_counter == CLOCK_DIV - 1);
    assign final_edge      = (cpha_reg == 1'b0) ? shift_edge : sample_edge;

    // State transition logic
    always_comb begin
        next_state           = state;
        next_cpol_reg        = cpol_reg;
        next_cpha_reg        = cpha_reg;
        next_bit_order_reg   = bit_order_reg;
        next_tx_shift_reg    = tx_shift_reg;
        next_rx_shift_reg    = rx_shift_reg;
        next_rx_data_reg     = rx_data_reg;
        next_clk_div_counter = clk_div_counter;
        next_bit_count       = bit_count;
        next_mosi_reg        = mosi_reg;
        next_sclk_reg        = sclk_reg;
        next_cs_n_reg        = cs_n_reg;
        next_busy_reg        = busy_reg;
        next_done_reg        = done_reg;
        sclk_rise            = 1'b0;
        sclk_fall            = 1'b0;
        sample_edge          = 1'b0;
        shift_edge           = 1'b0;
        sclk_toggle          = 1'b0;
        case (state)
            IDLE: begin
                next_busy_reg = 1'b0;
                next_done_reg = 1'b0;
                next_cs_n_reg = 1'b1;
                next_sclk_reg = cpol;
                if (start) begin
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
                next_clk_div_counter = '0;
                next_cs_n_reg        = 1'b0;
                next_sclk_reg        = cpol;
                // Pre-loading MOSI for CPHA = 0
                if (!cpha) begin
                    next_mosi_reg     = bit_order ? tx_data[DATA_WIDTH-1] : tx_data[0];
                    next_tx_shift_reg = bit_order ? tx_data << 1 : tx_data >> 1;
                end
            end

            TRANSFER: begin
                // Divider
                if(toggle_now) begin
                    next_clk_div_counter = '0;
                    sclk_toggle          = 1'b1;
                end
                else begin
                    next_clk_div_counter = clk_div_counter + 1'b1;
                    sclk_toggle          = 1'b0;
                end

                // SCLK Generation
                if (sclk_toggle) begin
                    if (!sclk_reg) begin
                        sclk_rise     = 1'b1;
                        next_sclk_reg = 1'b1;
                    end
                    else begin
                        sclk_fall     = 1'b1;
                        next_sclk_reg = 1'b0;
                    end
                end
                else begin
                    sclk_rise = 1'b0;
                    sclk_fall = 1'b0;
                end

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
                    next_mosi_reg     = bit_order_reg ? tx_shift_reg[DATA_WIDTH-1] :tx_shift_reg[0];
                    next_tx_shift_reg = bit_order_reg ? tx_shift_reg << 1 : tx_shift_reg >> 1;
                end
                // Reception
                else if (sample_edge) begin
                    next_rx_shift_reg = bit_order_reg ?
                                        {rx_shift_reg[DATA_WIDTH-2:0], miso} :
                                        {miso, rx_shift_reg[DATA_WIDTH-1:1]};
                end

                // Counter update
                if (final_edge && !transfer_finish) begin
                    next_bit_count = bit_count + 1'b1;
                end

                // Transfer status check
                if (transfer_finish && final_edge) begin
                    next_state = STOP;
                end
                else begin
                    next_state = TRANSFER;
                end
            end

            STOP: begin
                next_sclk_reg = cpol_reg;

                // Wait for half a SPI clock period to synchronize
                if (toggle_now) begin
                    next_state           = IDLE;
                    next_cs_n_reg        = 1'b1;
                    next_busy_reg        = 1'b0;
                    next_done_reg        = 1'b1;
                    next_rx_data_reg     = rx_shift_reg;
                    next_clk_div_counter = '0;
                end
                else begin
                    // Delaying STOP
                    next_clk_div_counter = clk_div_counter + 1'b1;
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
            clk_div_counter <= '0;
            bit_count       <= '0;
            mosi_reg        <= '0;
            sclk_reg        <= '0;
            cs_n_reg        <= 1'b1;
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
            clk_div_counter <= next_clk_div_counter;
            bit_count       <= next_bit_count;
            mosi_reg        <= next_mosi_reg;
            sclk_reg        <= next_sclk_reg;
            cs_n_reg        <= next_cs_n_reg;
            busy_reg        <= next_busy_reg;
            done_reg        <= next_done_reg;
        end
    end

    // Output logic
    assign mosi    = mosi_reg;
    assign sclk    = sclk_reg;
    assign cs_n    = cs_n_reg;
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
