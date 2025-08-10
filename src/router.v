// src/router.v
// Parameterized synchronous router for Bi-NoC using input FIFOs.
//
// Assumptions:
// - Single clock domain
// - Wormhole routing style
// - Destination port encoded in header flit bits
//
// Parameters:
//   DATA_WIDTH : width of each flit
//   DEPTH      : FIFO depth
//   NUM_PORTS  : number of input/output ports
//   DEST_BITS  : number of bits used to represent destination port
`timescale 1ns/1ps

module router #
(
    parameter integer DATA_WIDTH = 32,
    parameter integer DEPTH      = 8,
    parameter integer NUM_PORTS  = 4,
    parameter integer DEST_BITS  = 2  // log2(NUM_PORTS)
)
(
    input  wire                       clk,
    input  wire                       rst_n,

    // Input ports
    input  wire [NUM_PORTS-1:0]                        in_valid,
    input  wire [NUM_PORTS*DATA_WIDTH-1:0]            in_data,
    output wire [NUM_PORTS-1:0]                        in_ready,

    // Output ports
    output reg  [NUM_PORTS-1:0]                        out_valid,
    output reg  [NUM_PORTS*DATA_WIDTH-1:0]            out_data,
    input  wire [NUM_PORTS-1:0]                        out_ready
);

    // --- Input FIFOs ---
    wire [NUM_PORTS-1:0] fifo_full, fifo_empty;
    wire [NUM_PORTS*DATA_WIDTH-1:0] fifo_out;

    genvar i;
    generate
        for (i = 0; i < NUM_PORTS; i = i + 1) begin : input_fifos
            fifo #(
                .DATA_WIDTH(DATA_WIDTH),
                .DEPTH(DEPTH)
            ) fifo_inst (
                .clk      (clk),
                .rst_n    (rst_n),
                .wr_en    (in_valid[i] && !fifo_full[i]),
                .data_in  (in_data[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]),
                .full     (fifo_full[i]),
                .rd_en    (fifo_rd_en[i]),
                .data_out (fifo_out[(i+1)*DATA_WIDTH-1 : i*DATA_WIDTH]),
                .empty    (fifo_empty[i])
            );
        end
    endgenerate

    // Ready is just "not full"
    assign in_ready = ~fifo_full;

    // --- Routing Logic ---
    // Simple header-based: top DEST_BITS bits of flit define output port
    wire [DEST_BITS-1:0] dest_port[NUM_PORTS-1:0];
    generate
        for (i = 0; i < NUM_PORTS; i = i + 1) begin : dest_extract
            assign dest_port[i] = fifo_out[(i+1)*DATA_WIDTH-1 -: DEST_BITS];
        end
    endgenerate

    // --- Arbitration ---
    // Each output port gets one winner from requesting input ports
    reg [NUM_PORTS-1:0] fifo_rd_en;
    integer out_idx, in_idx;

    always @(*) begin
        // Defaults
        fifo_rd_en = {NUM_PORTS{1'b0}};
        out_valid  = {NUM_PORTS{1'b0}};
        out_data   = {NUM_PORTS*DATA_WIDTH{1'b0}};

        for (out_idx = 0; out_idx < NUM_PORTS; out_idx = out_idx + 1) begin
            // Find first requesting input (simple priority)
            for (in_idx = 0; in_idx < NUM_PORTS; in_idx = in_idx + 1) begin
                if (!fifo_empty[in_idx] &&
                    dest_port[in_idx] == out_idx[DEST_BITS-1:0] &&
                    out_ready[out_idx]) begin
                    fifo_rd_en[in_idx] = 1'b1;
                    out_valid[out_idx] = 1'b1;
                    out_data[(out_idx+1)*DATA_WIDTH-1 : out_idx*DATA_WIDTH] =
                        fifo_out[(in_idx+1)*DATA_WIDTH-1 : in_idx*DATA_WIDTH];
                    disable inner_loop; // stop after first match
                end
            end
            inner_loop: ;
        end
    end

endmodule
