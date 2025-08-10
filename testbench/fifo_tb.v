// tb/fifo_tb.v
// Testbench for FIFO module
// Simulates basic write/read operations, overflow, underflow conditions

`timescale 1ns/1ps

module fifo_tb;

    // --- Parameters ---
    parameter DATA_WIDTH = 32;
    parameter DEPTH      = 8;

    // --- Testbench signals ---
    reg                   clk;
    reg                   rst_n;
    reg                   wr_en;
    reg                   rd_en;
    reg  [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;
    wire                  full;
    wire                  empty;

    // --- Instantiate FIFO ---
    fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) uut (
        .clk   (clk),
        .rst_n (rst_n),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .din   (din),
        .dout  (dout),
        .full  (full),
        .empty (empty)
    );

    // --- Clock Generation ---
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // --- Test sequence ---
    initial begin
        // Initialize
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        din   = 0;
        #20;

        // Release reset
        rst_n = 1;
        $display("---- Starting FIFO Test ----");

        // 1. Write some data into FIFO
        repeat (4) begin
            @(posedge clk);
            if (!full) begin
                wr_en <= 1;
                din   <= $random;
                $display("Time %0t: Writing data: %h", $time, din);
            end
        end
        @(posedge clk) wr_en <= 0;

        // 2. Read two entries
        repeat (2) begin
            @(posedge clk);
            if (!empty) begin
                rd_en <= 1;
            end
        end
        @(posedge clk) rd_en <= 0;

        // 3. Fill FIFO completely to test 'full'
        while (!full) begin
            @(posedge clk);
            wr_en <= 1;
            din   <= $random;
            $display("Time %0t: Writing data: %h", $time, din);
        end
        @(posedge clk) wr_en <= 0;

        // 4. Read all entries to test 'empty'
        while (!empty) begin
            @(posedge clk);
            rd_en <= 1;
            $display("Time %0t: Reading data: %h", $time, dout);
        end
        @(posedge clk) rd_en <= 0;

        // 5. Underflow test — reading when empty
        @(posedge clk);
        rd_en <= 1;
        @(posedge clk);
        rd_en <= 0;

        // End simulation
        #20;
        $display("---- FIFO Test Completed ----");
        $finish;
    end

endmodule
