`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst;
    reg reinit;
    reg incr_valid;
    reg decr_valid;
    reg [3:0] initial_value;
    reg [1:0] incr;
    reg [1:0] decr;
    wire [3:0] value;
    wire [3:0] value_next;

    counter dut (
        .clk(clk),
        .rst(rst),
        .reinit(reinit),
        .incr_valid(incr_valid),
        .decr_valid(decr_valid),
        .initial_value(initial_value),
        .incr(incr),
        .decr(decr),
        .value(value),
        .value_next(value_next)
    );

    function automatic [3:0] wrap_0_to_10(input integer raw_value);
        integer temp;
        begin
            temp = raw_value;
            while (temp < 0) begin
                temp = temp + 11;
            end
            while (temp > 10) begin
                temp = temp - 11;
            end
            wrap_0_to_10 = temp[3:0];
        end
    endfunction

    function automatic [3:0] expected_next_value(
        input [3:0] cur_value,
        input rst_i,
        input reinit_i,
        input incr_valid_i,
        input decr_valid_i,
        input [3:0] initial_value_i,
        input [1:0] incr_i,
        input [1:0] decr_i
    );
        integer delta;
        begin
            if (rst_i || reinit_i) begin
                expected_next_value = initial_value_i;
            end else begin
                delta = 0;
                if (incr_valid_i) begin
                    delta = delta + incr_i;
                end
                if (decr_valid_i) begin
                    delta = delta - decr_i;
                end
                expected_next_value = wrap_0_to_10(cur_value + delta);
            end
        end
    endfunction

    task automatic fail(input [8*160-1:0] msg);
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    task automatic check_outputs(
        input [8*160-1:0] label,
        input [3:0] expected_value_now,
        input [3:0] expected_next_now
    );
        begin
            #1;
            if (value !== expected_value_now) begin
                $display(
                    "Mismatch after %0s: value expected %0d got %0d",
                    label,
                    expected_value_now,
                    value
                );
                $finish;
            end
            if (value_next !== expected_next_now) begin
                $display(
                    "Mismatch after %0s: value_next expected %0d got %0d",
                    label,
                    expected_next_now,
                    value_next
                );
                $finish;
            end
            if (value > 10 || value_next > 10) begin
                fail("counter outputs must stay in range 0..10");
            end
        end
    endtask

    task automatic check_value_only(
        input [8*160-1:0] label,
        input [3:0] expected_value_now
    );
        begin
            #1;
            if (value !== expected_value_now) begin
                $display(
                    "Mismatch after %0s: value expected %0d got %0d",
                    label,
                    expected_value_now,
                    value
                );
                $finish;
            end
            if (value > 10) begin
                fail("counter value must stay in range 0..10");
            end
        end
    endtask

    task automatic apply_cycle(
        input [8*160-1:0] label,
        input rst_i,
        input reinit_i,
        input incr_valid_i,
        input decr_valid_i,
        input [3:0] initial_value_i,
        input [1:0] incr_i,
        input [1:0] decr_i,
        inout [3:0] model_value
    );
        reg [3:0] expected_next;
        reg [3:0] expected_next_after_edge;
        begin
            @(negedge clk);
            rst = rst_i;
            reinit = reinit_i;
            incr_valid = incr_valid_i;
            decr_valid = decr_valid_i;
            initial_value = initial_value_i;
            incr = incr_i;
            decr = decr_i;

            expected_next = expected_next_value(
                model_value,
                rst_i,
                reinit_i,
                incr_valid_i,
                decr_valid_i,
                initial_value_i,
                incr_i,
                decr_i
            );

            if (rst_i) begin
                check_value_only({label, " (before rising edge)"}, model_value);
            end else begin
                check_outputs({label, " (before rising edge)"}, model_value, expected_next);
            end

            @(posedge clk);
            model_value = expected_next;
            if (rst_i) begin
                check_value_only({label, " (after rising edge)"}, model_value);
            end else begin
                expected_next_after_edge = expected_next_value(
                    model_value,
                    rst_i,
                    reinit_i,
                    incr_valid_i,
                    decr_valid_i,
                    initial_value_i,
                    incr_i,
                    decr_i
                );
                check_outputs(
                    {label, " (after rising edge)"},
                    model_value,
                    expected_next_after_edge
                );
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        reg [3:0] model_value;

        rst = 1'b1;
        reinit = 1'b0;
        incr_valid = 1'b1;
        decr_valid = 1'b1;
        initial_value = 4'd6;
        incr = 2'd3;
        decr = 2'd2;
        model_value = 4'd6;

        @(posedge clk);
        #1;
        if (value !== 4'd6) begin
            $display(
                "Mismatch after initial synchronous reset: value expected %0d got %0d",
                4'd6,
                value
            );
            $finish;
        end
        if (value > 10) begin
            fail("counter value must stay in range 0..10");
        end

        apply_cycle("hold after reset", 1'b0, 1'b0, 1'b0, 1'b0, 4'd6, 2'd0, 2'd0, model_value);
        apply_cycle("increment by one", 1'b0, 1'b0, 1'b1, 1'b0, 4'd0, 2'd1, 2'd0, model_value);
        apply_cycle("increment by three", 1'b0, 1'b0, 1'b1, 1'b0, 4'd0, 2'd3, 2'd0, model_value);
        apply_cycle("decrement by two", 1'b0, 1'b0, 1'b0, 1'b1, 4'd0, 2'd0, 2'd2, model_value);
        apply_cycle("simultaneous incr and decr net plus one", 1'b0, 1'b0, 1'b1, 1'b1, 4'd0, 2'd3, 2'd2, model_value);
        apply_cycle("simultaneous incr and decr net zero", 1'b0, 1'b0, 1'b1, 1'b1, 4'd0, 2'd2, 2'd2, model_value);
        apply_cycle("simultaneous incr and decr net minus two", 1'b0, 1'b0, 1'b1, 1'b1, 4'd0, 2'd1, 2'd3, model_value);

        apply_cycle("reset to nine before overflow test", 1'b1, 1'b0, 1'b0, 1'b0, 4'd9, 2'd0, 2'd0, model_value);
        apply_cycle("overflow wraps 9 plus 3 to 1", 1'b0, 1'b0, 1'b1, 1'b0, 4'd0, 2'd3, 2'd0, model_value);
        apply_cycle("overflow wraps 1 plus 10 total sequence part one", 1'b0, 1'b0, 1'b1, 1'b0, 4'd0, 2'd3, 2'd0, model_value);
        apply_cycle("overflow wraps 4 plus 3", 1'b0, 1'b0, 1'b1, 1'b0, 4'd0, 2'd3, 2'd0, model_value);
        apply_cycle("overflow wraps 7 plus 3 to 10", 1'b0, 1'b0, 1'b1, 1'b0, 4'd0, 2'd3, 2'd0, model_value);
        apply_cycle("overflow wraps 10 plus 1 to 0", 1'b0, 1'b0, 1'b1, 1'b0, 4'd0, 2'd1, 2'd0, model_value);

        apply_cycle("reset to one before underflow test", 1'b1, 1'b0, 1'b0, 1'b0, 4'd1, 2'd0, 2'd0, model_value);
        apply_cycle("underflow wraps 1 minus 3 to 9", 1'b0, 1'b0, 1'b0, 1'b1, 4'd0, 2'd0, 2'd3, model_value);
        apply_cycle("underflow wraps 9 minus 2", 1'b0, 1'b0, 1'b0, 1'b1, 4'd0, 2'd0, 2'd2, model_value);
        apply_cycle("underflow wraps 7 minus 3", 1'b0, 1'b0, 1'b0, 1'b1, 4'd0, 2'd0, 2'd3, model_value);
        apply_cycle("underflow wraps 4 minus 3", 1'b0, 1'b0, 1'b0, 1'b1, 4'd0, 2'd0, 2'd3, model_value);
        apply_cycle("underflow wraps 1 minus 1 to 0", 1'b0, 1'b0, 1'b0, 1'b1, 4'd0, 2'd0, 2'd1, model_value);
        apply_cycle("underflow wraps 0 minus 1 to 10", 1'b0, 1'b0, 1'b0, 1'b1, 4'd0, 2'd0, 2'd1, model_value);

        apply_cycle("reinit has priority over operations", 1'b0, 1'b1, 1'b1, 1'b1, 4'd4, 2'd3, 2'd3, model_value);
        apply_cycle("hold after reinit", 1'b0, 1'b0, 1'b0, 1'b0, 4'd4, 2'd0, 2'd0, model_value);
        apply_cycle("reinit to zero", 1'b0, 1'b1, 1'b0, 1'b0, 4'd0, 2'd0, 2'd0, model_value);
        apply_cycle("increment from zero by three", 1'b0, 1'b0, 1'b1, 1'b0, 4'd0, 2'd3, 2'd0, model_value);
        apply_cycle("decrement from three by three to zero", 1'b0, 1'b0, 1'b0, 1'b1, 4'd0, 2'd0, 2'd3, model_value);

        $display("TESTS PASSED");
        $finish;
    end

endmodule
