`timescale 1ns/1ps

module athena_dip(
    bus_if              bridge,
    output logic [15:0] dip_switches
);
    athena::dip_switch_t dip_switch = athena::DIP_SWITCH_DEFAULT;

    always_ff @(posedge bridge.clk) begin
        case(bridge.addr)
            32'h00200000: begin
                if(bridge.wr) begin
                    dip_switch.cabinet <= athena::cabinet_e'(bridge.wr_data);
                end
                bridge.rd_data <= dip_switch.cabinet;
            end
            32'h00200004: begin
                if(bridge.wr) begin
                    dip_switch.lives <= athena::lives_e'(bridge.wr_data);
                end
                bridge.rd_data <= dip_switch.lives;
            end
            32'h00200008: begin
                if(bridge.wr) begin
                    dip_switch.coin_a <= athena::coin_a_e'(bridge.wr_data);
                end
                bridge.rd_data <= dip_switch.coin_a;
            end
            32'h0020000c: begin
                if(bridge.wr) begin
                    dip_switch.coin_b <= athena::coin_b_e'(bridge.wr_data);
                end
                bridge.rd_data <= dip_switch.coin_b;
            end
            32'h00200010: begin
                if(bridge.wr) begin
                    dip_switch.difficulty <= athena::difficulty_e'(bridge.wr_data);
                end
                bridge.rd_data <= dip_switch.difficulty;
            end
            32'h00200014: begin
                if(bridge.wr) begin
                    dip_switch.demo_sounds <= athena::demo_sounds_e'(bridge.wr_data);
                end
                bridge.rd_data <= dip_switch.demo_sounds;
            end
            32'h00200018: begin
                if(bridge.wr) begin
                    dip_switch.bonus_life <= athena::bonus_life_e'(bridge.wr_data);
                end
                bridge.rd_data <= dip_switch.bonus_life;
            end
            32'h0020001c: begin
                if(bridge.wr) begin
                    dip_switch.energy <= athena::energy_e'(bridge.wr_data);
                end
                bridge.rd_data <= dip_switch.energy;
            end
            default: begin
                bridge.rd_data <= '0;
            end

        endcase
        bridge.rd_data_valid <= bridge.rd;
    end

    always_comb begin
        dip_switches = athena::dip_switch_map(dip_switch);
    end

endmodule
