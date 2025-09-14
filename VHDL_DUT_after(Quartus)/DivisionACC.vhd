library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
-------------------------------------
ENTITY DivisionACC IS
  GENERIC (n : INTEGER := 32);
  PORT (    Dividend,Divisor: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
            Divclk,rst,ena: IN STD_LOGIC;
            DivIFG: OUT STD_LoGIC;
            Quotient,Residue: OUT STD_LOGIC_VECTOR(n-1 downto 0));
END DivisionACC;
--------------------------------------------------------------------------
architecture DivisionACC_ARCH of DivisionACC IS
	signal Dividend_shiftreg : STD_LOGIC_VECTOR(2*n-1 DOWNTO 0);
	signal Divisor_reg, Quotient_shift, Subtractor_res : STD_LOGIC_VECTOR(n-1 DOWNTO 0);
	signal Divisor_reg_sub, Subtractor_out_sub,Dividend_shift_sub : STD_LOGIC_VECTOR(n DOWNTO 0);
	signal counter : INTEGER range 0 to n+1;

begin
	
	Dividend_shift_sub <= '0'& Dividend_shiftreg(2*n-1 DOWNTO n);
	Divisor_reg_sub <= '0'& Divisor_Reg;
	Subtractor_out_sub <= Dividend_shift_sub - Divisor_reg_sub;
	Subtractor_res <= Subtractor_out_sub(n-1 DOWNTO 0);
	
	process(rst,ena,Divclk)
	begin
		if (rst = '1') then
			counter <= 0;
			DivIFG <= '0';
			Quotient_shift <= (others => '0');
		elsif (ena = '0' or counter = n+1) then
			counter <= 0;
			Quotient_shift <= (others => '0');
			DivIFG <= '0';
		elsif (Divclk'event and Divclk = '1') then
			if (counter = 0 and ena = '1') then
				Dividend_shiftreg <= X"0000000"&B"000" & Dividend & '0' ;
				Divisor_reg <=  Divisor ;
				counter <= counter + 1;
			elsif (ena = '1' and counter < n+1 and counter > 0) then
				if (Subtractor_res(n-1) = '1' or Subtractor_out_sub (n) = '1') then 
					Quotient_shift <= Quotient_shift(n-2 DOWNTO 0) & '0';
					Dividend_shiftreg <= Dividend_shiftreg(2*n-2 DOWNTO 0) & '0';
				else 
					Quotient_shift <= Quotient_shift(n-2 DOWNTO 0) & '1';
					Dividend_shiftreg <= Subtractor_res(n-2 DOWNTO 0) & Dividend_shiftreg(n-1 DOWNTO 0)& '0';
				end if;
				if (counter = n)then
					DivIFG <= '1';
					if (Subtractor_res(n-1) = '1' or Subtractor_out_sub (n) = '1') then
						Quotient <= Quotient_shift(n-2 DOWNTO 0) & '0';
						Residue <= Dividend_shiftreg(2*n-1 DOWNTO n);
					else
						Quotient <= Quotient_shift(n-2 DOWNTO 0) & '1';
						Residue <= Subtractor_res;
					end if;
				end if;
				counter <= counter + 1;
			end if;	
		end if;
		
	end process;

END DivisionACC_ARCH;