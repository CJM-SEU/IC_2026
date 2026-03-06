//////////////////////////////////////////////////////////////////////////////////

module adder32(
    input [31:0] wallace_s,
    input [31:0] wallace_c,
    input booth_c,
    output [31:0] product
    );
    
    wire [31:0] P,G;	//传播，产生
    assign P = wallace_s | wallace_c ;
    assign G = wallace_s & wallace_c ;
    
    wire [31:0] C;	//第0级超前进位加法器
    wire [7:0] pm;	//第0级超前进位加法器的p out
    wire [7:0] c1;	//第1级超前进位加法器
    wire [1:0] pm1;	//第1级超前进位加法器的p out
    wire [3:0] c2;	//第2级超前进位加法器
    wire 	  pm2;	//第2级超前进位加法器的p out
    
    //第0级 0 1 2 3 超前进位加法器
    para_carry_4bit p00(P[3:0],  G[3:0],  booth_c,C[3:0],  pm[0]);
    para_carry_4bit p01(P[7:4],  G[7:4],  c1[0],  C[7:4],  pm[1]);
    para_carry_4bit p02(P[11:8], G[11:8], c1[1],  C[11:8], pm[2]);
    para_carry_4bit p03(P[15:12],G[15:12],c1[2],  C[15:12],pm[3]);
    //第1级 0 超前进位加法器
    para_carry_4bit p10(pm[3:0],{C[15],C[11],C[7],C[3]},booth_c,c1[3:0],pm1[0]);
    
    //第0级 4 5 6 7 超前进位加法器
    para_carry_4bit p04(P[19:16],G[19:16],c2[0],C[19:16],pm[4]);
    para_carry_4bit p05(P[23:20],G[23:20],c1[4],C[23:20],pm[5]);
    para_carry_4bit p06(P[27:24],G[27:24],c1[5],C[27:24],pm[6]);
    para_carry_4bit p07(P[31:28],G[31:28],c1[6],C[31:28],pm[7]);
    //第1级 1 超前进位加法器
    para_carry_4bit p11(pm[7:4],{C[31],C[27],C[23],C[19]},c2[0],c1[7:4],pm1[1]);
    
    //第2级 0 超前进位加法器
    para_carry_4bit p20({0,0,pm1},{0,0,c1[7],c1[3]},booth_c,c2,pm2);   
    
    wire [31:0] newC;
    assign newC = {C[30:0],booth_c};
    assign product = (~wallace_s&~wallace_c&newC)|(~wallace_s&wallace_c&~newC)|(wallace_s&~wallace_c&~newC)|(wallace_s&wallace_c&newC);
    
    
endmodule
