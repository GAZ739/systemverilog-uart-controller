
module tb_uart;

    // =========================================================
    // CLOCK / RESET
    // =========================================================

    logic clk;
    logic rst;


    // =========================================================
    // UART TX SIGNALS
    // =========================================================

    logic [7:0] tx_data;
    logic       tx_start;

    logic       tx;
    logic       tx_busy;
    logic       tx_done;


    // =========================================================
    // UART RX SIGNALS
    // =========================================================

    logic [7:0] rx_data;
    logic       rx_valid;

    logic       framing_error;
    logic       parity_error;


    // =========================================================
    // RX TEST SIGNALS
    // =========================================================

    logic rx_serial;

    logic manual_rx;
    logic use_manual_rx;


    // =========================================================
    // UART TRANSMITTER
    // =========================================================

    uart_tx #(
        .CLK_FREQ(10_000_000),
        .BAUD_RATE(1_000_000)
    ) transmitter (

        .clk(clk),
        .rst(rst),

        .tx_data(tx_data),
        .tx_start(tx_start),

        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)

    );


    // =========================================================
    // RX INPUT MULTIPLEXER
    //
    // Normal test:
    //     TX -> RX
    //
    // Error test:
    //     Manual signal -> RX
    // =========================================================

    always_comb begin

        if (use_manual_rx)
            rx_serial = manual_rx;

        else
            rx_serial = tx;

    end


    // =========================================================
    // UART RECEIVER
    // =========================================================

    uart_rx #(
        .CLK_FREQ(10_000_000),
        .BAUD_RATE(1_000_000)
    ) receiver (

        .clk(clk),
        .rst(rst),

        .rx(rx_serial),

        .rx_data(rx_data),
        .rx_valid(rx_valid),

        .framing_error(framing_error),
        .parity_error(parity_error)

    );


    // =========================================================
    // CLOCK
    // =========================================================

    initial begin

        clk = 1'b0;

        // 10 MHz clock
        // Period = 100 ns

        forever #50 clk = ~clk;

    end


    // =========================================================
    // NORMAL UART TEST
    // =========================================================

    task send_and_check(input logic [7:0] data);

        begin

            $display("----------------------------------");
            $display("Sending 0x%h", data);


            // Put data into TX
            tx_data = data;


            // Start TX
            tx_start = 1'b1;

            #100;

            tx_start = 1'b0;


            // Wait until RX receives valid byte
            wait(rx_valid);


            // Check received data
            if ((rx_data == data) &&
                (framing_error == 1'b0) &&
                (parity_error == 1'b0)) begin

                $display(
                    "PASS : TX = 0x%h, RX = 0x%h",
                    data,
                    rx_data
                );

            end

            else begin

                $display(
                    "FAIL : TX = 0x%h, RX = 0x%h",
                    data,
                    rx_data
                );

                $display(
                    "Framing Error = %b, Parity Error = %b",
                    framing_error,
                    parity_error
                );

            end


            // Small gap between frames
            #200;

        end

    endtask


    // =========================================================
    // FRAMING ERROR TEST
    //
    // Frame:
    //
    // START
    // DATA x 8
    // CORRECT PARITY
    // BAD STOP = 0
    // =========================================================
  
  task send_back_to_back(
    input logic [7:0] data1,
    input logic [7:0] data2,
    input logic [7:0] data3
);

    begin

        $display("");
        $display("======================================");
        $display("BACK-TO-BACK UART TEST");
        $display("======================================");

        // -------------------------------
        // BYTE 1
        // -------------------------------
        tx_data  = data1;
        tx_start = 1'b1;
        #100;
        tx_start = 1'b0;

        wait(rx_valid);

        if ((rx_data == data1) &&
            (framing_error == 1'b0) &&
            (parity_error == 1'b0))
            $display("PASS : Byte 1 TX=0x%h RX=0x%h",
                     data1, rx_data);
        else
            $display("FAIL : Byte 1 TX=0x%h RX=0x%h",
                     data1, rx_data);

        #200;


        // -------------------------------
        // BYTE 2
        // -------------------------------
        tx_data  = data2;
        tx_start = 1'b1;
        #100;
        tx_start = 1'b0;

        wait(rx_valid);

        if ((rx_data == data2) &&
            (framing_error == 1'b0) &&
            (parity_error == 1'b0))
            $display("PASS : Byte 2 TX=0x%h RX=0x%h",
                     data2, rx_data);
        else
            $display("FAIL : Byte 2 TX=0x%h RX=0x%h",
                     data2, rx_data);

        #200;


        // -------------------------------
        // BYTE 3
        // -------------------------------
        tx_data  = data3;
        tx_start = 1'b1;
        #100;
        tx_start = 1'b0;

        wait(rx_valid);

        if ((rx_data == data3) &&
            (framing_error == 1'b0) &&
            (parity_error == 1'b0))
            $display("PASS : Byte 3 TX=0x%h RX=0x%h",
                     data3, rx_data);
        else
            $display("FAIL : Byte 3 TX=0x%h RX=0x%h",
                     data3, rx_data);

        #200;

    end

endtask

    task send_bad_stop(input logic [7:0] data);

        integer i;
        integer error_detected;

        begin

            $display("");
            $display("----------------------------------");
            $display("FRAMING ERROR TEST");
            $display("Sending 0x%h with BAD STOP BIT", data);


            error_detected = 0;


            // Switch to manual RX
            use_manual_rx = 1'b1;

            // UART idle = HIGH
            manual_rx = 1'b1;

            #500;


            // =================================================
            // START
            // =================================================

            manual_rx = 1'b0;

            #1000;


            // =================================================
            // DATA
            // LSB FIRST
            // =================================================

            for (i = 0; i < 8; i = i + 1) begin

                manual_rx = data[i];

                #1000;

            end


            // =================================================
            // CORRECT EVEN PARITY
            // =================================================

            manual_rx = ^data;

            #1000;


            // =================================================
            // BAD STOP
            // =================================================

            manual_rx = 1'b0;


            // =================================================
            // MONITOR FRAMING ERROR
            // =================================================

            fork

                begin

                    @(posedge framing_error);

                    error_detected = 1;

                    $display(
                        "Framing error pulse detected!"
                    );

                end


                begin

                    #1500;

                end

            join_any

            disable fork;


            // Return to idle
            manual_rx = 1'b1;

            #500;


            // =================================================
            // RESULT
            // =================================================

            if (error_detected == 1) begin

                $display(
                    "PASS : Framing error detected!"
                );

            end

            else begin

                $display(
                    "FAIL : Framing error NOT detected!"
                );

            end


            // Return to normal TX -> RX
            use_manual_rx = 1'b0;

        end

    endtask


    // =========================================================
    // PARITY ERROR TEST
    //
    // Frame:
    //
    // START
    // DATA x 8
    // WRONG PARITY
    // CORRECT STOP
    // =========================================================

    task send_bad_parity(input logic [7:0] data);

        integer i;
        integer error_detected;

        begin

            $display("");
            $display("----------------------------------");
            $display("PARITY ERROR TEST");
            $display("Sending 0x%h with BAD PARITY", data);


            error_detected = 0;


            // Switch to manual RX
            use_manual_rx = 1'b1;

            manual_rx = 1'b1;

            #500;


            // =================================================
            // START
            // =================================================

            manual_rx = 1'b0;

            #1000;


            // =================================================
            // DATA
            // LSB FIRST
            // =================================================

            for (i = 0; i < 8; i = i + 1) begin

                manual_rx = data[i];

                #1000;

            end


            // =================================================
            // WRONG PARITY
            //
            // Correct even parity = ^data
            // Therefore wrong parity = ~(^data)
            // =================================================

            manual_rx = ~(^data);

            // Monitor parity error while parity bit is active
            fork

                begin

                    @(posedge parity_error);

                    error_detected = 1;

                    $display(
                        "Parity error pulse detected!"
                    );

                end


                begin

                    #1500;

                end

            join_any

            disable fork;


            // =================================================
            // CORRECT STOP
            // =================================================

            manual_rx = 1'b1;

            #1000;


            // =================================================
            // RETURN TO IDLE
            // =================================================

            manual_rx = 1'b1;

            #500;


            // =================================================
            // RESULT
            // =================================================

            if (error_detected == 1) begin

                $display(
                    "PASS : Parity error detected!"
                );

            end

            else begin

                $display(
                    "FAIL : Parity error NOT detected!"
                );

            end


            // Return to normal TX -> RX
            use_manual_rx = 1'b0;

        end

    endtask


    // =========================================================
    // MAIN TEST
    // =========================================================

    initial begin

        // =====================================================
        // VCD
        // =====================================================

        $dumpfile("dump.vcd");
        $dumpvars(0, tb_uart);


        // =====================================================
        // INITIAL VALUES
        // =====================================================

        rst           = 1'b1;

        tx_data       = 8'h00;
        tx_start      = 1'b0;

        manual_rx     = 1'b1;
        use_manual_rx = 1'b0;


        // =====================================================
        // RESET
        // =====================================================

        #200;

        rst = 1'b0;

        #200;


        // =====================================================
        // NORMAL DATA TESTS
        // =====================================================

        send_and_check(8'hA5);

        send_and_check(8'h55);

        send_and_check(8'h00);

        send_and_check(8'hFF);

        send_and_check(8'h3C);


        // =====================================================
        // FRAMING ERROR
        // =====================================================

        send_bad_stop(8'hA5);


        // =====================================================
        // PARITY ERROR
        // =====================================================

        send_bad_parity(8'hA5);
      send_back_to_back(
    8'hA5,
    8'h55,
    8'h3C
);


        // =====================================================
        // COMPLETE
        // =====================================================

        $display("");
        $display("======================================");
        $display("ALL UART TESTS COMPLETED");
        $display("======================================");


        #200;

        $finish;

    end

endmodule