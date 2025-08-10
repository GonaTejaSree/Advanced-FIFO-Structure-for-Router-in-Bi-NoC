   `timescale 1ns / 1ps

module router_tb;

    // Parameters
    parameter FLIT_WIDTH = 32;
    parameter FIFO_DEPTH = 8;
    parameter NUM_PORTS  = 4;

    // Clock and reset
    reg clk;
    reg reset;

    // Router I/O
    reg  [FLIT_WIDTH-1:0] data_in     [0:NUM_PORTS-1];
    reg                   wr_en       [0:NUM_PORTS-1];
    wire [FLIT_WIDTH-1:0] data_out    [0:NUM_PORTS-1];
    reg                   rd_en       [0:NUM_PORTS-1];
    wire                  fifo_full   [0:NUM_PORTS-1];
    wire                  fifo_empty  [0:NUM_PORTS-1];

    integer i;

    // DUT Instantiation
    router #(
        .FLIT_WIDTH(FLIT_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .NUM_PORTS(NUM_PORTS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .wr_en(wr_en),
        .data_out(data_out),
        .rd_en(rd_en),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    initial begin
        // Initialize
        clk   = 0;
        reset = 1;
        for (i = 0; i < NUM_PORTS; i = i + 1) begin
            data_in[i] = 0;
            wr_en[i]   = 0;
            rd_en[i]   = 0;
        end

        // Release reset
        #20 reset = 0;

        // Write to FIFO on port 0
        @(posedge clk);
        data_in[0] = 32'hA1A1_A1A1;
        wr_en[0]   = 1;

        @(posedge clk);
        wr_en[0]   = 0;

        // Read from FIFO on port 0
        #20;
        rd_en[0] = 1;

        @(posedge clk);
        rd_en[0] = 0;

        // Write to all ports in parallel
        #20;
        for (i = 0; i < NUM_PORTS; i = i + 1) begin
            data_in[i] = 32'h1000 + i;
            wr_en[i]   = 1;
        end

        @(posedge clk);
        for (i = 0; i < NUM_PORTS; i = i + 1) begin
            wr_en[i] = 0;
        end

        // Read from all ports
        #20;
        for (i = 0; i < NUM_PORTS; i = i + 1) begin
            rd_en[i] = 1;
        end

        @(posedge clk);
        for (i = 0; i < NUM_PORTS; i = i + 1) begin
            rd_en[i] = 0;
        end

        // End simulation
        #50;
        $stop;
    end

endmodule
