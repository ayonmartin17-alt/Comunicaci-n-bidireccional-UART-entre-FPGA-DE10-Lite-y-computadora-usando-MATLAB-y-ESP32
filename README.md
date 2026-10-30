# Práctica 4 – Comunicación UART bidireccional en FPGA (Verilog)

Práctica 4 de **Sistemas Embebidos** (UDLAP). Diseño en Verilog de un sistema de comunicación serial UART (9600 baudios, 8N1) pensado para la FPGA **Terasic DE10-Lite**, con un **ESP32** como puente USB–UART hacia la computadora y scripts de **MATLAB** para enviar y recibir datos.

> **Estado del proyecto:** el diseño se verificó por **simulación con testbench en Active-HDL**. La prueba en hardware (DE10-Lite + ESP32 + MATLAB) no logró completarse, por lo que los resultados que se presentan son de simulación. Ver la sección [Estado y limitaciones](#estado-y-limitaciones).

---

## Objetivo

Implementar en una FPGA un enlace UART bidireccional: la FPGA recibe un byte, lo procesa (le suma 1) y lo transmite de regreso.

```
PC (MATLAB) <-- USB --> ESP32 <-- UART 3.3 V --> FPGA DE10-Lite
```

## Especificaciones

| Parámetro | Valor |
|---|---|
| Velocidad | 9600 baudios |
| Formato | 8N1 (8 bits de datos, sin paridad, 1 bit de paro) |
| Reloj de la FPGA | 50 MHz |
| Ciclos de reloj por bit | 50 000 000 / 9600 ≈ 5208 |
| Procesamiento | `dato_respuesta = dato_recibido + 1` |
| Niveles lógicos | 3.3 V (FPGA y ESP32, conexión directa con GND común) |

## Estructura del repositorio

> Ajusta los nombres a los de tus archivos.

```
.
├── rtl/
│   ├── top_uart_de10lite.v     # Módulo superior: conecta RX, TX y la lógica de control
│   ├── uart_rx.v               # Receptor UART
│   └── uart_tx.v               # Transmisor UART
├── sim/
│   └── tb_*.v                  # Testbench(es) usados en Active-HDL
├── esp32/
│   └── puente_uart.ino         # Puente USB–UART (Arduino IDE)
├── matlab/
│   ├── transmision.m           # Envío de bytes
│   ├── recepcion.m             # Recepción de bytes
│   └── bidireccional.m         # Envío + lectura de respuesta
├── docs/
│   └── practica4.pdf           # Instrucciones de la práctica
└── README.md
```

## Descripción de los módulos

### `uart_tx`
Transmisor serial. Al recibir `tx_start` carga un registro de 10 bits (`stop + dato + start`) y lo desplaza bit por bit, manteniendo cada uno `CLKS_PER_BIT` ciclos de reloj. La salida `busy` indica que hay una transmisión en curso.

### `uart_rx`
Receptor serial. Detecta el bit de inicio (flanco de bajada de `rx`), espera medio bit para ubicarse a la mitad del bit y muestrea cada bit cada `CLKS_PER_BIT` ciclos. Al terminar entrega el byte en `data_out` y pulsa `data_valid` un ciclo.

### `top_uart_de10lite`
Integra ambos módulos. Cuando `rx_done` es 1 y el transmisor no está ocupado, carga `rx_data + 1` en `tx_data` y dispara `tx_start`. El reset de la tarjeta es activo en bajo (`RESET_N`), por lo que se invierte internamente.

Puertos: `CLOCK_50`, `RESET_N`, `UART_RX` (entrada), `UART_TX` (salida).

## Simulación en Active-HDL

1. Crear un workspace/diseño nuevo en Active-HDL.
2. Agregar los archivos de `rtl/` y el testbench de `sim/`.
3. Compilar todos los archivos (*Design → Compile All*).
4. Inicializar la simulación con el testbench como módulo superior.
5. Agregar las señales al *waveform* (`clk`, `rx`/`tx`, `rx_done`, `rx_data`, `tx_start`, `tx_data`, `busy`) y ejecutar.

> Con un reloj de 50 MHz y 9600 baudios, cada byte dura ≈ 1.04 ms (10 bits × 104.2 µs). Ajusta el tiempo de simulación (por ejemplo `run 5 ms`) para ver varios bytes completos.

### Casos de prueba

| Dato enviado | Respuesta esperada | Descripción |
|---|---|---|
| 10 | 11 | Incremento en 1 |
| 25 | 26 | Incremento en 1 |
| 100 | 101 | Incremento en 1 |
| 200 | 201 | Incremento en 1 |
| 255 | 0 | Desbordamiento de 8 bits |

### Resultados de simulación

> Agrega aquí tus capturas del *waveform*.

```
docs/img/sim_rx.png   -> recepción del byte
docs/img/sim_tx.png   -> transmisión de la respuesta
docs/img/sim_full.png -> ciclo completo (RX -> +1 -> TX)
```

## Implementación en hardware (planeada)

### Conexión física

| ESP32 | DE10-Lite |
|---|---|
| GPIO17 (TX2) | `UART_RX` (pin GPIO asignado en Quartus) |
| GPIO16 (RX2) | `UART_TX` (pin GPIO asignado en Quartus) |
| GND | GND |

La conexión TX↔RX es cruzada y es indispensable compartir tierra.

### Pasos

1. **Quartus Prime:** compilar el proyecto, asignar pines de `CLOCK_50`, `RESET_N`, `UART_RX` y `UART_TX`, y programar la FPGA con el USB Blaster.
2. **Arduino IDE:** cargar `esp32/puente_uart.ino` al ESP32 (puente transparente a 9600 baudios entre `Serial` y `Serial2`).
3. **MATLAB:** editar el puerto COM en los scripts (`PORT = "COMx"`) y ejecutar `bidireccional.m`.

## Estado y limitaciones

- El diseño fue **verificado únicamente en simulación** (Active-HDL con testbench).
- En hardware, el puente ESP32 sí funcionó en modo *loopback* (RX2 conectado a TX2) desde MATLAB, pero **no se obtuvo respuesta de la FPGA**, por lo que la validación física quedó pendiente.
- Posibles causas a revisar: asignación de pines en Quartus, conexión física/GND común, polaridad del reset, y prueba con un valor fijo transmitido desde Verilog para aislar el TX.

## Herramientas

- Active-HDL (simulación)
- Quartus Prime (síntesis y programación)
- Arduino IDE (ESP32)
- MATLAB (`serialport`)
- FPGA DE10-Lite y ESP32

## Autores

- Nombre: Martín Ayón Castañed
- Matricula: 184298
- Nombre: Sarahi Juárez García
- Matricula: 186581
- Materia: Sistemas Embebidos – UDLAP
- Profesor: Gerardo Ulises Diaz Arango

## Referencias

- M. Morris Mano, *Digital Design*
- Stephen Brown, *Fundamentals of Digital Logic with Verilog Design*
- Documentación de Quartus Prime, MATLAB Serial Communication, Arduino IDE y ESP32 UART
