`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst;
    reg push_sender_in_reset;
    wire push_receiver_in_reset;
    reg push_credit_stall;
    wire push_credit;
    reg push_valid;
    reg pop_credit;
    wire pop_valid;
    reg credit_initial;
    reg credit_withhold;
    wire credit_count;
    wire credit_available;
    reg [7:0] push_data;
    wire [7:0] pop_data;

    credit_receiver dut (
        .clk(clk),
        .rst(rst),
        .push_sender_in_reset(push_sender_in_reset),
        .push_receiver_in_reset(push_receiver_in_reset),
        .push_credit_stall(push_credit_stall),
        .push_credit(push_credit),
        .push_valid(push_valid),
        .pop_credit(pop_credit),
        .pop_valid(pop_valid),
        .credit_initial(credit_initial),
        .credit_withhold(credit_withhold),
        .credit_count(credit_count),
        .credit_available(credit_available),
        .push_data(push_data),
        .pop_data(pop_data)
    );

    task automatic fail(input [8*160-1:0] msg);
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        push_sender_in_reset = 1'b0;
        push_credit_stall = 1'b0;
        push_valid = 1'b0;
        pop_credit = 1'b0;
        credit_initial = 1'b1;
        credit_withhold = 1'b0;
        push_data = 8'h00;

        @(posedge clk);
        #1;
        if (push_receiver_in_reset !== 1'b1) fail("push_receiver_in_reset should mirror rst");
        if (pop_valid !== 1'b0) fail("pop_valid should be low during reset");
        if (push_credit !== 1'b0) fail("push_credit should be low during reset");
        if (credit_count !== 1'b1) fail("credit_count should load credit_initial on reset");

        rst = 1'b0;
        push_data = 8'h5A;
        push_valid = 1'b1;
        #1;
        if (pop_valid !== 1'b1) fail("pop_valid should follow push_valid out of reset");
        if (pop_data !== 8'h5A) fail("pop_data should match push_data");
        if (push_credit !== 1'b1) fail("push_credit should be asserted when a credit is available");

        push_credit_stall = 1'b1;
        #1;
        if (push_credit !== 1'b0) fail("push_credit should drop when stalled");

        push_credit_stall = 1'b0;
        credit_withhold = 1'b1;
        #1;
        if (credit_available !== 1'b0) fail("credit_available should be zero when the single credit is withheld");
        if (push_credit !== 1'b0) fail("push_credit should be low when all credit is withheld");

        credit_withhold = 1'b0;
        pop_credit = 1'b1;
        @(posedge clk);
        #1;
        if (credit_count !== 1'b1) fail("credit_count should stay at one after a replenishing pop_credit");

        push_sender_in_reset = 1'b1;
        #1;
        if (pop_valid !== 1'b0) fail("push_sender_in_reset should block pop_valid");
        push_sender_in_reset = 1'b0;

        $display("TESTS PASSED");
        $finish;
    end

endmodule
