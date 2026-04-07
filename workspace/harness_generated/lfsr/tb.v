`timescale 1ns/1ps

module tb;

    reg clk;
    reg rst;
    reg reinit;
    reg advance;
    wire out;
    reg [4:0] initial_state;
    reg [4:0] taps;
    wire [4:0] out_state;
    reg [4:0] model_state;

    lfsr dut (
        .clk(clk),
        .rst(rst),
        .reinit(reinit),
        .advance(advance),
        .out(out),
        .initial_state(initial_state),
        .taps(taps),
        .out_state(out_state)
    );

    function automatic feedback_bit;
        input [4:0] state_i;
        input [4:0] taps_i;
        begin
            feedback_bit = ^(state_i & taps_i);
        end
    endfunction

    function automatic [4:0] next_state;
        input [4:0] state_i;
        input rst_i;
        input reinit_i;
        input advance_i;
        input [4:0] initial_state_i;
        input [4:0] taps_i;
        begin
            if (rst_i || reinit_i) begin
                next_state = initial_state_i;
            end else if (advance_i) begin
                next_state = {state_i[3:0], feedback_bit(state_i, taps_i)};
            end else begin
                next_state = state_i;
            end
        end
    endfunction

    task automatic fail(input [8*160-1:0] msg);
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    task automatic check_now(input [8*160-1:0] label, input [4:0] expected_state);
        begin
            #1;
            if (out_state !== expected_state) begin
                $display("FAIL: %0s expected state %05b got %05b", label, expected_state, out_state);
                $finish;
            end
            if (out !== expected_state[0]) fail("out should equal out_state[0]");
        end
    endtask

    task automatic apply_cycle(
        input [8*160-1:0] label,
        input rst_i,
        input reinit_i,
        input advance_i,
        input [4:0] initial_state_i,
        input [4:0] taps_i
    );
        begin
            @(negedge clk);
            rst = rst_i;
            reinit = reinit_i;
            advance = advance_i;
            initial_state = initial_state_i;
            taps = taps_i;
            check_now({label, " before edge"}, model_state);
            @(posedge clk);
            model_state = next_state(model_state, rst_i, reinit_i, advance_i, initial_state_i, taps_i);
            check_now({label, " after edge"}, model_state);
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        model_state = 5'b10101;
        rst = 1'b1;
        reinit = 1'b0;
        advance = 1'b0;
        initial_state = 5'b10101;
        taps = 5'b10110;

        @(posedge clk);
        model_state = 5'b10101;
        check_now("reset load", model_state);

        apply_cycle("hold", 1'b0, 1'b0, 1'b0, 5'b00111, 5'b10110);
        apply_cycle("advance once", 1'b0, 1'b0, 1'b1, 5'b00111, 5'b10110);
        apply_cycle("advance twice", 1'b0, 1'b0, 1'b1, 5'b00111, 5'b10110);
        apply_cycle("reinit", 1'b0, 1'b1, 1'b1, 5'b01110, 5'b10110);
        apply_cycle("advance after reinit", 1'b0, 1'b0, 1'b1, 5'b01110, 5'b10110);
        apply_cycle("reset wins", 1'b1, 1'b1, 1'b1, 5'b11001, 5'b01011);
        apply_cycle("new taps advance", 1'b0, 1'b0, 1'b1, 5'b11001, 5'b01011);
        apply_cycle("hold after advance", 1'b0, 1'b0, 1'b0, 5'b11001, 5'b01011);

        $display("TESTS PASSED");
        $finish;
    end

endmodule
