LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY BTIMER IS
	generic ( MEMwitdh : integer :=12);
	PORT( Mclk,Mclk2,Mclk4,Mclk8,Mrst 		: IN 	STD_LOGIC;
			MemRead 			: IN 	STD_LOGIC;
         		MemWrite 			: IN 	STD_LOGIC;	
			addressBUS		   	: IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
			DATA_bus 			: INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			PWMout 				: OUT 	STD_LOGIC;	
			set_BTIFG 			: OUT 	STD_LOGIC
			);
END BTIMER;

ARCHITECTURE BTIMER_arch OF BTIMER IS
signal READbus,WRITEbus,BTCNT,BTCL0,BTCL1: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
signal BTCTL : STD_LOGIC_VECTOR( 7 DOWNTO 0 );

signal enwr,BTOUTMD,BTOUTEN,BTHOLD :STD_LOGIC;
signal BTSSEL :STD_LOGIC_VECTOR( 1 DOWNTO 0 );
signal BTIPx :STD_LOGIC_VECTOR( 2 DOWNTO 0 );

signal clk,Q0,Q3,Q7,Q11,Q15,Q19,Q23,Q25 :STD_LOGIC;


BEGIN 
READbus <= DATA_bus( 31 DOWNTO 0 );
DATA_bus <= WRITEbus WHEN enwr='1' else ( others =>'Z');

BTOUTMD<=BTCTL(7);
BTOUTEN<=BTCTL(6);
BTHOLD <=BTCTL(5);
BTSSEL <=BTCTL(4 downto 3);
BTIPx  <=BTCTL(2 downto 0);

with BTSSEL SELECT
	clk <=	Mclk2 WHEN "01",
		Mclk4 WHEN "10",
		Mclk8 WHEN "11", 
		Mclk WHEN others; --"00"
		
with BTIPx SELECT
	set_BTIFG <=	Q0 	WHEN "000",
			Q3	WHEN "001",
			Q7 	WHEN "010",
			Q11	WHEN "011",
			Q15 	WHEN "100",
			Q19	WHEN "101",
			Q23	WHEN "110", 
			Q25 	WHEN others; --"111"
		

BTlatches: PROCESS(MemRead,addressBUS,READbus,MemWrite,Mrst)
begin
IF Mrst = '1' THEN
	BTCTL <= X"20"; --BTHOLD='1'
	BTCNT <= (OTHERS => '0');
	BTCL0 <= (OTHERS => '0');
	BTCL1 <= (OTHERS => '0');
END IF;
	case addressBUS(11 downto 0) IS
		-- BTCTL
		WHEN X"81C" 	=>	
			IF (MemWrite ='1') THEN	
				BTCTL <= READbus(7 DOWNTO 0);
				enwr <= '0' ;
			ELSIF (MemRead ='1') THEN
				enwr <= '1' ;
				WRITEbus <= X"000000"&BTCTL;
			END IF;
		-- BTCNT
	 	WHEN X"820" 	=>	
			IF (MemWrite ='1') THEN	
				BTCNT <= READbus;
				enwr <= '0' ;
			ELSIF (MemRead ='1') THEN
				enwr <= '1' ;
				WRITEbus <= BTCNT;
			END IF;
		-- BTCCR0
		WHEN X"824" 	=>
			IF (MemWrite ='1') THEN	
				BTCL0 <= READbus;
				enwr <= '0' ;
			ELSIF (MemRead ='1') THEN
				enwr <= '1' ;
				WRITEbus <= BTCL0;
			END IF;
		-- BTCCR1		
 	 	WHEN X"828" 	=>	
			IF (MemWrite ='1') THEN	
				BTCL1 <= READbus;
				enwr <= '0' ;
			ELSIF (MemRead ='1') THEN
				enwr <= '1' ;
				WRITEbus <= BTCL1;
			END IF;
 	 	WHEN OTHERS	=>	enwr <= '0' ;
  	END CASE;
 
end process;

----BTCNT REGISTER COUNTING PROCESS
process (clk,Mrst)
begin
	if (Mrst ='1') then
		BTCNT <= (others =>'0');
    	elsif (rising_edge(clk)) then	
		IF (BTHOLD ='0') then
			if (BTCNT = X"FFFFFFFF") then
				BTCNT <= (others =>'0');
			else 
				BTCNT <= BTCNT + 1;
			end if;
		end if;
	end if;
end process;



----BTCNT REGISTER OVERFLOW PROCESS
process (BTCNT)
begin
	case BTCNT IS
		WHEN X"00000002" => Q0  <='1';	--Q0=CLK\CLK+1
		WHEN X"00000008" => Q3  <='1';	
		WHEN X"00000080" => Q7  <='1';	
		WHEN X"00000800" => Q11 <='1';	
		WHEN X"00008000" => Q15 <='1';
		WHEN X"00080000" => Q19 <='1';
		WHEN X"00800000" => Q23 <='1';
		WHEN X"02000000" => Q25 <='1';
		WHEN OTHERS	 =>	
			Q0  <='0';	
			Q3  <='0';	
			Q7  <='0';	
			Q11 <='0';	
		 	Q15 <='0';
		  	Q19 <='0';
		 	Q23 <='0';
		 	Q25 <='0';
	END CASE;
end process;

PROCESS(BTCNT,BTOUTMD,BTCL1,BTCL0,BTOUTEN)
--(BTCL0 -BTCL1)/ BTRMAX = dutycycle
BEGIN
	IF (BTOUTMD='0' AND BTOUTEN = '1') THEN
		IF (BTCNT >= BTCL1 AND BTCNT < BTCL0) THEN
			PWMout <= '1';
		ELSIF (BTCNT >= BTCL0) THEN
			PWMout <= '0';
		Else
			PWMout <= '0';
		END IF;
	ELSIF (BTOUTMD='1' AND BTOUTEN = '1' ) THEN
		IF (BTCNT >= BTCL1 AND BTCNT < BTCL0) THEN
			PWMout <= '0';
		ELSIF (BTCNT >= BTCL0) THEN
			PWMout <= '1';
		ELSE
			PWMout <= '1';
		END IF;
	ELSE PWMout <= '0';
	END IF;
END PROCESS;

END BTIMER_arch;
