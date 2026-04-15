`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////

module para_carry_4bit(
    input [3:0] p,
    input [3:0] g,
    input c0,
    output [3:0] cout,
    output P_out
    );
    
    assign cout[0] = g[0] | (p[0]&c0);
    
    assign cout[1] = g[1] | (p[1]&g[0]) | (p[1]&p[0]&c0);
    
    assign cout[2] = g[2] | (p[2]&g[1]) | (p[2]&p[1]&g[0])| (p[2]&p[1]&p[0]&c0);   
    
    assign cout[3] = g[3] | (p[3]&g[2]) | (p[3]&p[2]&g[1]) |(p[3]&p[2]&p[1]&g[0])| (p[3]&p[2]&p[1]&p[0]&c0); 
    
    assign P_out = p[3]&p[2]&p[1]&p[0] ;
    
endmodule
