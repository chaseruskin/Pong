----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: CLA_4bit - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity CLA_4bit is
    port(
        A, B : IN std_logic_vector(3 downto 0);
        C_IN : IN std_logic;
        C_OUT : OUT std_logic;
        SUM : OUT std_logic_vector(3 downto 0)
    );
end entity;

 --4-bit carry look-ahead adder using helper functions "propagate carry" and "generate carry"
architecture arch of CLA_4bit is
    signal prop_func, gen_func, carry : std_logic_vector(3 downto 0);
    
begin

    prop_func(0) <= A(0) or B(0);
    gen_func(0) <= A(0) and B(0);
    
    SUM(0) <= prop_func(0) xor gen_func(0) xor C_IN;
    carry(0) <= gen_func(0) or (prop_func(0) and C_IN);

    CLA : for i in 1 to 3 generate
        prop_func(i) <= A(i) or B(i);
        gen_func(i) <= A(i) and B(i);
    
        SUM(i) <= prop_func(i) xor gen_func(i) xor carry(i-1);
        carry(i) <= gen_func(i) or (prop_func(i) and carry(i-1));
    end generate CLA;
    
    C_OUT <= carry(3);
end architecture;
