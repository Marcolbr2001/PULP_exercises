----------------------------------------------------------------------------------
-- Engineer: Marco La Barbera
-- 
-- Create Date: 06.02.2026 22:44:32
-- Module Name: constant_pkg
--
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

package constant_pkg is
    
    -- FIFO Parameters
    constant DATA_WIDTH : integer := 8; 
    constant FIFO_DEPTH : integer := 4;
    
    -- Parity Checker Parameters
    constant PARITY_TYPE : string := "EVEN"; -- EVEN or ODD
    constant PARITY_BIT  : string := "MSB";  -- MSB or LSB
    
end package;
