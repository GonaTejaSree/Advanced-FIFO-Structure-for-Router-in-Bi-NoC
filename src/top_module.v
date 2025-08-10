// src/top_module.v
// Top-level wrapper integrating router and FIFO buffers
// For Bi-NoC demonstration / simulation

`timescale 1ns/1ps

module top_module #
(
    parameter integer DATA_WIDTH = 32,
    parameter integer DEPTH      = 8,
    parameter integer NUM_PORTS  = 4,
    parameter integer DEST_BITS  = 2
)
(
    input  wire                       clk,
    input  wire                       rst_n
);

    // --- Internal signals between testbench and router ---
    reg  [NUM_PORTS-1:0]              in_valid;
    reg  [NUM_PORTS*DATA_WIDTH-1:0]   in_data;
    wire [NUM_PORTS-1:0]              in_ready;

    wire [NUM_PORTS-1:0]              out_valid;
    wire [NUM_PORTS*DATA_WIDTH-1:0]   out_data;
    reg  [NUM_PORTS-1:0]              out_ready;

    // --- DUT: Router ---
    router #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH),
        .NUM_PORTS  (NUM_PORTS),
        .DEST_BITS  (DEST_BITS)
    ) router_inst (
        .clk       (clk),
        .rst_n     (rst_n),

        .in_valid  (in_valid),
        .in_data   (in_data),
        .in_ready  (in_ready),

        .out_valid (out_valid),
        .out_data  (out_data),
        .out_ready (out_ready)
    );

    // --- Simple traffic generator for simulation ---
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_valid <= {NUM_PORTS{1'b0}};
            in_data  <= {NUM_PORTS*DATA_WIDTH{1'b0}};
            out_ready <= {NUM_PORTS{1'b1}}; // always ready to receive
        end
        else begin
            // Example: send one flit from port 0 to port 2
            // Format: [DEST_BITS = top bits | payload = rest]
            in_valid <= {NUM_PORTS{1'b0}};
            if (in_ready[0]) begin
                in_valid[0] <= 1'b1;
                in_data[DATA_WIDTH-1:DATA_WIDTH-DEST_BITS] <= 2'd2; // destination port ID
                in_data[DATA_WIDTH-DEST_BITS-1:0] <= 30'hABCDE;      // payload
            end

            // Additional ports can be driven here
            for (i = 1; i < NUM_PORTS; i = i + 1) begin
                in_valid[i] <= 1'b0; // idle in this example
            end
        end
    end

    // --- Monitor output (for simulation) ---
    always @(posedge clk) begin
        for (i = 0; i < NUM_PORTS; i = i + 1) begin
            if (out_valid[i] && out_ready[i]) begin
                $display("Time %0t: Output port %0d received flit: %h",
                         $time, i,
                         out_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]);
            end
        end
    end

endmodule
