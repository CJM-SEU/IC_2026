`timescale 1ns/1ps

module tb_csa32;

    // csa32 组合逻辑TB：
    // 1) 校验位级关系 s=x^y^z 与 c={(majority)[30:0],1'b0}
    // 2) 校验等效关系 (s+c) == (x+y+z) 的低32位

    reg  [31:0] x;
    reg  [31:0] y;
    reg  [31:0] z;
    wire [31:0] s;
    wire [31:0] c;

    reg  [31:0] exp_s;
    reg  [31:0] exp_c;
    reg  [32:0] full_sum;

    integer i;

    csa32 dut (
        .x(x),
        .y(y),
        .z(z),
        .s(s),
        .c(c)
    );

    task check_case;
        input [31:0] tx;
        input [31:0] ty;
        input [31:0] tz;
        begin
            x = tx;
            y = ty;
            z = tz;
            #1;

            exp_s = tx ^ ty ^ tz;
            exp_c = (((tx & ty) | (tx & tz) | (ty & tz)) << 1);
            full_sum = {1'b0, tx} + {1'b0, ty} + {1'b0, tz};

            if (s !== exp_s) begin
                $display("ERROR: s mismatch. x=%h y=%h z=%h got=%h exp=%h", tx, ty, tz, s, exp_s);
                $fatal(1);
            end

            if (c !== exp_c) begin
                $display("ERROR: c mismatch. x=%h y=%h z=%h got=%h exp=%h", tx, ty, tz, c, exp_c);
                $fatal(1);
            end

            if ((s + c) !== full_sum[31:0]) begin
                $display("ERROR: s+c mismatch. x=%h y=%h z=%h got=%h exp=%h", tx, ty, tz, (s + c), full_sum[31:0]);
                $fatal(1);
            end
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_csa32);

        // 定向边界向量
        check_case(32'h00000000, 32'h00000000, 32'h00000000);
        check_case(32'h00000001, 32'h00000001, 32'h00000001);
        check_case(32'hFFFFFFFF, 32'h00000000, 32'h00000000);
        check_case(32'hFFFFFFFF, 32'hFFFFFFFF, 32'h00000000);
        check_case(32'hFFFFFFFF, 32'hFFFFFFFF, 32'hFFFFFFFF);
        check_case(32'hAAAAAAAA, 32'h55555555, 32'h0F0F0F0F);
        check_case(32'h80000000, 32'h80000000, 32'h80000000);

        // 随机回归
        for (i = 0; i < 2000; i = i + 1) begin
            check_case($random, $random, $random);
        end

        $display("=== tb_csa32 PASS ===");
        $finish;
    end

endmodule
