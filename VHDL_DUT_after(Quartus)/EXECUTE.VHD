--  Execute module (implements the data ALU and Branch Address Adder  
--  for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY  Execute IS
	generic ( MEMwitdh : integer :=12);
	PORT(	Read_data_1 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Read_data_2 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Sign_extend 	: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );  --shamt is 10 downto 6
			Function_opcode : IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
			Instr_opcode 	: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 ); --for Itype
			ALUOp 			: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			ALUSrc 			: IN 	STD_LOGIC;
			Zero 			: OUT	STD_LOGIC;
			ALU_Result 		: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Branch_or_jr 		: OUT	STD_LOGIC_VECTOR( MEMwitdh-3 DOWNTO 0 );
			PC_plus_4 		: IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
			clock, reset	: IN 	STD_LOGIC );
END Execute;


ARCHITECTURE behavior OF Execute IS
	SIGNAL Ainput, Binput 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL ALU_output_mux,ALU_out_itype	: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Branch_Add 			: STD_LOGIC_VECTOR( MEMwitdh-3 DOWNTO 0 );
	SIGNAL ALU_ctl				: STD_LOGIC_VECTOR( 2 DOWNTO 0 );
	signal AmulB 				: STD_LOGIC_VECTOR( 63 DOWNTO 0 );
	signal RDadrr				: STD_LOGIC_VECTOR( 4 DOWNTO 0 );
BEGIN
	Ainput <= Read_data_1; --rs
						-- ALU input mux
	Binput <=Read_data_2 WHEN ( ALUSrc = '0' ) ELSE   --rt
				Sign_extend( 31 DOWNTO 0 );	--imm
				
	RDadrr <= Sign_extend(15 downto 11);
	
	AmulB <= Ainput*Binput;
	
						-- Generate ALU control bits
	ALU_ctl( 0 ) <= ( Function_opcode( 0 ) OR Function_opcode( 3 ) ) AND ALUOp( 1 );		
	ALU_ctl( 1 ) <= ( NOT Function_opcode( 2 ) ) OR (NOT ALUOp( 1 )) ;	
	ALU_ctl( 2 ) <= ( Function_opcode( 1 ) AND ALUOp( 1 )) OR ALUOp( 0 );
						
	Zero <= '1' -- Generate Zero Flag OR - "TAKEN" Flag
WHEN (Instr_opcode="000100" AND ALU_output_mux = X"00000000") OR (Instr_opcode="000101" AND ALU_output_mux /= X"00000000")
		ELSE '0';    
						-- Select ALU output        
	ALU_result <= X"0000000" & B"000"  & ALU_output_mux(31) --SLT /SLTI
WHEN ALU_ctl = "111" OR (ALU_ctl = "010" AND Instr_opcode ="001010") 
				ELSE ALU_output_mux( 31 DOWNTO 0 );
			
						-- Adder to compute Branch Address
	Branch_Add	<= PC_plus_4( MEMwitdh-1 DOWNTO 2 ) +  Sign_extend( MEMwitdh-3 DOWNTO 0 ) ;
	Branch_or_jr 	<=  Branch_Add( MEMwitdh-3 DOWNTO 0 ) WHEN ALUop ="01" ELSE 
							ALU_output_mux( MEMwitdh-1 DOWNTO 2 );



-- ALU_ctl decoder is not Injective function with the new ISA:
PROCESS ( ALU_ctl, Ainput, Binput,ALU_out_itype,RDadrr)
	BEGIN-- Select ALU operation

 	CASE ALU_ctl IS
						-- ALU performs ALUresult = A_input AND B_input
		WHEN "000" 	=>	ALU_output_mux 	<= Ainput AND Binput; 
						-- ALU performs ALUresult = A_input OR B_input
     		WHEN "001" 	=>	ALU_output_mux 	<= Ainput OR Binput;
				--  Itype or Rtype_add or Rtype_sll and JType(jmp/jal)
	 	WHEN "010" 	=>	ALU_output_mux 	<= ALU_out_itype;
						-- ALU performs JR
 	 	WHEN "011" 	=>
		if Function_opcode(5) ='0' then
ALU_output_mux <= X"00000"&Ainput( MEMwitdh-1 DOWNTO 0 ); --JR 
	else
ALU_output_mux 	<= Ainput + Binput ; --MOV 0
 	end if;
						-- ALU performs xor Rtype
 	 	WHEN "100" 	=>	ALU_output_mux 	<= Ainput XOR Binput;
						-- ALU performs ?
 	 	WHEN "101" 	=>	ALU_output_mux 	<= X"00000000";

-- Rtype_sub or Rtype_srl OR Rtype_MUL OR branch
 	 	WHEN "110" 	=>	
			 if Instr_opcode="000000" then
			--Rtype_srl or Rtype_sub
					if Function_opcode(5) ='0' then
						ALU_output_mux 	<=  std_logic_vector(shift_right(signed(Binput), to_integer(unsigned( Sign_extend( 10 DOWNTO 6 )))));
					else
						ALU_output_mux 	<= Ainput - Binput ;
					end if;
			 else 	
			--Rtype_MUL OR branch
					if Instr_opcode="011100" then
						ALU_output_mux 	<= AmulB(31 downto 0)  ; 
					else
						ALU_output_mux 	<= Ainput - Binput ;
					end if;
			end if;
				-- ALU performs SLT
  	 	WHEN "111" 	=>	ALU_output_mux 	<= Ainput - Binput ;
 	 	WHEN OTHERS	=>	ALU_output_mux 	<= X"00000000" ;
  	END CASE;
END PROCESS;

PROCESS(Ainput, Binput,RDadrr)
begin
---------for I_TYPE
	CASE Instr_opcode(3 downto 0) IS
					
		WHEN "0000" 	=>	
--SLL,ADD are Rtype with ALU_ctl="010"
IF Function_opcode(5)='0' THEN
ALU_out_itype <= std_logic_vector(shift_left(signed(Binput), to_integer(unsigned( Sign_extend( 10 DOWNTO 6 )))));
ELSE 
ALU_out_itype <= Ainput + Binput;
END IF;
					-- ALU performs addi
		WHEN "1000" 	=>	ALU_out_itype 	<= Ainput + Binput; 
						-- ALU performs sub (slti)
	 	WHEN "1010" 	=>	ALU_out_itype 	<= Ainput - Binput;
						-- ALU performs add (sw/lw)
 	 	WHEN "1011" 	=>	ALU_out_itype <= Ainput + Binput; --sw
		WHEN "0011" 	=>	
IF Instr_opcode(5)='1' THEN
	ALU_out_itype <= Ainput + Binput; --lw
ELSE
	ALU_out_itype 	<= X"00000" &PC_plus_4; -- FOR jal
END IF;
						-- ALU performs and 
 	 	WHEN "1100" 	=>	ALU_out_itype 	<=  Ainput AND Binput;
						-- ALU performs or
 	 	WHEN "1101" 	=>	ALU_out_itype 	<= Ainput OR Binput;
						-- ALU performs xor
 	 	WHEN "1110" 	=>	ALU_out_itype 	<= Ainput xor Binput;
						-- ALU performs lui
  	 	WHEN "1111" 	=>	ALU_out_itype 	<= Binput(15 downto 0)&X"0000" ;
 	 	WHEN OTHERS	=>	ALU_out_itype 	<= X"00000000" ;
  	END CASE;

  END PROCESS;


END behavior;

