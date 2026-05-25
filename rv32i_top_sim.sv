`timescale 1ns / 1ps

module rv32i_top_sim;
    logic clk;
    logic rst;

    rv32i_top dut (
        .clk(clk),
        .rst(rst)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;
    end
endmodule
