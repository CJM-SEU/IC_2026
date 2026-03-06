//////////////////////////////////////////////////////////////////////////////////

module wallace(
    input part_mul_0,
    input part_mul_1,
    input part_mul_2,
    input part_mul_3,
    input part_mul_4,
    input part_mul_5,
    input part_mul_6,
    input part_mul_7,
    input [5:0] c_in,
    output [4:0] c_out,
    output wallace_c,
    output wallace_s
    );
	
	wire in10,in11,in13,in14,in21,in22,in31;
	fulladder f00(part_mul_0,part_mul_1,part_mul_2,c_out[0],in10);
	fulladder f01(part_mul_3,part_mul_4,part_mul_5,c_out[1],in11);    
	fulladder f02(part_mul_6,part_mul_7,c_in[0],   in13,    in14); 
	
	fulladder f10(in10,      in11,      in13,      c_out[2],in21);
	fulladder f11(in14,      c_in[1],   c_in[2],   c_out[3],in22);
	
	fulladder f20(in21,      in22,      c_in[3],   c_out[4],in31);
	
	fulladder f30(in31,      c_in[4],   c_in[5],   wallace_c,wallace_s);
    
endmodule
