`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////

module bit2booth(
    input [15:0] a,
    input [2:0] b_3bit,
    input [3:0] number,
    output reg [31:0] part_mul,
    output reg booth_c
    );

    // Radix-4 Booth编码单元：
    // 根据 b_3bit 选择 0, +/-A, +/-2A，并按 number 做位移。
    // booth_c 用于补码取反路径的进位补偿。
    
    reg [31:0] a0;
    always @(*)	begin
        a0 = {{32{a[15]}}, a};
    	case(b_3bit)
    		3'b000,3'b111: begin part_mul = 0;	booth_c = 0; end
    		3'b001,3'b010: begin part_mul = a0<<number;	booth_c = 0; end
    		3'b101,3'b110: begin part_mul = ~(a0<<number);	booth_c = 1; end
    		3'b011: begin part_mul = a0<<(number+1);	booth_c = 0; end
			3'b100: begin part_mul = ~(a0<<(number+1));	booth_c = 1; end
			default: begin part_mul = 0;	booth_c = 0; end
        endcase
   end
endmodule
