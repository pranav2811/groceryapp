module decoder(a,b,c,d,e,f,x);
input x,a,b;
output c,d,e,f;
assign c = x & (a & b);
assign d = x & (a & ~b);
assign e = x & (~a & b);
assign f = x & (~a & ~b);
endmodule

module testbench;
reg a, b, x;
wire c,d,e,f;
decoder obj(a,b,c,d,e,f,x);
initial begin
$dumpfile("decoder.vcd");
$dumpvars(0, testbench);
$display("Inputs | Outputs");
$display("x a b | c d e f");
$monitor("%b %b %b | %b %b %b %b",x,a,b,c,d,e,f);
x=0;a=0;b=0;
#10 x=1;a=0;b=0;
#10 x=1;a=1;b=0;
#10 x=1;a=0;b=1;
#10 x=1;a=1;b=1;
$finish;
end
endmodule