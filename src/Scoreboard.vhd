----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: Scoreboard - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Scoreboard is
    port(
        CLK : IN std_logic;
        P1_SCORE, P2_SCORE : IN std_logic_vector(3 downto 0); --stored in regular hex fashion
        SEG : OUT std_logic_vector(6 downto 0);
        DIGIT_P1_1, DIGIT_P1_0, DIGIT_P2_1, DIGIT_P2_0 : OUT std_logic
    );
end entity;

architecture arch of Scoreboard is
    signal seg_p1_1, seg_p1_0, seg_p2_1, seg_p2_0 : std_logic_vector(6 downto 0); --ABCDEFG
    
    component CLA_4bit is
        port(
            A, B : IN std_logic_vector(3 downto 0);
            C_IN : IN std_logic;
            C_OUT : OUT std_logic;
            SUM : OUT std_logic_vector(3 downto 0)
        );
    end component;
    
    component SevenSegment is
        port(
            BCD_VAL : IN std_logic_vector(3 downto 0);
            A, B, C, D, E, F, G : OUT std_logic
        );
    end component;

    component FlipFlop is
            port(
                CLK, RESET_L, D : IN std_logic;
                Q, Q_INV : OUT std_logic
            );
    end component;
    
    signal p1_bcd, p1_val, p2_bcd, p2_val : std_logic_vector(7 downto 0) := (others=>'0');
    signal digit_counter, inv_digit_counter : std_logic_vector(1 downto 0) := "00";
    
begin
    --PLAYER 1 SCORE
    uADDER1 : CLA_4bit port map(A=>P1_SCORE,
                                B=>"0110",
                                C_IN=>'0',
                                C_OUT=>p1_val(4),
                                SUM=>p1_val(3 downto 0));
    
    --if the value is greater than 9, add 6 to convert to BCD
    p1_bcd <= "0000" & P1_SCORE when (P1_SCORE(3) = '0' or P1_SCORE(3 downto 1) = "100") else
              p1_val;
    
    --ten's place of player 1's score
    uSSP1_1 : SevenSegment port map(BCD_VAL=>p1_bcd(7 downto 4),
                                    A=>seg_p1_1(6),
                                    B=>seg_p1_1(5),
                                    C=>seg_p1_1(4),
                                    D=>seg_p1_1(3),
                                    E=>seg_p1_1(2),
                                    F=>seg_p1_1(1),
                                    G=>seg_p1_1(0));
    --one's place of player 1's score
    uSSP1_0 : SevenSegment port map(BCD_VAL=>p1_bcd(3 downto 0),
                                    A=>seg_p1_0(6),
                                    B=>seg_p1_0(5),
                                    C=>seg_p1_0(4),
                                    D=>seg_p1_0(3),
                                    E=>seg_p1_0(2),
                                    F=>seg_p1_0(1),
                                    G=>seg_p1_0(0));
    
    --PLAYER 2 SCORE
    uADDER2 : CLA_4bit port map(A=>P2_SCORE,
                                B=>"0110",
                                C_IN=>'0',
                                C_OUT=>p2_val(4),
                                SUM=>p2_val(3 downto 0));
    
    --if the value is greater than 9, add 6 to convert to BCD
    p2_bcd <= "0000" & P2_SCORE when (P2_SCORE(3) = '0' or P2_SCORE(3 downto 1) = "100") else
              p2_val;
    
    --ten's place of player 2's score
    uSSP2_1 : SevenSegment port map(BCD_VAL=>p2_bcd(7 downto 4),
                                    A=>seg_p2_1(6),
                                    B=>seg_p2_1(5),
                                    C=>seg_p2_1(4),
                                    D=>seg_p2_1(3),
                                    E=>seg_p2_1(2),
                                    F=>seg_p2_1(1),
                                    G=>seg_p2_1(0));
                                    
    --one's place of player 2's score
    uSSP2_0 : SevenSegment port map(BCD_VAL=>p2_bcd(3 downto 0),
                                    A=>seg_p2_0(6),
                                    B=>seg_p2_0(5),
                                    C=>seg_p2_0(4),
                                    D=>seg_p2_0(3),
                                    E=>seg_p2_0(2),
                                    F=>seg_p2_0(1),
                                    G=>seg_p2_0(0));
    
    --determine which bus to output
    --digits are common anode (need to drive positive signal to the digit when its digit's turn)
    process(digit_counter, seg_p1_1, seg_p1_0, seg_p2_1, seg_p2_0)
    begin
        case digit_counter is
            when "00" =>
                SEG <= seg_p1_1;
                DIGIT_P1_1 <= '1';
                DIGIT_P1_0 <= '0';
                DIGIT_P2_1 <= '0';
                DIGIT_P2_0 <= '0';
            when "01" =>
                SEG <= seg_p1_0;
                DIGIT_P1_0 <= '1';
                DIGIT_P1_1 <= '0';
                DIGIT_P2_0 <= '0';
                DIGIT_P2_1 <= '0';
            when "10" =>
                SEG <= seg_p2_1;
                DIGIT_P2_1 <= '1';
                DIGIT_P2_0 <= '0';
                DIGIT_P1_1 <= '0';
                DIGIT_P1_0 <= '0';
            when "11" =>
                SEG <= seg_p2_0;
                DIGIT_P2_0 <= '1';
                DIGIT_P2_1 <= '0';
                DIGIT_P1_0 <= '0';
                DIGIT_P1_1 <= '0';
        end case;
    end process;
    
    --two flip-flops wired to create asynchronous counter for counting 0,1,2,3,0... for alternating through the digit segments
    uFF0 : FlipFlop port map(CLK=>CLK,
                             RESET_L=>'1',
                             Q=>digit_counter(0),
                             D=>inv_digit_counter(0),
                             Q_INV=>inv_digit_counter(0));
    
    uFF1 : FlipFlop port map(CLK=>inv_digit_counter(0),
                             RESET_L=>'1',
                             Q=>digit_counter(1),
                             D=>inv_digit_counter(1),
                             Q_INV=>inv_digit_counter(1));                                      
end architecture;
