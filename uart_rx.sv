
module uart_rx #(
    parameter CLK_FREQ  = 10_000_000,
    parameter BAUD_RATE = 1_000_000
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       rx,

    output logic [7:0] rx_data,
    output logic       rx_valid,

    output logic       framing_error,
    output logic       parity_error
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BIT     = CLKS_PER_BIT / 2;


    // =========================================================
    // RX FSM
    // =========================================================

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP
    } state_t;

    state_t state;


    // =========================================================
    // INTERNAL REGISTERS
    // =========================================================

    integer baud_counter;
    integer bit_counter;

    logic [7:0] rx_data_reg;

    logic rx_parity_reg;

    // Stored parity error.
    // Needed because parity_error itself is a pulse.
    logic parity_error_reg;


    // =========================================================
    // TWO-FLIP-FLOP SYNCHRONIZER
    // =========================================================

    logic rx_sync1;
    logic rx_sync2;


    always_ff @(posedge clk) begin

        if (rst) begin

            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;

        end

        else begin

            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;

        end

    end


    // =========================================================
    // MAIN RX FSM
    // =========================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            state <= IDLE;

            baud_counter <= 0;
            bit_counter  <= 0;

            rx_data_reg      <= 8'b0;
            rx_parity_reg    <= 1'b0;
            parity_error_reg <= 1'b0;

            rx_data       <= 8'b0;
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;
            parity_error  <= 1'b0;

        end

        else begin

            // Error/valid signals are one-clock pulses
            rx_valid      <= 1'b0;
            framing_error <= 1'b0;
            parity_error  <= 1'b0;


            case (state)


                // =================================================
                // IDLE
                // =================================================

                IDLE: begin

                    baud_counter <= 0;
                    bit_counter  <= 0;

                    // UART is idle HIGH.
                    // Detect START = LOW.
                    if (rx_sync2 == 1'b0) begin

                        // Clear previous frame's parity error
                        parity_error_reg <= 1'b0;

                        state <= START;

                    end

                end


                // =================================================
                // START
                // =================================================

                START: begin

                    // Wait half a bit period.
                    // This samples near the center of START.
                    if (baud_counter == HALF_BIT-1) begin

                        baud_counter <= 0;

                        // Confirm START is still LOW
                        if (rx_sync2 == 1'b0) begin

                            state <= DATA;

                        end

                        else begin

                            // False start
                            state <= IDLE;

                        end

                    end

                    else begin

                        baud_counter <= baud_counter + 1;

                    end

                end


                // =================================================
                // DATA
                // =================================================

                DATA: begin

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        // UART transmits LSB first
                        rx_data_reg[bit_counter] <= rx_sync2;

                        if (bit_counter == 7) begin

                            bit_counter <= 0;

                            state <= PARITY;

                        end

                        else begin

                            bit_counter <= bit_counter + 1;

                        end

                    end

                    else begin

                        baud_counter <= baud_counter + 1;

                    end

                end


                // =================================================
                // PARITY
                // =================================================

                PARITY: begin

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        // Capture received parity
                        rx_parity_reg <= rx_sync2;

                        // Even parity:
                        //
                        // parity bit should equal XOR of data bits
                        //
                        // If they differ, parity is wrong.

                        if (rx_sync2 != ^rx_data_reg) begin

                            parity_error_reg <= 1'b1;
                            parity_error     <= 1'b1;

                        end

                        else begin

                            parity_error_reg <= 1'b0;

                        end

                        state <= STOP;

                    end

                    else begin

                        baud_counter <= baud_counter + 1;

                    end

                end


                // =================================================
                // STOP
                // =================================================

                STOP: begin

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        // STOP bit must be HIGH
                        if (rx_sync2 == 1'b1) begin

                            rx_data <= rx_data_reg;

                            // Only accept data if parity is correct
                            if (parity_error_reg == 1'b0) begin

                                rx_valid <= 1'b1;

                            end

                        end

                        else begin

                            // STOP bit was LOW
                            framing_error <= 1'b1;

                        end

                        state <= IDLE;

                    end

                    else begin

                        baud_counter <= baud_counter + 1;

                    end

                end

            endcase

        end

    end

endmodule