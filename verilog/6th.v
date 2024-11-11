module mux(s1,s2,a,b,c,d,y);
input s1,s2,a,b,c,d;
output y;
assign y = ~s1 & ~s2 & a | ~s1 &s2 &b | s1 & ~s2 & c | s1 & s2 & d;
endmodule

module testbench;
reg a, b, c, d, s1, s2;
wire y;
mux obj(s1,s2,a,b,c,d,y);
initial begin
$dumpfile("mux.vcd");
$dumpvars(0, testbench);
$display("s1\t s2\t a\t b\t c\t d");
$monitor("%b\t %b\t %b\t %b\t %b\t %b | %b", s1, s2, a, b, c, d, y);
a=0; b=0; c=0; d=0; s1=0; s2=0;
#10 a=0; b=0; c=0; d=1; s1=0; s2=1;
#10 a=0; b=0; c=1; d=0; s1=1; s2=0;
#10 a=0; b=0; c=1; d=1; s1=1; s2=1;
#10 a=0; b=1; c=0; d=0; s1=0; s2=1;
#10 a=0; b=1; c=0; d=1; s1=1; s2=0;
#10 a=0; b=1; c=1; d=0; s1=1; s2=1;
#10 a=0; b=1; c=1; d=1; s1=0; s2=0;
#10 a=1; b=0; c=0; d=0; s1=1; s2=0;
#10 a=1; b=0; c=0; d=1; s1=1; s2=1;
#10
$finish;
end
endmodule