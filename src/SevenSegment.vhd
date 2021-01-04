----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: SevenSegment - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SevenSegment is
    port(
    BCD_VAL : IN std_logic_vector(3 downto 0);
    A, B, C, D, E, F, G : OUT std_logic
    );
end entity;

architecture arch of SevenSegment is
    signal seg : std_logic_vector(6 downto 0);
begin

--  |-A-|
--  F   B
--  |-G-|
--  E   C
--  |-D-|

seg <= "1111110" when (BCD_VAL = "0000") else --0
       "0110000" when (BCD_VAL = "0001") else --1
       "1101101" when (BCD_VAL = "0010") else --2
       "1111001" when (BCD_VAL = "0011") else --3
       "0110011" when (BCD_VAL = "0100") else --4
       "1011011" when (BCD_VAL = "0101") else --5
       "1011111" when (BCD_VAL = "0110") else --6
       "1110000" when (BCD_VAL = "0111") else --7
       "1111111" when (BCD_VAL = "1000") else --8
       "1110011" when (BCD_VAL = "1001") else --9
       "0000001"; --dash
       
 A <= not seg(6);
 B <= not seg(5);
 C <= not seg(4);
 D <= not seg(3);
 E <= not seg(2);
 F <= not seg(1);
 G <= not seg(0);
 
end architecture;
