----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: Datapath - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Datapath is
    port(
        CLK, RESET_L : IN std_logic;
        P1_INPUT, P2_INPUT : IN std_logic_vector(1 downto 0); --Paddle input as 2-bit vector
        IN_MOVE_P1, IN_MOVE_P2, IN_MOVE_BALL, IN_SERVE, IN_WAIT, IN_UPDATE_SCORE : IN std_logic; --signals sent from FSM to indicate what state is active
        P1_BOUNCE, P2_BOUNCE, DONE : IN std_logic; --DONE is used to allow for storing the value computed in the current state
        POINT_SCORED : OUT std_logic; --signal sent to FSM to correctly transition to UPDATE_SCORE
        O_BALL_ADDR, O_P1_ADDR, O_P2_ADDR : OUT std_logic_vector(13 downto 0);
        O_P1_SCORE, O_P2_SCORE : OUT std_logic_vector(3 downto 0)
    );
end entity;

architecture arch of Datapath is
    -- address format: y, x (8 bits each to accomodate for using 2 4-bit CLA's in the ALU)
    signal ball_addr : std_logic_vector(15 downto 0) := "00100101" & "00000101";
    signal p1_addr : std_logic_vector(15 downto 0) := "00100011" & "00000010";
    signal p2_addr : std_logic_vector(15 downto 0) := "00100011" & "01100001";
    
    signal p1_score, p2_score : std_logic_vector(3 downto 0) := "0000";
    
    signal ball_velocity : std_logic_vector(15 downto 0) := "00000001" & "00000001";
    signal blue_point, red_point : std_logic := '0';
    signal ball_x_dir, ball_y_dir : std_logic := '0'; --0 means add (vel is positive), 1 means subtract (vel is negative)
        
    component ALU is
        port(
            A, B : IN std_logic_vector(7 downto 0);
            SUB : IN std_logic;
            OUTPUT : OUT std_logic_vector(7 downto 0)
        );
    end component;
    
    signal reg_A, reg_B, reg_C : std_logic_vector(15 downto 0);
    signal reg_SUB_x, reg_SUB_y : std_logic;
    signal reg_p1_rebound, reg_p2_rebound, ball_correct : std_logic := '0';
    
begin
    --signal '1' if the ball has not yet been corrected and it is indeed on the same location as paddle1
    reg_p1_rebound <= '1' when (P1_BOUNCE = '1' and ball_correct = '0') else
                      '0' when (ball_correct = '1');
    
    --signal '1' if the ball has not yet been corrected and it is indeed on the same location as paddle2
    reg_p2_rebound <= '1' when (P2_BOUNCE = '1' and ball_correct = '0') else
                      '0' when (ball_correct = '1');
    
    --8-bit ALU for the x position
    uALU_x : ALU port map(A=>reg_A(7 downto 0), 
                          B=>reg_B(7 downto 0),
                          SUB=>reg_SUB_x,
                          OUTPUT=>reg_C(7 downto 0));
    --8-bit ALU for the y position
    uALU_y : ALU port map(A=>reg_A(15 downto 8),
                          B=>reg_B(15 downto 8),
                          SUB=>reg_SUB_y,
                          OUTPUT=>reg_C(15 downto 8));

    --process statement to handle what computations to perform given what signals (states) are triggered
    COMPUTE : process(CLK, RESET_L, IN_MOVE_P1, IN_MOVE_P2, IN_MOVE_BALL, IN_UPDATE_SCORE, blue_point, red_point, reg_p2_rebound, p1_score, p2_score,
                      P1_INPUT, P2_INPUT, ball_x_dir, ball_y_dir, DONE, ball_addr, p1_addr, p2_addr, ball_velocity, reg_C, reg_p1_rebound)
    begin
        if(RESET_L = '0') then
            --reset positions of objects and the score
            ball_x_dir <= '0';
            blue_point <= '0';
            red_point <= '0';
            ball_correct <= '0';
            ball_addr <= "00100101" & "00000101";
            p1_addr <= "00100011" & "00000010";
            p2_addr <= "00100011" & "01100001";
            p1_score <= "0000";
            p2_score <= "0000";
        elsif(rising_edge(CLK)) then
            --#1 COMPUTE THE PADDLE 1 POSITION
            if(IN_MOVE_P1 = '1') then
                if(DONE = '1') then --store the value
                    --prevent paddle from going off screen
                    if(p1_addr(15 downto 8) = "00000000" and reg_SUB_y = '1') then
                        p1_addr(15 downto 8) <= (others=>'0');
                    elsif(p1_addr(15 downto 8) = "01000101" and reg_SUB_y = '0') then
                        p1_addr(15 downto 8) <= "01000101";
                    else
                        p1_addr <= reg_C;
                    end if;
                else --set up the computation
                    reg_A <= p1_addr;
                    reg_B <= (8=>P1_INPUT(1) OR P1_INPUT(0), others=>'0');
                    reg_SUB_y <= P1_INPUT(1);
                    reg_SUB_x <= '0';
                end if;
            --#2 COMPUTE THE PADDLE 2 POSITION
            elsif(IN_MOVE_P2 = '1') then
                if(DONE = '1') then --store the value
                    --prevent paddle from going off screen
                    if(p2_addr(15 downto 8) = "00000000" and reg_SUB_y = '1') then
                        p2_addr(15 downto 8) <= (others=>'0');
                    elsif(p2_addr(15 downto 8) = "01000101" and reg_SUB_y = '0') then
                        p2_addr(15 downto 8) <= "01000101";
                    else
                        p2_addr <= reg_C;
                    end if;
                else --set up the computation
                    reg_A <= p2_addr;
                    reg_B <= (8=>P2_INPUT(1) OR P2_INPUT(0), others=>'0');
                    reg_SUB_y <= P2_INPUT(1);
                    reg_SUB_x <= '0';
                end if;
            --#3 COMPUTE THE BALL'S POSITION
            elsif(IN_MOVE_BALL = '1') then
                if(DONE = '1') then --store the value
                    --handle y position
                    if(ball_addr(15 downto 8) = "00000000" and reg_SUB_y = '1') then --hit top of screen
                        ball_addr(15 downto 8) <= "00000000";
                        ball_y_dir <= '0';
                    elsif(ball_addr(15 downto 8) = "01001010" and reg_SUB_y = '0') then --hit bottom of screen
                        ball_addr(15 downto 8) <= "01001010";
                        ball_y_dir <= '1';
                    --perform a form of "english" on the ball from paddle 1 or paddle 2 
                    --(move ball y direction in same direction as the paddle if the paddle is moving on contact)
                    elsif(reg_p1_rebound = '1') then
                        ball_y_dir <= P1_INPUT(1) OR (reg_SUB_y AND NOT P1_INPUT(0));
                    elsif(reg_p2_rebound = '1') then
                        ball_y_dir <= P2_INPUT(1) OR (reg_SUB_y AND NOT P2_INPUT(0));
                    else
                        ball_addr(15 downto 8) <= reg_C(15 downto 8);
                    end if;
                    
                    --handle x position
                    if(ball_addr(7 downto 0) = "00000000") then --blue scores! (hit left of screen)
                        blue_point <= '1';
                    elsif(ball_addr(7 downto 0) = "01100011") then --red scores! (hit right of screen)
                        red_point <= '1';
                    elsif(reg_p1_rebound = '1') then --paddle 1 hit ball
                        ball_x_dir <= '0'; --send to the right
                        ball_addr(7 downto 0) <= "00000011";
                        ball_correct <= '1';
                    elsif(reg_p2_rebound = '1') then --paddle 2 hit ball
                        ball_x_dir <= '1'; --send to the left
                        ball_addr(7 downto 0) <= "01100000";
                        ball_correct <= '1';
                    else
                        ball_addr(7 downto 0) <= reg_C(7 downto 0);
                        red_point <= '0';
                        blue_point <= '0';
                        ball_correct <= '0'; --if paddle 1 or paddle 2 did not hit the ball, the ball must be correct (used in conjunction with P1_BOUNCE, P2_BOUNCE signals)
                    end if;
                    
                else --set up computation
                    reg_A <= ball_addr;
                    reg_B <= ball_velocity;
                    reg_SUB_y <= ball_y_dir;
                    reg_SUB_x <= ball_x_dir;
                end if;
            elsif(IN_UPDATE_SCORE = '1') then
            
                if(DONE = '1') then --store value and reset paddles to orignal position
                    p1_addr <= "00100011" & "00000010";
                    p2_addr <= "00100011" & "01100001";
                    
                    if(blue_point = '1') then
                        p2_score <= reg_C(3 downto 0);
                        ball_addr <= "00100101" & "01011110";
                        ball_x_dir <= '1';
                    elsif(red_point = '1') then
                        p1_score <= reg_C(3 downto 0);
                        ball_addr <= "00100101" & "00000101";
                        ball_x_dir <= '0';
                    end if;
                    
                else --set up computation
                    if(blue_point = '1') then --add 1 to player 2 score
                        reg_A <= "000000000000" & p2_score;
                        reg_B <= (0=>'1', others=>'0');
                        reg_SUB_x <= '0';
                    elsif(red_point = '1') then --add 1 to player 1 score
                        reg_A <= "000000000000" & p1_score;
                        reg_B <= (0=>'1', others=>'0');
                        reg_SUB_x <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    --reformat address from 8-bit values for y, x -> 7-bit values for y, x
    O_BALL_ADDR <= ball_addr(14 downto 8) & ball_addr(6 downto 0);
    O_P1_ADDR <= p1_addr(14 downto 8) & p1_addr(6 downto 0);
    O_P2_ADDR <= p2_addr(14 downto 8) & p2_addr(6 downto 0);
    
    O_P1_SCORE <= p1_score;
    O_P2_SCORE <= p2_score;
    
    POINT_SCORED <= red_point or blue_point;
end architecture;