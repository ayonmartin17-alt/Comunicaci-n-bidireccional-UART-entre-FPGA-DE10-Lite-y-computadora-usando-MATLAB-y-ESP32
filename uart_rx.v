// ============================================
// uart_rx.v
// Modulo receptor UART (del profesor, sin cambios)
// ============================================

module uart_rx #(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600
)(
    input  wire clk,
    input  wire reset,
    input  wire rx,
    output reg [7:0] data_out,
    output reg data_valid
);

localparam integer CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE;
localparam integer HALF_BIT      = CLKS_PER_BIT / 2;

reg [15:0] clk_count;
reg [3:0]  bit_index;
reg [7:0]  rx_shift;
reg        receiving;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        clk_count  <= 0;
        bit_index  <= 0;
        rx_shift   <= 0;
        receiving  <= 1'b0;
        data_out   <= 8'd0;
        data_valid <= 1'b0;
    end else begin
        data_valid <= 1'b0;

        if (!receiving) begin
            if (rx == 1'b0) begin
                receiving <= 1'b1;
                clk_count <= HALF_BIT;
                bit_index <= 0;
            end
        end else begin
            if (clk_count < CLKS_PER_BIT - 1) begin
                clk_count <= clk_count + 1;
            end else begin
                clk_count <= 0;

                if (bit_index < 8) begin
                    rx_shift[bit_index] <= rx;
                    bit_index <= bit_index + 1;
                end else begin
                    receiving  <= 1'b0;
                    data_out   <= rx_shift;
                    data_valid <= 1'b1;
                end
            end
        end
    end
end

endmodule
