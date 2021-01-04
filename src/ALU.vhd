----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: ALU - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ALU is
    port(
        A, B : IN std_logic_vector(7 downto 0);
        SUB : IN std_logic;
        OUTPUT : OUT std_logic_vector(7 downto 0)
    );
end entity;

--8-bit addition and subtraction utilizing two's complement
architecture arch of ALU is
    
    component CLA_4bit is
        port(
            A, B : IN std_logic_vector(3 downto 0);
            C_IN : IN std_logic;
            C_OUT : OUT std_logic;
            SUM : OUT std_logic_vector(3 downto 0)
        );
    end component;
    
    signal s_B : std_logic_vector(7 downto 0);
    signal carry : std_logic;
begin

    s_B <= not B when (SUB = '1') else
                B;    

    --invert B and C_IN = '1' to create subtraction using 2's complement
    --can perform A + B and A - B
    
    uCLA0 : CLA_4bit port map(A=>A(3 downto 0), 
                              B=>s_B(3 downto 0), 
                              C_IN=>SUB,
                              C_OUT=>carry, 
                              SUM=>OUTPUT(3 downto 0));
    
     uCLA1 : CLA_4bit port map(A=>A(7 downto 4), 
                              B=>s_B(7 downto 4), 
                              C_IN=>carry,
                              C_OUT=>OPEN, 
                              SUM=>OUTPUT(7 downto 4));
end architecture;
