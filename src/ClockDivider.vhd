----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: ClockDivider - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ClockDivider is
    port(
        CLK : IN std_logic;
        MAX_COUNT : IN std_logic_vector(7 downto 0);
        SLOW_CLK : OUT std_logic
    );
end entity;

--outputs a slowed down version of the internal CLK pin depending on the MAX_COUNT binary value passed in
architecture arch of ClockDivider is
    
    component CLA_4bit is
        port(
            A, B : IN std_logic_vector(3 downto 0);
            C_IN : IN std_logic;
            C_OUT : OUT std_logic;
            SUM : OUT std_logic_vector(3 downto 0)
        );
    end component;
    
    signal next_counter, counter : std_logic_vector(7 downto 0) := (others=>'0');
    signal snail_clk : std_logic := '0';
    signal carry : std_logic;
    
begin
    --add a value of 1 to the counter and store it into next counter (8-bit width using 2 4-bit CLAs)
    uCLA : CLA_4bit port map(A=>counter(3 downto 0), 
                             B=>"0000", 
                             C_IN=>'1', 
                             C_OUT=>carry, 
                             SUM=>next_counter(3 downto 0));
                             
    uCLA1 : CLA_4bit port map(A=>counter(7 downto 4), 
                              B=>"0000", 
                              C_IN=>carry, 
                              C_OUT=>OPEN, 
                              SUM=>next_counter(7 downto 4));
    
    process(CLK, next_counter, MAX_COUNT)
    begin
        if(rising_edge(CLK)) then
            if(next_counter = MAX_COUNT) then
                snail_clk <= '1';
                counter <= (others=>'0');
            else
                snail_clk <= '0';
                counter <= next_counter; --update the counter on the CLK's rising edge 
            end if;
        end if;
    end process;
    
    SLOW_CLK <= snail_clk;

end architecture;
