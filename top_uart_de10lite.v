// ============================================
// top_uart_de10lite.v
// Modulo superior: UART RX + UART TX (devuelve dato + 1)
// Se agrega un generador de "tick" a 9600 baudios
// ============================================

module top_uart_de10lite(
    input  wire CLOCK_50,
    input  wire RESET_N,
    input  wire UART_RX,
    output wire UART_TX,
    output reg  tick          // pulso de 1 ciclo cada bit (9600 baudios)
);

localparam integer CLK_FREQ     = 50000000;
localparam integer BAUD_RATE    = 9600;
localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;   // 5208

wire reset;
assign reset = ~RESET_N;

// ---------- Generador de tick ----------
reg [12:0] tick_count;

always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        tick_count <= 0;
        tick       <= 1'b0;
    end else begin
        if (tick_count == CLKS_PER_BIT - 1) begin
            tick_count <= 0;
            tick       <= 1'b1;
        end else begin
            tick_count <= tick_count + 1;
            tick       <= 1'b0;
        end
    end
end

// ---------- UART ----------
wire [7:0] rx_data;
wire       rx_done;
reg  [7:0] tx_data;
reg        tx_start;
wire       tx_busy;

uart_rx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) RX0 (
    .clk(CLOCK_50),
    .reset(reset),
    .rx(UART_RX),
    .data_out(rx_data),
    .data_valid(rx_done)
);

uart_tx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) TX0 (
    .clk(CLOCK_50),
    .reset(reset),
    .tx_start(tx_start),
    .data_in(tx_data),
    .tx(UART_TX),
    .busy(tx_busy)
);

always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        tx_data  <= 8'd0;
        tx_start <= 1'b0;
    end else begin
        tx_start <= 1'b0;

        if (rx_done && !tx_busy) begin
            tx_data  <= rx_data + 8'd1;   // procesamiento: dato + 1
            tx_start <= 1'b1;
        end
    end
end

endmodule
