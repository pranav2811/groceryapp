module encoder(a,b,c,d,x,y);
input a,b,c,d;
output x,y;
assign x= a|b;
assign y= a|c;
endmodule

module testbench;
reg a, b, c, d;
wire x,y;
encoder obj(a,b,c,d,x,y);
initial begin
$display("Inputs | Outputs");
$display("a b c d | x y");
$monitor("%b %b %b %b | %b %b", a,b,c,d,x,y);
a=0; b=0; c=0; d=1;
#10 a=0; b=0; c=1; d=0;
#10 a=0; b=1; c=0; d=0;
#10 a=1; b=0; c=0; d=0;
$finish;
end
endmodule