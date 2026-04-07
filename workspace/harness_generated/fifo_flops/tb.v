`timescale 1ns/1ps

module tb;

    localparam integer DEPTH = 13;

    reg        clk;
    reg        rst;
    wire       push_ready;
    reg        push_valid;
    reg        pop_ready;
    wire       pop_valid;
    wire       full;
    wire       full_next;
    wire       empty;
    wire       empty_next;
    reg  [7:0] push_data;
    wire [7:0] pop_data;
    wire [3:0] slots;
    wire [3:0] slots_next;
    wire [3:0] items;
    wire [3:0] items_next;

    integer model_count;
    integer i;
    reg [7:0] model_mem [0:DEPTH-1];

    fifo_flops dut (
        .clk(clk),
        .rst(rst),
        .push_ready(push_ready),
        .push_valid(push_valid),
        .pop_ready(pop_ready),
        .pop_valid(pop_valid),
        .full(full),
        .full_next(full_next),
        .empty(empty),
        .empty_next(empty_next),
        .push_data(push_data),
        .pop_data(pop_data),
        .slots(slots),
        .slots_next(slots_next),
        .items(items),
        .items_next(items_next)
    );

    function automatic integer expected_push_ready_i;
        input integer count_i;
        begin
            expected_push_ready_i = (count_i < DEPTH);
        end
    endfunction

    function automatic integer expected_pop_valid_i;
        input integer count_i;
        input integer push_valid_i;
        input integer pop_ready_i;
        begin
            if (count_i > 0) begin
                expected_pop_valid_i = 1;
            end else begin
                expected_pop_valid_i = push_valid_i && pop_ready_i;
            end
        end
    endfunction

    function automatic integer expected_push_beat_i;
        input integer count_i;
        input integer push_valid_i;
        begin
            expected_push_beat_i = push_valid_i && (count_i < DEPTH);
        end
    endfunction

    function automatic integer expected_pop_beat_i;
        input integer count_i;
        input integer push_valid_i;
        input integer pop_ready_i;
        begin
            expected_pop_beat_i = pop_ready_i && expected_pop_valid_i(count_i, push_valid_i, pop_ready_i);
        end
    endfunction

    function automatic integer expected_next_count_i;
        input integer count_i;
        input integer push_valid_i;
        input integer pop_ready_i;
        begin
            expected_next_count_i = count_i + expected_push_beat_i(count_i, push_valid_i) - expected_pop_beat_i(count_i, push_valid_i, pop_ready_i);
        end
    endfunction

    task automatic fail;
        input [8*160-1:0] msg;
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    task automatic clear_model;
        begin
            model_count = 0;
            for (i = 0; i < DEPTH; i = i + 1) model_mem[i] = 8'h00;
        end
    endtask

    task automatic check_reset_state;
        input [8*160-1:0] label;
        begin
            #1;
            if (push_ready !== 1'b1) fail({label, ": push_ready should be 1 after reset"});
            if (pop_valid !== 1'b0) fail({label, ": pop_valid should be 0 after reset"});
            if (empty !== 1'b1) fail({label, ": empty should be 1 after reset"});
            if (full !== 1'b0) fail({label, ": full should be 0 after reset"});
            if (items !== 4'd0) fail({label, ": items should be 0 after reset"});
            if (slots !== 4'd13) fail({label, ": slots should be 13 after reset"});
        end
    endtask

    task automatic check_outputs;
        input [8*160-1:0] label;
        integer exp_push_ready;
        integer exp_pop_valid;
        integer exp_next_count;
        integer strict_pop_check;
        reg [7:0] exp_pop_data;
        reg [3:0] exp_slots;
        reg [3:0] exp_slots_next;
        begin
            #1;
            exp_push_ready = expected_push_ready_i(model_count);
            exp_pop_valid = expected_pop_valid_i(model_count, push_valid, pop_ready);
            exp_next_count = expected_next_count_i(model_count, push_valid, pop_ready);
            exp_pop_data = (model_count > 0) ? model_mem[0] : push_data;
            exp_slots = DEPTH - model_count;
            exp_slots_next = DEPTH - exp_next_count;
            strict_pop_check = !((model_count == 0) && push_valid && !pop_ready);

            if (push_ready !== exp_push_ready[0]) begin
                $display("FAIL: %0s push_ready expected %0d got %0d", label, exp_push_ready, push_ready);
                $finish;
            end
            if (strict_pop_check && pop_valid !== exp_pop_valid[0]) begin
                $display("FAIL: %0s pop_valid expected %0d got %0d", label, exp_pop_valid, pop_valid);
                $finish;
            end
            if (strict_pop_check && exp_pop_valid && pop_data !== exp_pop_data) begin
                $display("FAIL: %0s pop_data expected 0x%02x got 0x%02x", label, exp_pop_data, pop_data);
                $finish;
            end
            if (full !== (model_count == DEPTH)) begin
                $display("FAIL: %0s full mismatch", label);
                $finish;
            end
            if (empty !== (model_count == 0)) begin
                $display("FAIL: %0s empty mismatch", label);
                $finish;
            end
            if (items !== model_count[3:0]) begin
                $display("FAIL: %0s items expected %0d got %0d", label, model_count, items);
                $finish;
            end
            if (slots !== exp_slots) begin
                $display("FAIL: %0s slots expected %0d got %0d", label, DEPTH - model_count, slots);
                $finish;
            end
            if (full_next !== (exp_next_count == DEPTH)) begin
                $display("FAIL: %0s full_next mismatch", label);
                $finish;
            end
            if (empty_next !== (exp_next_count == 0)) begin
                $display("FAIL: %0s empty_next mismatch", label);
                $finish;
            end
            if (items_next !== exp_next_count[3:0]) begin
                $display("FAIL: %0s items_next expected %0d got %0d", label, exp_next_count, items_next);
                $finish;
            end
            if (slots_next !== exp_slots_next) begin
                $display("FAIL: %0s slots_next expected %0d got %0d", label, DEPTH - exp_next_count, slots_next);
                $finish;
            end
        end
    endtask

    task automatic apply_model_update;
        integer push_beat;
        integer pop_beat;
        integer tail_index;
        integer j;
        begin
            push_beat = expected_push_beat_i(model_count, push_valid);
            pop_beat = expected_pop_beat_i(model_count, push_valid, pop_ready);

            if (rst) begin
                clear_model();
            end else if (model_count == 0) begin
                if (push_beat && !pop_beat) begin
                    model_mem[0] = push_data;
                    model_count = 1;
                end
            end else begin
                if (pop_beat) begin
                    for (j = 0; j < model_count - 1; j = j + 1) model_mem[j] = model_mem[j + 1];
                end
                if (push_beat) begin
                    tail_index = model_count - pop_beat;
                    model_mem[tail_index] = push_data;
                end
                model_count = model_count + push_beat - pop_beat;
            end
        end
    endtask

    task automatic apply_cycle;
        input [8*160-1:0] label;
        input rst_i;
        input push_valid_i;
        input pop_ready_i;
        input [7:0] push_data_i;
        begin
            @(negedge clk);
            rst = rst_i;
            push_valid = push_valid_i;
            pop_ready = pop_ready_i;
            push_data = push_data_i;

            if (!rst_i) check_outputs({label, " (before edge)"});

            @(posedge clk);
            apply_model_update();

            if (rst_i) begin
                check_reset_state({label, " (after edge)"});
            end else begin
                check_outputs({label, " (after edge)"});
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        clear_model();
        rst = 1'b0;
        push_valid = 1'b0;
        pop_ready = 1'b0;
        push_data = 8'h00;

        apply_cycle("synchronous reset", 1'b1, 1'b0, 1'b0, 8'h00);
        apply_cycle("idle after reset", 1'b0, 1'b0, 1'b0, 8'h00);
        apply_cycle("empty bypass transfer", 1'b0, 1'b1, 1'b1, 8'hA1);
        apply_cycle("empty idle after bypass", 1'b0, 1'b0, 1'b0, 8'h00);
        apply_cycle("store first word while consumer stalled", 1'b0, 1'b1, 1'b0, 8'h11);
        apply_cycle("hold buffered data with consumer stalled", 1'b0, 1'b0, 1'b0, 8'h00);
        apply_cycle("pop buffered first word", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("empty again", 1'b0, 1'b0, 1'b0, 8'h00);
        apply_cycle("enqueue 21", 1'b0, 1'b1, 1'b0, 8'h21);
        apply_cycle("enqueue 22", 1'b0, 1'b1, 1'b0, 8'h22);
        apply_cycle("enqueue 23", 1'b0, 1'b1, 1'b0, 8'h23);
        apply_cycle("dequeue 21", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("simultaneous pop and push keeps depth", 1'b0, 1'b1, 1'b1, 8'h24);
        apply_cycle("dequeue 23", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("dequeue 24", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("fill 01", 1'b0, 1'b1, 1'b0, 8'h01);
        apply_cycle("fill 02", 1'b0, 1'b1, 1'b0, 8'h02);
        apply_cycle("fill 03", 1'b0, 1'b1, 1'b0, 8'h03);
        apply_cycle("fill 04", 1'b0, 1'b1, 1'b0, 8'h04);
        apply_cycle("fill 05", 1'b0, 1'b1, 1'b0, 8'h05);
        apply_cycle("fill 06", 1'b0, 1'b1, 1'b0, 8'h06);
        apply_cycle("fill 07", 1'b0, 1'b1, 1'b0, 8'h07);
        apply_cycle("fill 08", 1'b0, 1'b1, 1'b0, 8'h08);
        apply_cycle("fill 09", 1'b0, 1'b1, 1'b0, 8'h09);
        apply_cycle("fill 0A", 1'b0, 1'b1, 1'b0, 8'h0A);
        apply_cycle("fill 0B", 1'b0, 1'b1, 1'b0, 8'h0B);
        apply_cycle("fill 0C", 1'b0, 1'b1, 1'b0, 8'h0C);
        apply_cycle("fill 0D reaches full", 1'b0, 1'b1, 1'b0, 8'h0D);
        apply_cycle("attempt push when full", 1'b0, 1'b1, 1'b0, 8'hEE);
        apply_cycle("pop from full", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("push after freeing one slot", 1'b0, 1'b1, 1'b0, 8'hEE);
        apply_cycle("drain 02", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 03", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 04", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 05", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 06", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 07", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 08", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 09", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 0A", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 0B", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 0C", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain 0D", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("drain EE to empty", 1'b0, 1'b0, 1'b1, 8'h00);
        apply_cycle("idle final empty state", 1'b0, 1'b0, 1'b0, 8'h00);

        $display("TESTS PASSED");
        $finish;
    end

endmodule
