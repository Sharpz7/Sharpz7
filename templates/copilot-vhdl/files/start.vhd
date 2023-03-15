library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity AOI is
    Port ( A : in STD_LOGIC;
           B : in STD_LOGIC;
           C : in STD_LOGIC;
           D : in STD_LOGIC;
           F : out STD_LOGIC);
end AOI;

-- Create architecture for an and-or invert gate
-- i.e two and gates feeding into an or gate
architecture V1 of AOI is

    signal I1, I2, I3 : std_logic;

begin
    -- concurrent assignments
    I1 <= A and B;
    I2 <= C and D;
    I3 <= I1 or I2;
    F <= not I3;
end V1;
