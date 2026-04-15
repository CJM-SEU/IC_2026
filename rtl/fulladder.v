`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////

module fulladder(
    input in1,
    input in2,
    input in3,
    output carry,
    output sum
    );
    
    assign sum = ~in1&~in2&in3 | ~in1&in2&~in3 | in1&~in2&~in3 | in1&in2&in3;
    assign carry = in1&in2 | in1&in3 | in2&in3 ;
endmodule
