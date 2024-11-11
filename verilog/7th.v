module demux(s1,s2,a,b,c,d,i,e);
input s1,s2,i,e;
output a,b,c,d;
assign a = i & e & ~s1 & ~s2;
assign b = i & e & ~s1 & s2;
assign c = i & e & s1 & ~s2;
assign d = i & e & s1 & s2;
endmodule

module testbench;
reg s1, s2,i,e;
wire a,b,c,d;
demux obj(s1,s2,a,b,c,d,i,e);
initial begin
$display("i\t e\t s1 \t s2 \t a \t b \t c\t d\t");
$monitor("%b \t %b \t %b \t %b \t %b \t %b \t %b | %b",i,e,s1,s2,a,b,c,d);
i=0; e=0; s1=0;s2=0;
#10 i=0; e=0;s1=0; s2=1;
#10 i=0; e=0;s1=1; s2=0;
#10 i=0; e=0;s1=1; s2=1;
#10 i=0; e=1;s1=0; s2=0;
#10 i=0; e=1;s1=0; s2=1;
#10 i=0; e=1;s1=1; s2=0;
#10 i=0; e=1;s1=1; s2=1;
#10 i=1; e=0;s1=0; s2=0;
#10 i=1; e=0;s1=0; s2=1;
#10 i=1; e=0;s1=1; s2=0;
#10 i=1; e=0;s1=1; s2=1;
#10 i=1; e=1;s1=0; s2=0;
#10 i=1; e=1;s1=0; s2=1;
#10 i=1; e=1;s1=1; s2=0;
#10 i=1; e=1;s1=1; s2=1;
#10
$finish;
end
endmodule