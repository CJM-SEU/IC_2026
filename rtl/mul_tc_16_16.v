`timescale 1ns/1ps

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

module mul_tc_16_16(
    input signed [15:0] a,
    input signed [15:0] b,
    output signed [31:0] product
    );
    
    wire signed [31:0] part_mul_0,part_mul_1,part_mul_2,part_mul_3,part_mul_4,part_mul_5,part_mul_6,part_mul_7;
    wire [7:0] booth_c ;
    
    //8�� ��λbooth�˷�
    bit2booth b0(a, {b[1:0],1'b0}, 4'd0,  part_mul_0, booth_c[0]);
    bit2booth b1(a, b[3:1],       4'd2,  part_mul_1, booth_c[1]);
    bit2booth b2(a, b[5:3],       4'd4,  part_mul_2, booth_c[2]);
    bit2booth b3(a, b[7:5],       4'd6,  part_mul_3, booth_c[3]);
    bit2booth b4(a, b[9:7],       4'd8,  part_mul_4, booth_c[4]);
    bit2booth b5(a, b[11:9],      4'd10, part_mul_5, booth_c[5]);
    bit2booth b6(a, b[13:11],     4'd12, part_mul_6, booth_c[6]);
    bit2booth b7(a, b[15:13],     4'd14, part_mul_7, booth_c[7]);
    
    //�м�ֵ
   // wire signed [31:0] test;
    //assign  test = part_mul_0 +part_mul_1+part_mul_2+part_mul_3+part_mul_4+part_mul_5+part_mul_6+part_mul_7+booth_c[0]+booth_c[1]+booth_c[2]+booth_c[3]+booth_c[4]+booth_c[5]+booth_c[6]+booth_c[7];
    
    wire [4:0]  c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,c10,c11,c12,c13,c14,c15,c16,c17,c18,c19,c20,c21,c22,c23,c24,c25,c26,c27,c28,c29,c30,c31;
    wire [31:0] wallace_c, wallace_s;                                          
    //32�� wallace tree 8�����룬���������λbooth_c
    wallace w0 (part_mul_0[0], part_mul_1[0], part_mul_2[0], part_mul_3[0], part_mul_4[0], part_mul_5[0], part_mul_6[0], part_mul_7[0], booth_c[5:0],   c0[4:0], wallace_c[0], wallace_s[0]);
    wallace w1 (part_mul_0[1], part_mul_1[1], part_mul_2[1], part_mul_3[1], part_mul_4[1], part_mul_5[1], part_mul_6[1], part_mul_7[1], {c0[4:0],1'b0}, c1[4:0], wallace_c[1], wallace_s[1]);
    wallace w2 (part_mul_0[2], part_mul_1[2], part_mul_2[2], part_mul_3[2], part_mul_4[2], part_mul_5[2], part_mul_6[2], part_mul_7[2], {c1[4:0],1'b0}, c2[4:0], wallace_c[2], wallace_s[2]);
    wallace w3 (part_mul_0[3], part_mul_1[3], part_mul_2[3], part_mul_3[3], part_mul_4[3], part_mul_5[3], part_mul_6[3], part_mul_7[3], {c2[4:0],1'b0}, c3[4:0], wallace_c[3], wallace_s[3]);
    wallace w4 (part_mul_0[4], part_mul_1[4], part_mul_2[4], part_mul_3[4], part_mul_4[4], part_mul_5[4], part_mul_6[4], part_mul_7[4], {c3[4:0],1'b0}, c4[4:0], wallace_c[4], wallace_s[4]);
    wallace w5 (part_mul_0[5], part_mul_1[5], part_mul_2[5], part_mul_3[5], part_mul_4[5], part_mul_5[5], part_mul_6[5], part_mul_7[5], {c4[4:0],1'b0}, c5[4:0], wallace_c[5], wallace_s[5]);
    wallace w6 (part_mul_0[6], part_mul_1[6], part_mul_2[6], part_mul_3[6], part_mul_4[6], part_mul_5[6], part_mul_6[6], part_mul_7[6], {c5[4:0],1'b0}, c6[4:0], wallace_c[6], wallace_s[6]);
    wallace w7 (part_mul_0[7], part_mul_1[7], part_mul_2[7], part_mul_3[7], part_mul_4[7], part_mul_5[7], part_mul_6[7], part_mul_7[7], {c6[4:0],1'b0}, c7[4:0], wallace_c[7], wallace_s[7]);
    wallace w8 (part_mul_0[8], part_mul_1[8], part_mul_2[8], part_mul_3[8], part_mul_4[8], part_mul_5[8], part_mul_6[8], part_mul_7[8], {c7[4:0],1'b0}, c8[4:0], wallace_c[8], wallace_s[8]);
    wallace w9 (part_mul_0[9], part_mul_1[9], part_mul_2[9], part_mul_3[9], part_mul_4[9], part_mul_5[9], part_mul_6[9], part_mul_7[9], {c8[4:0],1'b0}, c9[4:0], wallace_c[9], wallace_s[9]);
    wallace w10(part_mul_0[10],part_mul_1[10],part_mul_2[10],part_mul_3[10],part_mul_4[10],part_mul_5[10],part_mul_6[10],part_mul_7[10],{c9[4:0],1'b0}, c10[4:0],wallace_c[10],wallace_s[10]);
    wallace w11(part_mul_0[11],part_mul_1[11],part_mul_2[11],part_mul_3[11],part_mul_4[11],part_mul_5[11],part_mul_6[11],part_mul_7[11],{c10[4:0],1'b0},c11[4:0],wallace_c[11],wallace_s[11]);
    wallace w12(part_mul_0[12],part_mul_1[12],part_mul_2[12],part_mul_3[12],part_mul_4[12],part_mul_5[12],part_mul_6[12],part_mul_7[12],{c11[4:0],1'b0},c12[4:0],wallace_c[12],wallace_s[12]);
    wallace w13(part_mul_0[13],part_mul_1[13],part_mul_2[13],part_mul_3[13],part_mul_4[13],part_mul_5[13],part_mul_6[13],part_mul_7[13],{c12[4:0],1'b0},c13[4:0],wallace_c[13],wallace_s[13]);
    wallace w14(part_mul_0[14],part_mul_1[14],part_mul_2[14],part_mul_3[14],part_mul_4[14],part_mul_5[14],part_mul_6[14],part_mul_7[14],{c13[4:0],1'b0},c14[4:0],wallace_c[14],wallace_s[14]);
    wallace w15(part_mul_0[15],part_mul_1[15],part_mul_2[15],part_mul_3[15],part_mul_4[15],part_mul_5[15],part_mul_6[15],part_mul_7[15],{c14[4:0],1'b0},c15[4:0],wallace_c[15],wallace_s[15]);
    wallace w16(part_mul_0[16],part_mul_1[16],part_mul_2[16],part_mul_3[16],part_mul_4[16],part_mul_5[16],part_mul_6[16],part_mul_7[16],{c15[4:0],1'b0},c16[4:0],wallace_c[16],wallace_s[16]);
    wallace w17(part_mul_0[17],part_mul_1[17],part_mul_2[17],part_mul_3[17],part_mul_4[17],part_mul_5[17],part_mul_6[17],part_mul_7[17],{c16[4:0],1'b0},c17[4:0],wallace_c[17],wallace_s[17]);
    wallace w18(part_mul_0[18],part_mul_1[18],part_mul_2[18],part_mul_3[18],part_mul_4[18],part_mul_5[18],part_mul_6[18],part_mul_7[18],{c17[4:0],1'b0},c18[4:0],wallace_c[18],wallace_s[18]);
    wallace w19(part_mul_0[19],part_mul_1[19],part_mul_2[19],part_mul_3[19],part_mul_4[19],part_mul_5[19],part_mul_6[19],part_mul_7[19],{c18[4:0],1'b0},c19[4:0],wallace_c[19],wallace_s[19]);
    wallace w20(part_mul_0[20],part_mul_1[20],part_mul_2[20],part_mul_3[20],part_mul_4[20],part_mul_5[20],part_mul_6[20],part_mul_7[20],{c19[4:0],1'b0},c20[4:0],wallace_c[20],wallace_s[20]);
    wallace w21(part_mul_0[21],part_mul_1[21],part_mul_2[21],part_mul_3[21],part_mul_4[21],part_mul_5[21],part_mul_6[21],part_mul_7[21],{c20[4:0],1'b0},c21[4:0],wallace_c[21],wallace_s[21]);
    wallace w22(part_mul_0[22],part_mul_1[22],part_mul_2[22],part_mul_3[22],part_mul_4[22],part_mul_5[22],part_mul_6[22],part_mul_7[22],{c21[4:0],1'b0},c22[4:0],wallace_c[22],wallace_s[22]);
    wallace w23(part_mul_0[23],part_mul_1[23],part_mul_2[23],part_mul_3[23],part_mul_4[23],part_mul_5[23],part_mul_6[23],part_mul_7[23],{c22[4:0],1'b0},c23[4:0],wallace_c[23],wallace_s[23]);
    wallace w24(part_mul_0[24],part_mul_1[24],part_mul_2[24],part_mul_3[24],part_mul_4[24],part_mul_5[24],part_mul_6[24],part_mul_7[24],{c23[4:0],1'b0},c24[4:0],wallace_c[24],wallace_s[24]);
    wallace w25(part_mul_0[25],part_mul_1[25],part_mul_2[25],part_mul_3[25],part_mul_4[25],part_mul_5[25],part_mul_6[25],part_mul_7[25],{c24[4:0],1'b0},c25[4:0],wallace_c[25],wallace_s[25]);
    wallace w26(part_mul_0[26],part_mul_1[26],part_mul_2[26],part_mul_3[26],part_mul_4[26],part_mul_5[26],part_mul_6[26],part_mul_7[26],{c25[4:0],1'b0},c26[4:0],wallace_c[26],wallace_s[26]);
    wallace w27(part_mul_0[27],part_mul_1[27],part_mul_2[27],part_mul_3[27],part_mul_4[27],part_mul_5[27],part_mul_6[27],part_mul_7[27],{c26[4:0],1'b0},c27[4:0],wallace_c[27],wallace_s[27]);
    wallace w28(part_mul_0[28],part_mul_1[28],part_mul_2[28],part_mul_3[28],part_mul_4[28],part_mul_5[28],part_mul_6[28],part_mul_7[28],{c27[4:0],1'b0},c28[4:0],wallace_c[28],wallace_s[28]);
    wallace w29(part_mul_0[29],part_mul_1[29],part_mul_2[29],part_mul_3[29],part_mul_4[29],part_mul_5[29],part_mul_6[29],part_mul_7[29],{c28[4:0],1'b0},c29[4:0],wallace_c[29],wallace_s[29]);
    wallace w30(part_mul_0[30],part_mul_1[30],part_mul_2[30],part_mul_3[30],part_mul_4[30],part_mul_5[30],part_mul_6[30],part_mul_7[30],{c29[4:0],1'b0},c30[4:0],wallace_c[30],wallace_s[30]);
    wallace w31(part_mul_0[31],part_mul_1[31],part_mul_2[31],part_mul_3[31],part_mul_4[31],part_mul_5[31],part_mul_6[31],part_mul_7[31],{c30[4:0],1'b0},c31[4:0],wallace_c[31],wallace_s[31]);
                                                                                                                                           
    //32λ�ӷ���
    adder32 a0(wallace_s, {wallace_c[30:0],booth_c[6]}, booth_c[7], product);
    
endmodule
