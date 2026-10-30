// ============================================
// tb_top_uart.v
// Testbench: simula a MATLAB/ESP32 enviando bytes a la FPGA
// y revisa que la respuesta sea dato + 1
// ============================================

`timescale 1ns/1ps

module tb_top_uart;

localparam integer CLKS_PER_BIT = 5208;   // 50 MHz / 9600

// Senales
reg  CLOCK_50 = 1'b0;
reg  RESET_N  = 1'b0;
reg  UART_RX  = 1'b1;     // la linea UART en reposo vale 1
wire UART_TX;
wire tick;

reg [7:0] respuesta;
reg [7:0] esperado;

// Dispositivo bajo prueba
top_uart_de10lite dut (
    .CLOCK_50(CLOCK_50),
    .RESET_N(RESET_N),
    .UART_RX(UART_RX),
    .UART_TX(UART_TX),
    .tick(tick)
);

// Reloj de 50 MHz (periodo 20 ns)
always #10 CLOCK_50 = ~CLOCK_50;

// Envia un byte a la FPGA: un bit por cada tick (8N1)
task enviar_byte(input [7:0] dato);
    integer i;
    begin
        @(posedge tick);
        UART_RX = 1'b0;                 // bit de inicio
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge tick);
            UART_RX = dato[i];          // bits de datos (LSB primero)
        end
        @(posedge tick);
        UART_RX = 1'b1;                 // bit de paro
        @(posedge tick);
    end
endtask

// Recibe un byte desde UART_TX de la FPGA
task recibir_byte(output [7:0] dato);
    integer i;
    begin
        @(negedge UART_TX);                                 // bit de inicio
        repeat (CLKS_PER_BIT + CLKS_PER_BIT/2) @(posedge CLOCK_50); // mitad del bit 0
        for (i = 0; i < 8; i = i + 1) begin
            dato[i] = UART_TX;
            repeat (CLKS_PER_BIT) @(posedge CLOCK_50);
        end
    end
endtask

// Una prueba: envia, recibe y compara
task probar(input [7:0] dato);
    begin
        esperado = dato + 8'd1;
        fork
            enviar_byte(dato);
            recibir_byte(respuesta);
        join
        if (respuesta == esperado)
            $display("OK    -> Enviado: %0d  Recibido: %0d  Esperado: %0d", dato, respuesta, esperado);
        else
            $display("ERROR -> Enviado: %0d  Recibido: %0d  Esperado: %0d", dato, respuesta, esperado);
        #200000;   // pausa entre pruebas
    end
endtask

// Secuencia de pruebas (tabla de la practica)
initial begin
    RESET_N = 1'b0;
    #200;
    RESET_N = 1'b1;
    #1000;

    probar(8'd10);
    probar(8'd25);
    probar(8'd100);
    probar(8'd200);
    probar(8'd255);     // caso limite: 255 + 1 = 0

    $display("Fin de la simulacion");
    $stop;
end

endmodule
