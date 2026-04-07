`timescale 1ns/1ps

module tb;

    reg push_clk;
    reg push_rst;
    reg pop_clk;
    reg pop_rst;
    reg push_sender_in_reset;
    wire push_receiver_in_reset;
    reg push_credit_stall;
    wire push_credit;
    reg push_valid;
    reg pop_ready;
    wire pop_valid;
    wire push_full;
    wire pop_empty;
    reg [7:0] push_data;
    wire [7:0] pop_data;
    wire [4:0] push_slots;
    reg [4:0] credit_initial_push;
    reg [4:0] credit_withhold_push;
    wire [4:0] credit_count_push;
    wire [4:0] credit_available_push;
    wire [4:0] pop_items;

    integer timeout_count;

    cdc_fifo_flops_push_credit dut (
        .push_clk(push_clk),
        .push_rst(push_rst),
        .pop_clk(pop_clk),
        .pop_rst(pop_rst),
        .push_sender_in_reset(push_sender_in_reset),
        .push_receiver_in_reset(push_receiver_in_reset),
        .push_credit_stall(push_credit_stall),
        .push_credit(push_credit),
        .push_valid(push_valid),
        .pop_ready(pop_ready),
        .pop_valid(pop_valid),
        .push_full(push_full),
        .pop_empty(pop_empty),
        .push_data(push_data),
        .pop_data(pop_data),
        .push_slots(push_slots),
        .credit_initial_push(credit_initial_push),
        .credit_withhold_push(credit_withhold_push),
        .credit_count_push(credit_count_push),
        .credit_available_push(credit_available_push),
        .pop_items(pop_items)
    );

    task automatic fail(input [8*160-1:0] msg);
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    task automatic wait_push_cycles(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) @(posedge push_clk);
        end
    endtask

    task automatic wait_pop_cycles(input integer count);
        integer i;
        begin
            for (i = 0; i < count; i = i + 1) @(posedge pop_clk);
        end
    endtask

    initial begin
        push_clk = 1'b0;
        forever #3 push_clk = ~push_clk;
    end

    initial begin
        pop_clk = 1'b0;
        forever #5 pop_clk = ~pop_clk;
    end

    initial begin
        push_rst = 1'b1;
        pop_rst = 1'b1;
        push_sender_in_reset = 1'b0;
        push_credit_stall = 1'b0;
        push_valid = 1'b0;
        pop_ready = 1'b0;
        push_data = 8'h00;
        credit_initial_push = 5'd17;
        credit_withhold_push = 5'd0;

        wait_push_cycles(3);
        wait_pop_cycles(3);
        push_rst = 1'b0;
        pop_rst = 1'b0;

        wait_push_cycles(3);
        wait_pop_cycles(3);
        #1;
        if (push_receiver_in_reset !== 1'b0) fail("push_receiver_in_reset should clear after reset");
        if (push_full !== 1'b0) fail("push_full should be low after reset");
        if (pop_empty !== 1'b1) fail("pop_empty should be high after reset");
        if (push_slots == 0) fail("push_slots should indicate available capacity after reset");

        pop_ready = 1'b1;
        push_data = 8'hA5;
        @(negedge push_clk);
        push_valid = 1'b1;
        @(posedge push_clk);
        @(negedge push_clk);
        push_valid = 1'b0;

        timeout_count = 0;
        while (pop_valid !== 1'b1 && timeout_count < 40) begin
            @(posedge pop_clk);
            timeout_count = timeout_count + 1;
        end
        if (pop_valid !== 1'b1) fail("pop_valid did not assert after a pushed item");
        #1;
        if (pop_data !== 8'hA5) fail("pop_data did not match the pushed item");

        @(posedge pop_clk);
        timeout_count = 0;
        while (push_credit !== 1'b1 && timeout_count < 40) begin
            @(posedge push_clk);
            timeout_count = timeout_count + 1;
        end
        if (push_credit !== 1'b1) fail("push_credit did not pulse after a successful pop");

        push_credit_stall = 1'b1;
        push_data = 8'h3C;
        @(negedge push_clk);
        push_valid = 1'b1;
        @(posedge push_clk);
        @(negedge push_clk);
        push_valid = 1'b0;

        timeout_count = 0;
        while (pop_valid !== 1'b1 && timeout_count < 40) begin
            @(posedge pop_clk);
            timeout_count = timeout_count + 1;
        end
        if (pop_valid !== 1'b1) fail("second pop_valid did not assert");
        #1;
        if (pop_data !== 8'h3C) fail("second pop_data did not match the pushed item");

        @(posedge pop_clk);
        wait_push_cycles(4);
        if (push_credit === 1'b1) fail("push_credit should be stalled when push_credit_stall is asserted");

        $display("TESTS PASSED");
        $finish;
    end

endmodule
