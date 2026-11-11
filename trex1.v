module trex_game1 (
    input  wire CLOCK_50,
    input  wire [1:0] KEY,
    output wire VGA_CLK,
    output wire VGA_HS,
    output wire VGA_VS,
    output wire VGA_BLANK_N,
    output wire VGA_SYNC_N,
    output reg [7:0] VGA_R,
    output reg [7:0] VGA_G,
    output reg [7:0] VGA_B
);

    // 1. ESTADOS DO JOGO
    localparam IDLE = 2'b00;
    localparam RUN  = 2'b01;
    localparam JUMP = 2'b10;
    localparam DEAD = 2'b11;

    reg [1:0] state;

    wire reset = ~KEY[0];
    wire jump_button = ~KEY[1];

    // 2. CLOCK DE PIXEL VGA (50 MHz / 2 = 25 MHz)
    reg pixel_clk;
    assign VGA_CLK = pixel_clk;

    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) pixel_clk <= 1'b0;
        else       pixel_clk <= ~pixel_clk;
    end

    // 3. GERADOR DE SINCRONISMO VGA 640x480 @ 60Hz
    reg [9:0] h_count, v_count;
    wire frame_tick = (h_count == 10'd799) && (v_count == 10'd524);

    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else if (h_count == 10'd799) begin
            h_count <= 10'd0;
            if (v_count == 10'd524) v_count <= 10'd0;
            else v_count <= v_count + 1'b1;
        end else begin
            h_count <= h_count + 1'b1;
        end
    end

    assign VGA_HS = ~((h_count >= 10'd656) && (h_count < 10'd752));
    assign VGA_VS = ~((v_count >= 10'd490) && (v_count < 10'd492));
    assign VGA_BLANK_N = (h_count < 10'd640) && (v_count < 10'd480);
    assign VGA_SYNC_N = 1'b0;

    // 4. TRATAMENTO DO BOTAO DE PULO
    reg [1:0] jump_sync;
    reg jump_prev;
    wire jump_event = jump_sync[1] && !jump_prev;

    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            jump_sync <= 2'b00;
            jump_prev <= 1'b0;
        end else begin
            jump_sync <= {jump_sync[0], jump_button};
            jump_prev <= jump_sync[1];
        end
    end

    reg [15:0] score, high_score;
    reg [3:0] score_divider;
    reg [9:0] cactus_x, bird_x;
    reg [5:0] jump_count;
    reg jump_pending;

    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            jump_pending <= 1'b0;
        end else begin
            if (jump_event && state != DEAD) jump_pending <= 1'b1;
            if (state == DEAD) jump_pending <= 1'b0;
            else if (frame_tick && ((state == IDLE) || (state == RUN)) && jump_pending)
                jump_pending <= 1'b0;
        end
    end

    // 5. POSICAO E PULO DO DINOSSAURO
    localparam DINO_X   = 10'd65;
    localparam DINO_W   = 10'd57;
    localparam DINO_H   = 10'd60;
    localparam GROUND_Y = 10'd395;

    reg [9:0] dino_y;
    reg [9:0] jump_height;
    reg [9:0] jump_product;

    always @* begin
        jump_product = ({4'b0000, jump_count} * (10'd40 - {4'b0000, jump_count}));
        jump_height = jump_product / 10'd4;
        dino_y = GROUND_Y - DINO_H - jump_height;
    end

    // 6. DETECCAO DE COLISAO
    wire cactus_collision =
        (cactus_x + 10'd20 > DINO_X + 10'd8) &&
        (cactus_x + 10'd4  < DINO_X + DINO_W - 10'd5) &&
        (dino_y + DINO_H > GROUND_Y - 10'd36);

    wire bird_collision =
        (bird_x + 10'd32 > DINO_X + 10'd8) &&
        (bird_x + 10'd4  < DINO_X + DINO_W - 10'd5) &&
        (dino_y < 10'd295) &&
        (dino_y + DINO_H > 10'd275);

    // 7. MAQUINA DE ESTADOS DO JOGO (FSM)
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cactus_x <= 10'd639;
            bird_x <= 10'd900;
            jump_count <= 6'd0;
            score <= 16'd0;
            high_score <= 16'd0;
            score_divider <= 4'd0;
        end else if (frame_tick) begin
            case (state)
                IDLE: begin
                    cactus_x <= 10'd639;
                    bird_x <= 10'd900;
                    jump_count <= 6'd0;
                    score <= 16'd0;
                    score_divider <= 4'd0;
                    if (jump_pending) begin
                        state <= JUMP;
                        jump_count <= 6'd0;
                    end
                end
                RUN: begin
                    if (cactus_collision || bird_collision) state <= DEAD;
                    else if (jump_pending) begin
                        state <= JUMP;
                        jump_count <= 6'd0;
                    end
                    
                    if (cactus_x <= 10'd5) cactus_x <= 10'd639;
                    else cactus_x <= cactus_x - 10'd4;
                    
                    if (bird_x <= 10'd5) bird_x <= 10'd850;
                    else bird_x <= bird_x - 10'd5;
                    
                    if (score_divider == 4'd9) begin
                        score_divider <= 4'd0;
                        score <= score + 1'b1;
                        if (score + 1'b1 > high_score) high_score <= score + 1'b1;
                    end else begin
                        score_divider <= score_divider + 1'b1;
                    end
                end
                JUMP: begin
                    if (cactus_collision || bird_collision) state <= DEAD;
                    else begin
                        if (jump_count >= 6'd40) begin
                            state <= RUN;
                            jump_count <= 6'd0;
                        end else begin
                            jump_count <= jump_count + 1'b1;
                        end
                        
                        if (cactus_x <= 10'd5) cactus_x <= 10'd639;
                        else cactus_x <= cactus_x - 10'd4;
                        
                        if (bird_x <= 10'd5) bird_x <= 10'd850;
                        else bird_x <= bird_x - 10'd5;
                        
                        if (score_divider == 4'd9) begin
                            score_divider <= 4'd0;
                            score <= score + 1'b1;
                            if (score + 1'b1 > high_score) high_score <= score + 1'b1;
                        end else begin
                            score_divider <= score_divider + 1'b1;
                        end
                    end
                end
                DEAD: state <= DEAD;
                default: state <= IDLE;
            endcase
        end
    end

    wire visible    = (h_count < 10'd640) && (v_count < 10'd480);
    wire night_mode = ((score / 16'd100) % 2) != 0;
    wire ground     = (v_count >= GROUND_Y) && (v_count < GROUND_Y + 2);

    // 8. BITMAP DO T-REX
    function dino_pixel;
        input [4:0] col;
        input [4:0] row;
        reg [18:0] line;
        begin
            case (row)
                5'd0:  line = 19'b0000000000011111110;
                5'd1:  line = 19'b0000000000111111111;
                5'd2:  line = 19'b0000000000111111111;
                5'd3:  line = 19'b0000000000111111111;
                5'd4:  line = 19'b0000000000111111111;
                5'd5:  line = 19'b0000000000111100000;
                5'd6:  line = 19'b0000000000111111100;
                5'd7:  line = 19'b1000000001111000000;
                5'd8:  line = 19'b1000000111111000000;
                5'd9:  line = 19'b1100001111111110000;
                5'd10: line = 19'b1110011111111010000;
                5'd11: line = 19'b1111111111111000000;
                5'd12: line = 19'b1111111111111000000;
                5'd13: line = 19'b0111111111110000000;
                5'd14: line = 19'b0001111111110000000;
                5'd15: line = 19'b0000111111100000000;
                5'd16: line = 19'b0000011111000000000;
                5'd17: line = 19'b0000011001000000000;
                5'd18: line = 19'b00000100001000000000;
                5'd19: line = 19'b0000010000100000000;
                default: line = 19'b0;
            endcase
            dino_pixel = line[18 - col];
        end
    endfunction

    // CORRECAO DE ARGUMENTOS DA FUNCAO (SINAIS CALCULADOS SEPARADAMENTE)
    wire [9:0] dx = h_count - DINO_X;
    wire [9:0] dy = v_count - dino_y;
    wire dino_area = (h_count >= DINO_X) && (h_count < DINO_X + DINO_W) &&
                     (v_count >= dino_y) && (v_count < dino_y + DINO_H);

    wire [9:0] dx_div3 = dx / 3;
    wire [9:0] dy_div3 = dy / 3;
    wire [4:0] dino_col_scaled = dx_div3[4:0];
    wire [4:0] dino_row_scaled = dy_div3[4:0];
    wire dinosaur = dino_area && dino_pixel(dino_col_scaled, dino_row_scaled);

    // 9. BITMAP DO PTERODACTILO
    function bird_pixel;
        input [3:0] col;
        input [3:0] row;
        reg [15:0] line;
        begin
            case (row)
                4'd0:  line = 16'b0000011000000000;
                4'd1:  line = 16'b0000011100000000;
                4'd2:  line = 16'b0000011110000000;
                4'd3:  line = 16'b0000011111000000;
                4'd4:  line = 16'b1111111111100000;
                4'd5:  line = 16'b0111111111111000;
                4'd6:  line = 16'b0001111111111100;
                4'd7:  line = 16'b0000011111100000;
                4'd8:  line = 16'b0000001111000000;
                4'd9:  line = 16'b0000000110000000;
                default: line = 16'b0;
            endcase
            bird_pixel = line[15 - col];
        end
    endfunction

    wire [9:0] bx = h_count - bird_x;
    wire [9:0] by = v_count - 10'd275;
    wire bird_area = (h_count >= bird_x) && (h_count < bird_x + 10'd32) &&
                     (v_count >= 10'd275) && (v_count < 10'd295);

    wire [9:0] bx_div2 = bx / 2;
    wire [9:0] by_div2 = by / 2;
    wire [3:0] bird_col_scaled = bx_div2[3:0];
    wire [3:0] bird_row_scaled = by_div2[3:0];
    wire bird = bird_area && bird_pixel(bird_col_scaled, bird_row_scaled);

    // 10. CACTO
    wire [9:0] cx = h_count - cactus_x;
    wire [9:0] cy = v_count - (GROUND_Y - 10'd36);
    wire cactus_area = (h_count >= cactus_x) && (h_count < cactus_x + 10'd24) &&
                       (v_count >= GROUND_Y - 10'd36) && (v_count < GROUND_Y);

    wire cactus_trunk   = (cx >= 10'd9)  && (cx < 10'd15);
    wire cactus_left_h  = (cx >= 10'd3)  && (cx < 10'd9)  && (cy >= 10'd18) && (cy < 10'd22);
    wire cactus_left_v  = (cx >= 10'd3)  && (cx < 10'd7)  && (cy >= 10'd10) && (cy < 10'd22);
    wire cactus_right_h = (cx >= 10'd15) && (cx < 10'd21) && (cy >= 10'd12) && (cy < 10'd16);
    wire cactus_right_v = (cx >= 10'd17) && (cx < 10'd21) && (cy >= 10'd4)  && (cy < 10'd16);

    wire cactus = cactus_area && (cactus_trunk || cactus_left_h || cactus_left_v || cactus_right_h || cactus_right_v);

    // 11. FONTE DOS DIGITOS
    function digit_pixel;
        input [3:0] digit;
        input [1:0] col;
        input [2:0] row;
        reg [14:0] bits;
        begin
            case (digit)
                0: bits = 15'b111101101101111;
                1: bits = 15'b010010010010010;
                2: bits = 15'b111001111100111;
                3: bits = 15'b111001111001111;
                4: bits = 15'b101101111001001;
                5: bits = 15'b111100111001111;
                6: bits = 15'b111100111101111;
                7: bits = 15'b111001010010010;
                8: bits = 15'b111101111101111;
                9: bits = 15'b111101111001111;
                default: bits = 15'b0;
            endcase
            digit_pixel = bits[14 - (row * 3 + col)];
        end
    endfunction

    // 12. FONTE DAS LETRAS DO GAME OVER
    function gameover_pixel;
        input [3:0] letter_idx;
        input [2:0] col;
        input [2:0] row;
        reg [34:0] bits;
        begin
            case (letter_idx)
                0: bits = {5'b01110,5'b10001,5'b10000,5'b10000,5'b10011,5'b10001,5'b01110};
                1: bits = {5'b01110,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
                2: bits = {5'b10001,5'b11011,5'b10101,5'b10101,5'b10001,5'b10001,5'b10001};
                3: bits = {5'b11111,5'b10000,5'b10000,5'b11110,5'b10000,5'b10000,5'b11111};
                4: bits = 35'b0;
                5: bits = {5'b01110,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01110};
                6: bits = {5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01010,5'b00100};
                7: bits = {5'b11111,5'b10000,5'b10000,5'b11110,5'b10000,5'b10000,5'b11111};
                8: bits = {5'b11110,5'b10001,5'b10001,5'b11110,5'b10100,5'b10010,5'b10001};
                default: bits = 35'b0;
            endcase
            gameover_pixel = bits[34 - (row * 5 + col)];
        end
    endfunction

    // 13. PLACAR SUPERIOR "HI [HIGH_SCORE] [SCORE]"
    wire hi_text = ((h_count >= 10'd420) && (h_count < 10'd423) && (v_count >= 10'd20) && (v_count < 10'd30)) ||
                   ((h_count >= 10'd427) && (h_count < 10'd430) && (v_count >= 10'd20) && (v_count < 10'd30)) ||
                   ((h_count >= 10'd423) && (h_count < 10'd427) && (v_count >= 10'd24) && (v_count < 10'd26)) ||
                   ((h_count >= 10'd434) && (h_count < 10'd437) && (v_count >= 10'd20) && (v_count < 10'd30));

    wire [9:0] hs_rel_x = h_count - 10'd445;
    wire [2:0] hs_idx = hs_rel_x / 10'd10;
    reg [3:0] hs_digit;
    always @* begin
        case (hs_idx)
            0: hs_digit = (high_score / 16'd10000) % 10;
            1: hs_digit = (high_score / 16'd1000) % 10;
            2: hs_digit = (high_score / 16'd100) % 10;
            3: hs_digit = (high_score / 16'd10) % 10;
            4: hs_digit = high_score % 10;
            default: hs_digit = 4'd0;
        endcase
    end

    wire [9:0] hs_sub_x = hs_rel_x % 10'd10;
    wire [1:0] hs_col = hs_sub_x[2:1];
    wire [9:0] hs_sub_y = v_count - 10'd20;
    wire [2:0] hs_row = hs_sub_y[3:1];
    wire hs_pixel = (h_count >= 10'd445) && (h_count < 10'd495) &&
                    (v_count >= 10'd20) && (v_count < 10'd30) &&
                    (hs_sub_x < 10'd6) &&
                    digit_pixel(hs_digit, hs_col, hs_row);

    wire [9:0] sc_rel_x = h_count - 10'd510;
    wire [2:0] sc_idx = sc_rel_x / 10'd10;
    reg [3:0] sc_digit;
    always @* begin
        case (sc_idx)
            0: sc_digit = (score / 16'd10000) % 10;
            1: sc_digit = (score / 16'd1000) % 10;
            2: sc_digit = (score / 16'd100) % 10;
            3: sc_digit = (score / 16'd10) % 10;
            4: sc_digit = score % 10;
            default: sc_digit = 4'd0;
        endcase
    end

    wire [9:0] sc_sub_x = sc_rel_x % 10'd10;
    wire [1:0] sc_col = sc_sub_x[2:1];
    wire [9:0] sc_sub_y = v_count - 10'd20;
    wire [2:0] sc_row = sc_sub_y[3:1];
    wire score_pixel = (h_count >= 10'd510) && (h_count < 10'd560) &&
                       (v_count >= 10'd20) && (v_count < 10'd30) &&
                       (sc_sub_x < 10'd6) &&
                       digit_pixel(sc_digit, sc_col, sc_row);

    // 14. TEXTO GAME OVER E BOTAO RESTART
    wire [9:0] go_rel_x = h_count - 10'd220;
    wire [3:0] go_letter_idx = go_rel_x / 10'd22;
    wire [9:0] go_sub_x = (go_rel_x % 10'd22) / 3;
    wire [2:0] go_col = go_sub_x[2:0];
    wire [9:0] go_sub_y = (v_count - 10'd150) / 4;
    wire [2:0] go_row = go_sub_y[2:0];
    wire game_over_text = (state == DEAD) &&
                          (h_count >= 10'd220) && (h_count < 10'd418) &&
                          (v_count >= 10'd150) && (v_count < 10'd178) &&
                          (go_col < 5) && (go_row < 7) &&
                          (go_letter_idx < 9) &&
                          gameover_pixel(go_letter_idx, go_col, go_row);

    wire restart_box = (state == DEAD) &&
                       (h_count >= 10'd300) && (h_count < 10'd340) &&
                       (v_count >= 10'd200) && (v_count < 10'd240);
    wire [9:0] rx = h_count - 10'd300;
    wire [9:0] ry = v_count - 10'd200;
    wire restart_icon = restart_box &&
        (((rx >= 10'd8 && rx < 10'd32) && (ry >= 10'd7 && ry < 10'd12)) ||
         ((rx >= 10'd8 && rx < 10'd14) && (ry >= 10'd7 && ry < 10'd30)) ||
         ((rx >= 10'd8 && rx < 10'd28) && (ry >= 10'd25 && ry < 10'd31)) ||
         ((rx >= 10'd23 && rx < 10'd32) && (ry >= 10'd20 && ry < 10'd31)));

    wire main_element = dinosaur || cactus || bird || ground || hi_text || hs_pixel || score_pixel;

    // 15. SAIDA DE CORES VGA
    always @* begin
        if (!visible) begin
            VGA_R = 8'h00; VGA_G = 8'h00; VGA_B = 8'h00;
        end else if (game_over_text || restart_icon) begin
            VGA_R = night_mode ? 8'hFF : 8'h30;
            VGA_G = night_mode ? 8'hFF : 8'h30;
            VGA_B = night_mode ? 8'hFF : 8'h30;
        end else if (night_mode) begin
            if (main_element) begin
                VGA_R = 8'hFF; VGA_G = 8'hFF; VGA_B = 8'hFF;
            end else begin
                VGA_R = 8'h00; VGA_G = 8'h00; VGA_B = 8'h00;
            end
        end else begin
            if (main_element) begin
                VGA_R = 8'h30; VGA_G = 8'h30; VGA_B = 8'h30;
            end else begin
                VGA_R = 8'hFF; VGA_G = 8'hFF; VGA_B = 8'hFF;
            end
        end
    end

    wire [4:0] me_dino_13 = 5'd13;

endmodule
