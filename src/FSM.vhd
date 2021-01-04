----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: FSM - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FSM is
    port(
        BEGIN_CYCLE, CLK, RESET_L : IN std_logic;  
        READY_BTN, POINT_SCORED : IN std_logic;
        DONE : OUT std_logic;
        IN_SERVE, IN_WAIT, IN_MOVE_P1, IN_MOVE_P2, IN_MOVE_BALL, IN_UPDATE_SCORE : OUT std_logic
    );
end entity;

architecture arch of FSM is
    type state is (S_SERVE, S_WAIT, S_MOVE_P1, S_MOVE_P2, S_MOVE_BALL, S_UPDATE_SCORE);
   
    signal cur_state : state := S_SERVE;
    signal state_bus : std_logic_vector(5 downto 0); --used to output which state is active
    signal complete : std_logic := '0'; --each state (except S_SERVE) goes through two parts, one when its not complete and one when it is complete
    signal single_loop : std_logic := '1'; --signal prevents FSM from looping through more than once during a single processing time

begin
    DONE <= complete; --this signal helps the datapath store the value that was just computed in the current state
     
    FSM : process(BEGIN_CYCLE, CLK, RESET_L, cur_state, READY_BTN, single_loop, POINT_SCORED)
    begin
        
        if(RESET_L = '0') then
            complete <= '0';
            cur_state <= S_SERVE;
        elsif(rising_edge(CLK)) then
            --game has yet to start and press ready_btn to start
            if(cur_state = S_SERVE and READY_BTN = '1') then 
                cur_state <= S_WAIT;
                
            elsif(cur_state = S_WAIT) then
                if(BEGIN_CYCLE = '1' and single_loop = '1') then
                    single_loop <= '0';
                    complete <= '0'; --only allow cycle once per each processing time block (AKA when not in display_view)
                    cur_state <= S_MOVE_P1; --transition to move paddle 1
                elsif(BEGIN_CYCLE = '0') then
                    single_loop <= '1'; --no longer in processing time so reset single_loop back to '1'
                end if;
            elsif(cur_state = S_MOVE_P1) then
                if(complete = '1') then
                    cur_state <= S_MOVE_P2; --transition to move paddle 2
                    complete <= '0';
                else
                    complete <= '1';
                end if;
                
            elsif(cur_state = S_MOVE_P2) then
                if(complete = '1') then
                    cur_state <= S_MOVE_BALL; --transition to move ball
                    complete <= '0';
                else
                    complete <= '1';
                end if;
                
            elsif(cur_state = S_MOVE_BALL) then
                if(complete = '1') then
                    if(POINT_SCORED = '1') then
                        cur_state <= S_UPDATE_SCORE; --transition to update the score if a point was scored
                    else
                        cur_state <= S_WAIT; --transition back to waiting (a single cycle is now complete)
                    end if;
                    complete <= '0';
                else
                    complete <= '1';
                end if;
            elsif(cur_state = S_UPDATE_SCORE) then
                if(complete = '1') then
                    cur_state <= S_SERVE; --transition to serve state after updating the score
                    complete <= '0';
                else
                    complete <= '1';
                end if;
            end if;
        end if;
    end process;
    
    --output signals accordingly depending on what state is active
    state_bus <= "100000" when (cur_state = S_SERVE) else
                 "010000" when (cur_state = S_WAIT) else
                 "001000" when (cur_state = S_MOVE_P1) else
                 "000100" when (cur_state = S_MOVE_P2) else
                 "000010" when (cur_state = S_MOVE_BALL) else
                 "000001" when (cur_state = S_UPDATE_SCORE);
    
    IN_SERVE <= state_bus(5);
    IN_WAIT <= state_bus(4);
    IN_MOVE_P1 <= state_bus(3);
    IN_MOVE_P2 <= state_bus(2);
    IN_MOVE_BALL <= state_bus(1);
    IN_UPDATE_SCORE <= state_bus(0);
    
end architecture;
