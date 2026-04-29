// ======================================================
// SPI MASTER MODULE
// ======================================================
module spi_master (
    input  wire       REFCLK,
    input  wire [1:0] CNTL,
    input  wire [7:0] INPUT,
    input  wire       MISO,
    output reg  [7:0] OUTPUT,
    output reg        READY,
    output reg        MOSI,
    output reg        SCLK,
    output reg  [7:0] SS
);
    localparam IDLE       = 3'd0;
    localparam TX_HIGH    = 3'd1;
    localparam TX_LOW     = 3'd2;
    localparam WAIT_CLEAR = 3'd3;

    reg [2:0] state;
    reg [7:0] tx_reg;
    reg [7:0] rx_reg;
    reg [2:0] bit_cnt;

    initial begin
        state  = IDLE; READY = 1'b1; SCLK = 1'b0;
        MOSI   = 1'b0; SS = 8'hFF; OUTPUT = 8'd0;
    end

    always @(posedge REFCLK) begin
        case (state)
            IDLE: begin
                SCLK <= 1'b0; READY <= 1'b1; bit_cnt <= 3'd0;
                case (CNTL)
                    2'b01: tx_reg <= INPUT;
                    2'b10: SS <= (INPUT <= 7) ? ~(8'b1 << INPUT[2:0]) : 8'hFF;
                    2'b11: begin
                        READY <= 1'b0;
                        MOSI  <= tx_reg[7];
                        state <= TX_HIGH;
                    end
                endcase
            end
            TX_HIGH: begin
                SCLK   <= 1'b1;
                rx_reg <= {rx_reg[6:0], MISO};
                state  <= TX_LOW;
            end
            TX_LOW: begin
                SCLK <= 1'b0;
                if (bit_cnt == 3'd7) begin
                    OUTPUT <= rx_reg;
                    state  <= WAIT_CLEAR;
                end else begin
                    tx_reg  <= {tx_reg[6:0], 1'b0};
                    MOSI    <= tx_reg[6];
                    bit_cnt <= bit_cnt + 1'b1;
                    state   <= TX_HIGH;
                end
            end
            WAIT_CLEAR: if (CNTL != 2'b11) begin READY <= 1'b1; state <= IDLE; end
        endcase
    end
endmodule

// ======================================================
// SPI SLAVE MODULE
// ======================================================
module spi_slave (
    input  wire [7:0] INPUT,
    input  wire       LOAD,
    output reg  [7:0] OUTPUT,
    output wire       READY,
    input  wire       SCLK,
    input  wire       MOSI,
    output reg        MISO,
    input  wire       CS
);
    reg [7:0] tx_shift, rx_shift;
    reg [2:0] b_cnt;
    assign READY = CS;

    initial begin MISO = 1'bz; b_cnt = 0; end

    always @(posedge LOAD) if (READY) tx_shift <= INPUT;

    always @(negedge SCLK or negedge CS) begin
        if (CS) MISO <= 1'bz;
        else begin
            MISO <= tx_shift[7];
            tx_shift <= {tx_shift[6:0], 1'b0};
        end
    end

    always @(posedge SCLK) begin
        if (!CS) begin
            rx_shift <= {rx_shift[6:0], MOSI};
            b_cnt <= b_cnt + 1'b1;
            if (b_cnt == 3'd7) OUTPUT <= {rx_shift[6:0], MOSI};
        end else b_cnt <= 0;
    end
endmodule

// ======================================================
// TOP MODULE: SPI COMMUNICATION
// ======================================================
module spi_communication (
    input  wire       M_REFCLK,
    input  wire [1:0] M_CNTL,
    input  wire [7:0] M_INPUT,
    output wire [7:0] M_OUTPUT,
    output wire       M_READY,
    input  wire [7:0] S_INPUT,
    input  wire       S_LOAD,
    output wire [7:0] S_OUTPUT,
    output wire       S_READY,
    output wire       M_MOSI,
    input  wire       M_MISO,
    output wire       M_SCLK,
    output wire [7:0] M_SS,
    input  wire       S_MOSI,
    output wire       S_MISO,
    input  wire       S_SCLK,
    input  wire       S_CS
);
    spi_master master_i (.REFCLK(M_REFCLK), .CNTL(M_CNTL), .INPUT(M_INPUT), .OUTPUT(M_OUTPUT), .READY(M_READY), .MOSI(M_MOSI), .MISO(M_MISO), .SCLK(M_SCLK), .SS(M_SS));
    spi_slave  slave_i  (.INPUT(S_INPUT), .LOAD(S_LOAD), .OUTPUT(S_OUTPUT), .READY(S_READY), .MOSI(S_MOSI), .MISO(S_MISO), .SCLK(S_SCLK), .CS(S_CS));
endmodule