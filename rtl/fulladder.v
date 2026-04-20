`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////

module fulladder(
    input in1,
    input in2,
    input in3,
    output carry,
    output sum
    );

    // 1-bit 全加器，供 Wallace tree 多级压缩复用。
    assign sum = ~in1&~in2&in3 | ~in1&in2&~in3 | in1&~in2&~in3 | in1&in2&in3;
    assign carry = in1&in2 | in1&in3 | in2&in3 ;
endmodule
