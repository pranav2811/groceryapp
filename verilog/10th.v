module D_FlipFlop(D,clk,Q);
input D;
input clk;
output reg Q;
always @(posedge clk)
begin
Q <= D;
end
endmodule
// Testbench Verilog code for verification
module tb_DFF();
reg D;
reg clk;
wire Q;
D_FlipFlop dut(D,clk,Q);
initial begin
clk=0;
forever #10 clk = ~clk;
end
initial begin
$display(" T \t clk \t D \t| q");
$monitor(" %0t \t %d \t %d | %d",$time,clk,D,Q);
end
initial begin
D = 0;
#20;
D = 1;
#20;
D = 0;
#20;
D = 1;
$finish;
end
endmodule