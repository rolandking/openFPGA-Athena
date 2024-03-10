module ym3256_mem#(
    parameter logic[24:0] ROM_ADDR_FROM = 32'h00020000,
    parameter logic[24:0] ROM_ADDR_TO   = 32'h0002bfff
) (
    input logic reset_n,
    // addr 15:0, data: 7:0
    bus_if      ym3256,
    // addr 24:0, data: 7:0
    bus_if      mem,
    // addr 22:0, data: 15:0
    cram_if     cram
);

    logic        clk;
    logic [22:0] rd_address;
    logic        rd_en;
    logic        rd_ack;
    logic [15:0] rd_data;
    logic [22:0] wr_address;
    logic        wr_en;
    logic        wr_ack;
    logic [15:0] wr_data;

    psram#(
        .CLK_FREQ     (53600000),
        .USER_CYCLES  (4),
        .ADDRESS_BITS (23),
        .DATA_BITS    (16),
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
        .positive  ('1)
    ) edge_detect_rd (
        .clk  (ym3256.clk),
        .in   (ym3256.rd ),
        .out  (rd_pulse  )
    );

    logic wr_pulse;
    edge_detect#(
        .positive  ('1)
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
            rd_address     = {7'd0,ym3256.addr};
            rd_en          = rd_pulse;
            wr_address     = {7'd0,ym3256.addr};
            wr_en          = wr_pulse;
            wr_data        = {8'haa,ym3256.wr_data};
            ym3256.rd_data = rd_data[7:0];
        end else begin
            // in reset - join the cram to the mem bus,
            // this is only writes so disconnect read
            rd_address     = 'x;
            wr_address     = {7'd0,mem.addr[15:0]};
            rd_en          = '0;
            wr_en          = mem.wr && mem_addr_match;
            wr_data        = {8'h55,mem.wr_data};
            ym3256.rd_data = 8'hCC;
        end
    end

endmodule
