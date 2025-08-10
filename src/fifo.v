// src/fifo.v
// Synchronous parameterizable FIFO with bypass (single-clock).
// - DATA_WIDTH : width of each flit
// - DEPTH      : number of entries (must be power of two)
// - ADDR_WIDTH : derived from DEPTH ($clog2)
`timescale 1ns/1ps

module fifo #
(
    parameter integer DATA_WIDTH = 32,
    parameter integer DEPTH = 8,
    parameter integer ADDR_WIDTH = $clog2(DEPTH)
)
(
    input  wire                  clk,
    input  wire                  rst_n,     // active low reset
    // Write interface
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire                  full,
    // Read interface
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] data_out,
    output wire                  empty
);

    // NOTE: DEPTH must be power-of-two for this pointer arithmetic to work correctly.
    // You may add a runtime check / synthesis-time assertion in your environment.

    // Pointer width includes an extra MSB for full/empty detection (wrap bit)
    localparam PTR_WIDTH = ADDR_WIDTH + 1;

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Binary pointers (with extra MSB for wrap detection)
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;

    // Extract address bits
    wire [ADDR_WIDTH-1:0] wr_addr = wr_ptr[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] rd_addr = rd_ptr[ADDR_WIDTH-1:0];

    // Empty: pointers equal
    assign empty = (wr_ptr == rd_ptr);

    // Full: MSB (wrap) differs and lower bits equal
    assign full  = ( (wr_ptr[PTR_WIDTH-1] != rd_ptr[PTR_WIDTH-1]) &&
                      (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]) );

    // Internal signals for write/read enable decisions
    wire write_cond; // when to actually write into memory
    wire read_cond;  // when to actually read from memory (i.e., consume stored element)
    wire bypass_cond;

    // Bypass condition: FIFO empty AND both wr_en and rd_en asserted.
    // In that case we forward data_in to data_out directly and do not touch memory.
    assign bypass_cond = (empty && wr_en && rd_en);

    // Actual write happens if wr_en and not full and not bypass (bypass avoids memory write)
    assign write_cond = (wr_en && !full && !bypass_cond);

    // Actual read (consumption of stored element) happens if rd_en and not empty and not bypass
    assign read_cond  = (rd_en  && !empty && !bypass_cond);

    // Synchronous logic: pointers, memory write, memory read register
    // data_out is updated on read or bypass
    reg [DATA_WIDTH-1:0] mem_read_data;

    integer i;
    // Optional: initialize mem to zero on reset for simulation clarity
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= {PTR_WIDTH{1'b0}};
            rd_ptr <= {PTR_WIDTH{1'b0}};
            data_out <= {DATA_WIDTH{1'b0}};
            mem_read_data <= {DATA_WIDTH{1'b0}};
            // synthesis translate_off
            for (i = 0; i < DEPTH; i = i + 1) mem[i] <= {DATA_WIDTH{1'b0}};
            // synthesis translate_on
        end else begin
            // Memory write (synchronous)
            if (write_cond) begin
                mem[wr_addr] <= data_in;
            end

            // Memory read (synchronous read; data available next cycle)
            if (read_cond) begin
                mem_read_data <= mem[rd_addr];
            end

            // Pointer updates (wr_ptr and rd_ptr are updated synchronously)
            if (write_cond) begin
                wr_ptr <= wr_ptr + 1'b1;
            end

            if (read_cond) begin
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Bypass case: new data_out is the data_in directly in same cycle when requested
            // If bypass, present data_in on data_out immediately.
            // Else if we did a memory read, present the registered mem_read_data
            if (bypass_cond) begin
                data_out <= data_in;
            end else if (read_cond) begin
                // Note: because mem is synchronous, mem_read_data was captured this cycle.
                // We output the captured value.
                data_out <= mem_read_data;
            end
            // else retain previous data_out
        end
    end

endmodule
