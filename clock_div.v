`define SIZE 21
module clock_div (
    input  wire clk,
    input  wire enable,
    output wire clk_div
);

reg [`SIZE-1:0] counter = `SIZE'h0;

always @(posedge clk ) 
        counter <= counter + 1'b1;
assign clk_div = enable ? counter[`SIZE-1] : clk;
endmodule
