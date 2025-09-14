LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

ENTITY GPIO IS
	generic ( MEMwitdh : integer :=12);
	PORT( 
			MCLK,divclk,rst				: IN 	STD_LOGIC;
			MemRead 			: IN 	STD_LOGIC;
         		MemWrite 			: IN 	STD_LOGIC;	
			addressBUS		   	: IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
			DATA_bus 			: INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			SWch 					: IN STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			LEDR 					:OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			HEX0,HEX1 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX2,HEX3 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			HEX4,HEX5 			:OUT STD_LOGIC_VECTOR( 6 DOWNTO 0 );
			DivIFG				:OUT STD_LOGIC
			);
END GPIO;


ARCHITECTURE behavior OF GPIO IS

COMPONENT DivisionACC IS
  GENERIC (n : INTEGER := 32);
  PORT (    Dividend,Divisor: IN STD_LOGIC_VECTOR (n-1 DOWNTO 0);
            Divclk,rst,ena: IN STD_LOGIC;
            DivIFG: OUT STD_LoGIC;
            Quotient,Residue: OUT STD_LOGIC_VECTOR(n-1 downto 0));
END COMPONENT;


signal read_bus,write_bus : STD_LOGIC_VECTOR(31 DOWNTO 0 );
signal CS: STD_LOGIC_VECTOR( 7 DOWNTO 0 );
signal hexINTER: STD_LOGIC_VECTOR( 3 DOWNTO 0 );
signal enwr,dividen,set_divIFG :STD_LOGIC;

constant n :integer :=32;
signal Dividend,Divisor : STD_LOGIC_VECTOR(n-1 DOWNTO 0 );
signal Quotient,Residue,Quotient_out,Residue_out,Quotient_IN,Residue_IN : STD_LOGIC_VECTOR(n-1 DOWNTO 0 );

BEGIN 
read_bus <= DATA_bus;
DATA_bus <= write_bus WHEN enwr='1' else ( others =>'Z');


DivIFG <= set_divIFG;
Quotient <= Quotient_IN when set_divIFG='0' else Quotient_out;
Residue <= Residue_IN when set_divIFG='0' else Residue_out;

/*
iodec: PROCESS(addressBUS)
begin
	case addressBUS(11 downto 0) IS
		-- LEDR
		WHEN X"800" 	=>	CS <= "00000001";
		-- HEX0/1
	 	WHEN X"804" 	=>	CS <= "00000010";		
 	 	WHEN X"805" 	=>	
CS <= "00000100";
		-- HEX2/3
		WHEN X"808" 	=>	CS <= "00001000";
 	 	WHEN X"809" 	=>	CS <= "00010000";
		-- HEX4/5		
 	 	WHEN X"80C" 	=>	CS <= "00100000";						
 	 	WHEN X"80D" 	=>	CS <= "01000000";
		-- SWch				
  	 	WHEN X"810" 	=>	CS <= "10000000";
		--DIVIDEND
		WHEN X"82C" 	=>	CS <= "11111110";
		--DIVISOR
 	 	WHEN X"830" 	=>	CS <= "11111100";
		--QUOTIENT	
 	 	WHEN X"834" 	=>	CS <= "11111000";	
		--RESIDUE				
 	 	WHEN X"838" 	=>	CS <= "11110000";
		WHEN OTHERS	=>	CS <= "00000000";
  	END CASE; 
end process;*/

latches :PROCESS(Mclk,rst,read_bus,SWch,DIVIDEND,DIVISOR,QUOTIENT,RESIDUE)
begin
if rst='1' then
Dividend <= (OTHERS => '0');
DIVISOR <= (OTHERS => '0');
Quotient_IN <= (OTHERS => '0');
Residue_IN <= (OTHERS => '0');
dividen <='0' ;
enwr <= '1' ;
LEDR<=(OTHERS => '0');
hexINTER <= "ZZZZ";

elsif (mclk'event and mclk ='0') then
	
if ( MemWrite = '1') then	
case addressBUS(11 downto 0)  IS
		--DIVIDEND
		WHEN X"82C"	=> 	
		Dividend <= read_bus; 
		dividen <='0' ;
		--DIVISOR
		WHEN X"830"	=>	
		DIVISOR <= read_bus;
		dividen <='1' ;
		--QUOTIENT
		WHEN X"834"=>	
		Quotient_IN <= read_bus;
		dividen <='0' ;
		--RESIDUE
		WHEN X"838"=>	
		Residue_IN <= read_bus;
		dividen <='0' ;	
		
			--LEDR
		WHEN X"800"=>	
		LEDR <= read_bus(7 DOWNTO 0);
		--write 7-segment (HEXi)
	WHEN X"804"  =>-- HEX0/1
		hexINTER <= read_bus(3 DOWNTO 0);
	WHEN X"805" =>
		hexINTER <= read_bus(3 DOWNTO 0);

	WHEN X"808" =>-- HEX2/3
		hexINTER <= read_bus(3 DOWNTO 0);
	WHEN X"809" =>
		hexINTER <= read_bus(3 DOWNTO 0);

	WHEN X"80C" =>-- HEX4/5
		hexINTER <= read_bus(3 DOWNTO 0);
	WHEN X"80D" =>
		hexINTER <= read_bus(3 DOWNTO 0);
 	 	WHEN OTHERS => dividen <='0' ;
  	END CASE;


elsif ( MemRead = '1') then
	case addressBUS(11 downto 0) IS
		--read SWch
		WHEN X"810" =>	
		write_bus <=  X"000000"&SWch;
		dividen <='0' ;
		enwr <= '1' ;
		--DIVIDEND
		WHEN X"82C"=> 	
		write_bus <= DIVIDEND;
		dividen <='0' ;
		enwr <= '1' ;
		--DIVISOR
		WHEN X"830"=>	
		write_bus <= DIVISOR;
		dividen <='0' ;
		enwr <= '1' ;
		--QUOTIENT
		WHEN X"834"	=>	
		write_bus <= QUOTIENT;
		dividen <='0' ;
		enwr <= '1' ;
		--RESIDUE
		WHEN X"838"=>	
		write_bus <= RESIDUE;
		dividen <='0' ;
		enwr <= '1' ;
 	 	WHEN OTHERS =>
		enwr <= '0' ;
		dividen <='0' ;
  	END CASE; 
END IF;
end if;
end process;


divMAP : DivisionACC GENERIC MAP(n) PORT MAP (
	Dividend => Dividend,
	Divisor => Divisor,
        Divclk=>divclk,
	rst=> rst,
	ena=>dividen,
        DivIFG=> set_divIFG,
	Quotient=>Quotient_out,
	Residue=> Residue_out);


hexprocess :PROCESS(mclk,hexINTER,rst,addressBUS)
begin
if rst='1' then 
HEX0 <= "1111111";
HEX1 <= "1111111";
HEX2 <= "1111111";
HEX3 <= "1111111";
HEX4 <= "1111111";
HEX5 <= "1111111";
elsif (mclk'event and mclk ='1') then
if (addressBUS =X"804" ) then
		case hexINTER is
					 when "0000" => HEX0 <= "0000001";  -- 0
					 when "0001" => HEX0 <= "1001111";  -- 1
				    	 when "0010" => HEX0 <= "0010010";  -- 2
					 when "0011" => HEX0 <= "0000110";  -- 3
					 when "0100" => HEX0 <= "1001100";  -- 4
					 when "0101" => HEX0 <= "0100100";  -- 5
					 when "0110" => HEX0 <= "0100000";  -- 6
					 when "0111" => HEX0 <= "0001111";  -- 7
					 when "1000" => HEX0 <= "0000000";  -- 8
					 when "1001" => HEX0 <= "0000100";  -- 9
                when "1010" => HEX0 <= "0001000"; -- a
					 when "1011" => HEX0 <= "1100000"; -- b
					 when "1100" => HEX0 <= "0110001"; -- C
					 when "1101" => HEX0 <= "1000010"; -- d
					 when "1110" => HEX0 <= "0110000"; -- E
					 when "1111" => HEX0 <= "0111000"; -- F
					 when others => HEX0 <= "1111111";  -- Off
        end case;
elsif (addressBUS = X"805") then
		case hexINTER(3 downto 0) is
					 when "0000" => HEX1 <= "0000001";  -- 0
					 when "0001" => HEX1 <= "1001111";  -- 1
				    when "0010" => HEX1 <= "0010010";  -- 2
					 when "0011" => HEX1 <= "0000110";  -- 3
					 when "0100" => HEX1 <= "1001100";  -- 4
					 when "0101" => HEX1 <= "0100100";  -- 5
					 when "0110" => HEX1 <= "0100000";  -- 6
					 when "0111" => HEX1 <= "0001111";  -- 7
					 when "1000" => HEX1 <= "0000000";  -- 8
					 when "1001" => HEX1 <= "0000100";  -- 9
                when "1010" => HEX1 <= "0001000"; -- a
					 when "1011" => HEX1 <= "1100000"; -- b
					 when "1100" => HEX1 <= "0110001"; -- C
					 when "1101" => HEX1 <= "1000010"; -- d
					 when "1110" => HEX1 <= "0110000"; -- E
					 when "1111" => HEX1 <= "0111000"; -- F
					 when others => HEX1 <= "1111111";  -- Off
        end case;
		
elsif (addressBUS = X"808") then
		case hexINTER(3 downto 0) is
					 when "0000" => HEX2 <= "0000001";  -- 0
					 when "0001" => HEX2 <= "1001111";  -- 1
				    when "0010" => HEX2 <= "0010010";  -- 2
					 when "0011" => HEX2 <= "0000110";  -- 3
					 when "0100" => HEX2 <= "1001100";  -- 4
					 when "0101" => HEX2 <= "0100100";  -- 5
					 when "0110" => HEX2 <= "0100000";  -- 6
					 when "0111" => HEX2 <= "0001111";  -- 7
					 when "1000" => HEX2 <= "0000000";  -- 8
					 when "1001" => HEX2 <= "0000100";  -- 9
                when "1010" => HEX2 <= "0001000"; -- a
					 when "1011" => HEX2 <= "1100000"; -- b
					 when "1100" => HEX2 <= "0110001"; -- C
					 when "1101" => HEX2 <= "1000010"; -- d
					 when "1110" => HEX2 <= "0110000"; -- E
					 when "1111" => HEX2 <= "0111000"; -- F
					 when others => HEX2 <= "1111111";  -- Off
        end case;
		
		
elsif (addressBUS = X"809") then
		case hexINTER(3 downto 0) is
					 when "0000" => HEX3 <= "0000001";  -- 0
					 when "0001" => HEX3 <= "1001111";  -- 1
				    when "0010" => HEX3 <= "0010010";  -- 2
					 when "0011" => HEX3 <= "0000110";  -- 3
					 when "0100" => HEX3 <= "1001100";  -- 4
					 when "0101" => HEX3 <= "0100100";  -- 5
					 when "0110" => HEX3 <= "0100000";  -- 6
					 when "0111" => HEX3 <= "0001111";  -- 7
					 when "1000" => HEX3 <= "0000000";  -- 8
					 when "1001" => HEX3 <= "0000100";  -- 9
                when "1010" => HEX3 <= "0001000"; -- a
					 when "1011" => HEX3 <= "1100000"; -- b
					 when "1100" => HEX3 <= "0110001"; -- C
					 when "1101" => HEX3 <= "1000010"; -- d
					 when "1110" => HEX3 <= "0110000"; -- E
					 when "1111" => HEX3 <= "0111000"; -- F
					 when others => HEX3 <= "1111111";  -- Off
        end case;
		
		
elsif (addressBUS = X"80C") then
		case hexINTER(3 downto 0) is
					 when "0000" => HEX4 <= "0000001";  -- 0
					 when "0001" => HEX4 <= "1001111";  -- 1
				    when "0010" => HEX4 <= "0010010";  -- 2
					 when "0011" => HEX4 <= "0000110";  -- 3
					 when "0100" => HEX4 <= "1001100";  -- 4
					 when "0101" => HEX4 <= "0100100";  -- 5
					 when "0110" => HEX4 <= "0100000";  -- 6
					 when "0111" => HEX4 <= "0001111";  -- 7
					 when "1000" => HEX4 <= "0000000";  -- 8
					 when "1001" => HEX4 <= "0000100";  -- 9
                when "1010" => HEX4 <= "0001000"; -- a
					 when "1011" => HEX4 <= "1100000"; -- b
					 when "1100" => HEX4 <= "0110001"; -- C
					 when "1101" => HEX4 <= "1000010"; -- d
					 when "1110" => HEX4 <= "0110000"; -- E
					 when "1111" => HEX4 <= "0111000"; -- F
					 when others => HEX4 <= "1111111";  -- Off
        end case;
		
		
elsif (addressBUS = X"80D") then
		case hexINTER(3 downto 0) is
					 when "0000" => HEX5 <= "0000001";  -- 0
					 when "0001" => HEX5 <= "1001111";  -- 1
				    when "0010" => HEX5 <= "0010010";  -- 2
					 when "0011" => HEX5 <= "0000110";  -- 3
					 when "0100" => HEX5 <= "1001100";  -- 4
					 when "0101" => HEX5 <= "0100100";  -- 5
					 when "0110" => HEX5 <= "0100000";  -- 6
					 when "0111" => HEX5 <= "0001111";  -- 7
					 when "1000" => HEX5 <= "0000000";  -- 8
					 when "1001" => HEX5 <= "0000100";  -- 9
                when "1010" => HEX5 <= "0001000"; -- a
					 when "1011" => HEX5 <= "1100000"; -- b
					 when "1100" => HEX5 <= "0110001"; -- C
					 when "1101" => HEX5 <= "1000010"; -- d
					 when "1110" => HEX5 <= "0110000"; -- E
					 when "1111" => HEX5 <= "0111000"; -- F
					 when others => HEX5 <= "1111111";  -- Off
        	end case;
end if;
end if;

end process;

END behavior;