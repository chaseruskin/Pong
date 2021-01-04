----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: FlipFlop - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FlipFlop is
    port(
        CLK, RESET_L, D : IN std_logic;
        Q, Q_INV : OUT std_logic
    );
end entity;

architecture arch of FlipFlop is
    signal out_q : std_logic := '0';
begin
    --store incoming value on CLK rising edge
    process(CLK, RESET_L, D)
    begin
        if(RESET_L = '0') then --asynchronous reset
            out_q <= '0';
        elsif(rising_edge(CLK)) then
            out_q <= D;
        end if;
    end process;
    
    Q <= out_q;
    Q_INV <= not out_q; --also output inverted value of the stored signal

end architecture;