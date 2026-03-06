`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////

module mul_tc_16_16_tb();
    reg signed [15:0] a,b;
    wire signed [31:0] product;
    initial begin
        a = 0;
        b = 0;
        #100
        a = 12365;
        b = 1520;
        #100
        a = 16'b1000000000000001;   //-32767
        b = 16'b1000000000000001;   //-32767  //1,073,676,289
        #100
        a = -5555;
        b = -120;  
        #100 
        a = 24704;
        b = -32767;  
        #100 
        a = -24704;
        b = 32767;  
        #100 
        a = 24704;
        b = 32767;  
        #100 

        a = 15;
        b = -6767;  
        #100 
        a = -15;
        b = 6767;  
        #100 
        a = 15;
        b = 6767;  
        #100 
        $finish;
    
    end
    initial begin
        $dumpfile("dump.vcd"); // 生成 dump.vcd 文件
        $dumpvars(0, mul_tc_16_16_tb); // 记录所有信号
    end
    mul_tc_16_16 m0(a,b,product);


endmodule
