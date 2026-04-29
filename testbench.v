`timescale 1ns/1ps

module tb_spi_communication();
    reg clk;
    reg [1:0] m_cntl; reg [7:0] m_in; wire [7:0] m_out; wire m_rdy;
    reg [7:0] s_in; reg s_ld; wire [7:0] s_out; wire s_rdy;
    wire mosi, sclk, miso; wire [7:0] ss;

    // Kết nối các tín hiệu SPI giữa Master và Slave
    spi_communication dut (
        .M_REFCLK(clk), .M_CNTL(m_cntl), .M_INPUT(m_in), .M_OUTPUT(m_out), .M_READY(m_rdy),
        .S_INPUT(s_in), .S_LOAD(s_ld), .S_OUTPUT(s_out), .S_READY(s_rdy),
        .M_MOSI(mosi), .M_MISO(miso), .M_SCLK(sclk), .M_SS(ss),
        .S_MOSI(mosi), .S_MISO(miso), .S_SCLK(sclk), .S_CS(ss[0])
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    initial begin
        $dumpfile("dump.vcd"); $dumpvars(0, tb_spi_communication);
        m_cntl = 0; m_in = 0; s_in = 0; s_ld = 0;
        #100;

        $display("TEST 1: Master(0x55) -> Slave");
        s_in = 8'hAA; s_ld = 1; #10; s_ld = 0;
        m_in = 8'h55; m_cntl = 2'b01; #10; // Load Data
        m_in = 8'd0;  m_cntl = 2'b10; #10; // Select Slave 0
        m_cntl = 2'b11; #10;               // Start
        m_cntl = 2'b00;
        wait(m_rdy);
        #20;
        $display("Slave received: 0x%h, Master received: 0x%h", s_out, m_out);
        
        #100; $finish;
    end
endmodule