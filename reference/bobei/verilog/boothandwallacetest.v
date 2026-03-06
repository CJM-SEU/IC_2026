module boothandwallacetest();

	reg [7:0] a;
	reg [7:0] b;
	reg rstn;
	wire [15:0] ab;
	reg clk;
	wire [15:0] p4_wire;
	wire [15:0] p3_wire;
	wire [15:0] p2_wire;
	wire [15:0] p1_wire;

	//---Module instantiation---
	partialproduct partialproduct1(
		.a(a),
		.b(b),
		.p1(p1_wire),
		.p2(p2_wire),
		.p3(p3_wire),
		.p4(p4_wire));

	wallace wallace2(
		.P1(p1_wire),
		.P2(p2_wire),
		.P3(p3_wire),
		.P4(p4_wire),
		.ab(ab),
		.clk(clk),
		.rstn(rstn));

	//----Code starts here: integrated by Robei-----
	always #2 clk=~clk;
	initial
	   begin
	     clk=0;
	     rstn=0;
	     a='b00000000;
	     b='b00000000;
	     #4;
		 rstn=1;
	     a='b10100111;//-89
	     b='b01101101;//109  .....结果应该为-9701
	     #4;
	     a='b11111011;//-5
	     b='b11111011;//-5   .....结果应该为25
	     #4;
	     a='b00001010;//10
	     b='b00000011;//3   .....结果应该为30
	     #4 $finish;
	   end
	
	
	
	initial begin
		$dumpfile ("F:/EDAzhang/eda/booth/boothandwallacetest.vcd");
		$dumpvars;
	end
endmodule    //boothandwallacetest

