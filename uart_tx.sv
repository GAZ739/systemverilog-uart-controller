
module uart_tx #(
    parameter CLK_FREQ  = 10_000_000,
    parameter BAUD_RATE = 1_000_000
)(
    input  logic       clk,
    input  logic       rst,

    input  logic [7:0] tx_data,
    input  logic       tx_start,

    output logic       tx,
    output logic       tx_busy,
    output logic       tx_done
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        PARITY,
        STOP
    } state_t;

    state_t state;

    logic [7:0] tx_data_reg;
    logic       parity_bit;

    integer baud_counter;
    integer bit_counter;


    always_ff @(posedge clk) begin

        if (rst) begin

            state        <= IDLE;

            tx           <= 1'b1;
            tx_busy      <= 1'b0;
            tx_done      <= 1'b0;

            tx_data_reg  <= 8'b0;
            parity_bit   <= 1'b0;

            baud_counter <= 0;
            bit_counter  <= 0;

        end

        else begin

            // tx_done is a one-clock pulse
            tx_done <= 1'b0;

            case (state)


                // =================================================
                // IDLE
                // =================================================

                IDLE: begin

                    tx           <= 1'b1;
                    tx_busy      <= 1'b0;

                    baud_counter <= 0;
                    bit_counter  <= 0;

                    if (tx_start) begin

                        tx_data_reg <= tx_data;

                        // Even parity
                        parity_bit <= ^tx_data;

                        tx_busy <= 1'b1;

                        state <= START;

                    end

                end


                // =================================================
                // START BIT
                // =================================================

                START: begin

                    tx <= 1'b0;

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        state <= DATA;

                    end

                    else begin

                        baud_counter <= baud_counter + 1;

                    end

                end


                // =================================================
                // DATA BITS
                // LSB FIRST
                // =================================================

                DATA: begin

                    tx <= tx_data_reg[bit_counter];

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

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
                // PARITY BIT
                // =================================================

                PARITY: begin

                    tx <= parity_bit;

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        state <= STOP;

                    end

                    else begin

                        baud_counter <= baud_counter + 1;

                    end

                end


                // =================================================
                // STOP BIT
                // =================================================

                STOP: begin

                    tx <= 1'b1;

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        tx_done <= 1'b1;
                        tx_busy <= 1'b0;

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


