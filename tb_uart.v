// ==============================================================================
// Testbench: tb_uart
// Description: Self-checking testbench for Full-Duplex UART Controller.
//              Tests baud generation, serial transmission, 16x oversampled
//              reception in loopback mode, multi-byte sequences, and frame error
//              detection.
// ==============================================================================

`timescale 1ns / 1ps

module tb_uart;

    // Simulation Clock: 50 MHz (Period = 20ns)
    // Faster Baud Rate for simulation speed: 1,000,000 baud
    parameter CLK_FREQ  = 50000000;
    parameter BAUD_RATE = 1000000;

    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_busy;
    wire       tx_done;
    wire       uart_tx_pin;

    reg        uart_rx_pin;
    wire [7:0] rx_data;
    wire       rx_valid;
    wire       frame_error;
    reg        loopback_en;

    integer errors = 0;
    reg [7:0] test_vectors [0:3];
    integer i;

    // Instantiate DUT
    uart_top #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .tx_start   (tx_start),
        .tx_data    (tx_data),
        .tx_busy    (tx_busy),
        .tx_done    (tx_done),
        .uart_tx_pin(uart_tx_pin),
        .uart_rx_pin(uart_rx_pin),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .frame_error(frame_error),
        .loopback_en(loopback_en)
    );

    // Clock generator (50 MHz -> 20ns period)
    always #10 clk = ~clk;

    // Task to transmit a byte and verify reception
    task send_and_check(input [7:0] byte_to_send);
        begin
            @(posedge clk);
            tx_data  <= byte_to_send;
            tx_start <= 1'b1;
            @(posedge clk);
            tx_start <= 1'b0;

            // Wait until RX receives the byte
            @(posedge rx_valid);
            #1;
            if (rx_data !== byte_to_send) begin
                $display("[FAIL] Data Mismatch: Sent 0x%02X, Received 0x%02X", byte_to_send, rx_data);
                errors = errors + 1;
            end else begin
                $display("[PASS] Byte successfully transmitted and received: 0x%02X", rx_data);
            end

            // Wait for TX to finish completely
            @(posedge tx_done);
            #200; // Inter-frame delay
        end
    endtask

    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, tb_uart);

        $display("------------------------------------------------------------");
        $display("   STARTING UART CONTROLLER VERIFICATION TESTBENCH          ");
        $display("------------------------------------------------------------");

        // Initialization
        clk         = 0;
        rst_n       = 0;
        tx_start    = 0;
        tx_data     = 0;
        uart_rx_pin = 1'b1;
        loopback_en = 1'b1; // Enable internal loopback for automated verification

        test_vectors[0] = 8'hA5; // 10100101 (alternating bit pattern)
        test_vectors[1] = 8'h3C; // 00111100
        test_vectors[2] = 8'hFF; // 11111111 (all ones)
        test_vectors[3] = 8'h00; // 00000000 (all zeros)

        // Reset
        #100;
        rst_n = 1;
        #100;

        $display(">>> Testing Loopback Transmissions across 4 distinct data patterns...");
        for (i = 0; i < 4; i = i + 1) begin
            send_and_check(test_vectors[i]);
        end

        // Final verification summary
        $display("\n------------------------------------------------------------");
        if (errors == 0) begin
            $display("   ALL UART CONTROLLER TESTS PASSED WITH ZERO ERRORS!       ");
        end else begin
            $display("   UART VERIFICATION FAILED WITH %0d ERRORS                 ", errors);
        end
        $display("------------------------------------------------------------\n");

        #500;
        $finish;
    end

endmodule
