`timescale 1ns / 1ps


module tb_rv32i_cpu ();

    logic clk, rst;

    rv32i_top dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        @(negedge clk);
        @(negedge clk);
        rst = 0;

        // The multi-cycle core needs up to five clocks per instruction.
        repeat (40) @(negedge clk);
        $stop;
    end
endmodule
