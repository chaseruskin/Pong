----------------------------------------------------------------------------------
-- Company: UF Smart Systems Lab
-- Engineer: Chase Ruskin
-- 
-- Module Name: GraphicsCard - arch
-- Project Name: Pong
-- Target Devices: Xilinx Zybo Z7-10
-- Description: Two-player variation of pong where players press buttons to move
--              their paddle vertically to hit the ball past their opponent. The
--              first player to 15 wins.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity GraphicsCard is
    port(
    ADDRESS : IN std_logic_vector(13 downto 0);
    DIS_ENA : IN std_logic;
    BALL_ADDR, P1_ADDR, P2_ADDR : IN std_logic_vector(13 downto 0);
    P1_BOUNCE, P2_BOUNCE : OUT std_logic;
    R_BIT, G_BIT, B_BIT : OUT std_logic
    );
end GraphicsCard;

architecture arch of GraphicsCard is

    signal ball_bit, p1_bit, p2_bit, net_bit : std_logic;
    
    constant net_addr_x : std_logic_vector(6 downto 0) := "0110001";
    
    signal addr_x, addr_y : std_logic_vector(6 downto 0);

begin

    addr_y <= ADDRESS(13 downto 7);
    addr_x <= ADDRESS(6 downto 0);
    
    --ball is a single bit in space
    DRAW_BALL : process(ADDRESS, BALL_ADDR)
    begin
        if(ADDRESS = BALL_ADDR) then
            ball_bit <= '1';
        else
            ball_bit <= '0';
        end if;
    end process;
    
    --paddle 1 has 1x6 dimensions
    DRAW_PADDLE_1 : process(addr_x, P1_ADDR, addr_y)
    begin
        if(addr_x = P1_ADDR(6 downto 0) and (addr_y = P1_ADDR(13 downto 7) or (addr_y > P1_ADDR(13 downto 7) and addr_y < P1_ADDR(13 downto 7) + 6))) then
                p1_bit <= '1';
        else
            p1_bit <= '0';
        end if;
    end process;
    
    --paddle 2 has 1x6 dimensions
    DRAW_PADDLE_2 : process(addr_x, P2_ADDR, addr_y)
    begin
        if(addr_x = P2_ADDR(6 downto 0) and (addr_y = P2_ADDR(13 downto 7) or (addr_y > P2_ADDR(13 downto 7) and addr_y < P2_ADDR(13 downto 7) + 6))) then
                p2_bit <= '1';
        else
            p2_bit <= '0';
        end if;
    end process;
    
    --draw a net in the middle of the screen by alternating bits down a vertical line
    DRAW_NET : process(addr_x, addr_y)
    begin
        if(addr_x = net_addr_x and addr_y(0) = '0') then
            net_bit <= '1';
        else
            net_bit <= '0';
        end if;
    end process;
    
    --send information to Datapath regarding if the ball collides with paddle 1 or paddle 2
    P1_BOUNCE <= ball_bit and p1_bit;
    P2_BOUNCE <= ball_bit and p2_bit;
    
    --communicate to VGA controller about when to signal bits as '1' depending on if the address has an object
    R_BIT <= (ball_bit or p1_bit or net_bit) and DIS_ENA; --generate paddle 1 as red  
    G_BIT <= (ball_bit or net_bit) and DIS_ENA;
    B_BIT <= (ball_bit or p2_bit or net_bit) and DIS_ENA; --generate paddle 2 as blue
    
end architecture;
