module ym3256_mem#(
    parameter logic[31:0] ROM_ADDR_FROM = 32'h00020000,
    parameter logic[31:0] ROM_ADDR_TO   = 32'h0002bfff
) (
    input logic reset_n,
    bus_if      ym3256,
    bus_if      mem,
    cram_if     cram
);

    logic        clk;
    logic [15:0] rd_address;
    logic        rd_en;
    logic        rd_ack;
    logic [7:0]  rd_data;
    logic [15:0] wr_address;
    logic        wr_en;
    logic        wr_ack;
    logic [7:0]  wr_data;

    psram#(
        .CLK_FREQ     (53600000),
        .USER_CYCLES  (6),
        .ADDRESS_BITS (16),
        .DATA_BITS    (8),
        .WRITE_WINS   ('1)
    ) ym_ram (

        .clk,
        .rd_address,
        .rd_en,
        .rd_ack(),
        .rd_data,
        .wr_address,
        .wr_en,
        .wr_data,
        .wr_ack(),

        .cram
    );

    logic rd_pulse;
    edge_detect#(
        .positive  ('0)
    ) edge_detect_rd (
        .clk  (ym3256.clk),
        .in   (ym3256.rd ),
        .out  (rd_pulse  )
    );

    logic wr_pulse;
    edge_detect#(
        .positive  ('0)
    ) edge_detect_wr (
        .clk  (ym3256.clk),
        .in   (ym3256.wr ),
        .out  (wr_pulse  )
    );

    logic mem_addr_match;
    always_comb begin
        mem_addr_match = (mem.addr >= ROM_ADDR_FROM && mem.addr <= ROM_ADDR_TO);
        clk            = mem.clk;
        if(reset_n) begin
            // out of reset connect directly to the CPU
            rd_address     = ym3256.addr;
            rd_en          = rd_pulse;
            wr_address     = ym3256.addr;
            wr_en          = wr_pulse;
            wr_data        = ym3256.wr_data;
            ym3256.rd_data = rd_data;
        end else begin
            // in reset - join the cram to the mem bus,
            // this is only writes so disconnect read
            rd_address     = 'x;
            wr_address     = mem.addr;
            rd_en          = '0;
            wr_en          = mem.wr && mem_addr_match;
            wr_data        = mem.wr_data;
            ym3256.rd_data = 'x;
        end
    end

endmodule
