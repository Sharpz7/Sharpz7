-- Testbench for andorinvert

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity andorinvertTB is
end;

architecture TB1 of andorinvertTB is

    component AOI
        port(A,B,C,D : in std_logic;
	         F       : out std_logic);
    end component;

	signal A,B,C,D,F : std_logic;

begin

    G1: AOI port map (A=>A, B =>B, C=>C, D=>D, F=>F);

    stimuli: process
    begin
        A <= '0'; B <= '0'; C <= '0'; D <= '0'; wait for 10 NS;
        report "F = " & std_logic'image(F) severity note;
        A <= '0'; B <= '1'; C <= '0'; D <= '1'; wait for 10 NS;
        report "F = " & std_logic'image(F) severity note;
        A <= '1'; B <= '0'; C <= '1'; D <= '0'; wait for 10 NS;
        report "F = " & std_logic'image(F) severity note;
        A <= '1'; B <= '1'; C <= '1'; D <= '1'; wait for 10 NS;
        report "F = " & std_logic'image(F) severity note;
        wait;
    end process;

end;