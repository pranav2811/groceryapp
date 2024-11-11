module BCD2Ex3(A,B,C,D,W,X,Y,Z);
input A,B,C,D;
output W,X,Y,Z;
assign W = A | (B&C) | (B&D);
assign X = (~B&C) | (~B & D) | (B & ~C & ~D);
assign Y = ~( C ^ D);
assign Z = ~D;
endmodule

module test;
wire W, X,Y,Z;
reg A,B,C,D;
BCD2Ex3 object(A,B,C,D,W,X,Y,Z);
initial begin
$dumpfile("dump_bcd.vcd");
$dumpvars(0,test);
$display (" A B C D | W X Y Z");
$monitor(" ",A, " ",B, " ",C, " ",D, " | ", W, " ",X, " ",Y, " ",Z);
A = 0;
B = 0;
C = 0;
D = 0;
#5 A = 0; B = 0; C = 0; D = 0;
#5 A = 0; B = 0; C = 0; D = 1;
#5 A = 0; B = 0; C = 1; D = 0;
#5 A = 0; B = 0; C = 1; D = 1;
#5 A = 0; B = 1; C = 0; D = 0;
#5 A = 0; B = 1; C = 0; D = 1;
#5 A = 0; B = 1; C = 1; D = 0;
#5 A = 0; B = 1; C = 1; D = 1;
#5 A = 1; B = 0; C = 0; D = 0;
#5 A = 1; B = 0; C = 0; D = 1;
end
endmodule