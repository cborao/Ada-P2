	
		--PRÁCTICA 2: César Borao Moratinos (client_collections)


	with Ada.Text_IO;
	with Chat_Messages;
	with Ada.Exceptions;
	with Lower_Layer_UDP;
	with Ada.Command_Line;
	with Ada.Strings.Unbounded;
	with Ada.Unchecked_Deallocation;

package body Client_Collections is

	package ATI renames Ada.Text_IO;
	package CM renames Chat_Messages;

	use ASU;

	procedure Add_Client (Collection: in out Collection_Type;
                              EP: in LLU.End_Point_Type;
                              Nick: in ASU.Unbounded_String;
                              Unique: in Boolean) is

		Aux: Cell_A;
		Included: Boolean;
	begin
		Included := False;
		if Collection.P_First = null then
			
			Collection.P_First := new Cell'(EP, Nick, null);
			Collection.Total := Collection.Total + 1;
			Aux := Collection.P_First;
			Included := True;
		else
		
			Aux := Collection.P_First;
			while Aux /= null and not Included loop
				
				if ASU.To_String(Aux.Nick) = ASU.To_String(Nick) and Unique then
					Included := True;
					raise Client_Collection_Error;
				end if;

				Aux := Aux.Next;
			end loop;
			
			Aux := new Cell'(EP, Nick, null);
			Aux.Next := Collection.P_First;
			Collection.P_First := Aux;
			Collection.Total := Collection.Total + 1;
		end if;
			
	end Add_Client;


	procedure Delete_Client (Collection: in out Collection_Type;
                           	 Nick: in ASU.Unbounded_String) is

		Aux: Cell_A := Collection.P_First;
		Prev: Cell_A := Aux;
		Found: Boolean;
	
		procedure Free is new Ada.Unchecked_Deallocation (Cell, Cell_A);
	
	begin
		Found := False;

		while Aux /= null loop
			if ASU.To_String(Prev.Nick) = ASU.To_String(Nick) then
				Collection.P_First := Collection.P_First.Next;
				Free(Aux);
				Collection.Total := Collection.Total - 1;
				Found := True;	
			elsif ASU.To_String(Aux.Nick) = ASU.To_String(Nick) then
				Prev.Next := Aux.Next;
				Collection.Total := Collection.Total - 1;
				Free(Aux);
				Found := True;		
			else
				Prev := Aux;
				Aux := Aux.Next; 
			end if;
		end loop;

		if not Found then
			raise Client_Collection_Error;
		end if;
	end Delete_Client;


	function Search_Client (Collection: in Collection_Type;
				EP: in LLU.End_Point_Type) return ASU.Unbounded_String is

	
		Finder: Cell_A := Collection.P_First;
		Found: Boolean;
		Result: ASU.Unbounded_String;
	begin
		Found := False;
		while Finder /= null loop
			
			if LLU."="(Finder.Client_EP, EP) then
					
				Found := True;
				Result := Finder.Nick;

			end if;
			Finder := Finder.Next;
		end loop;
		
		if not Found then
			raise Client_Collection_Error;
		end if;

		return Result;

	end Search_Client;
                    

	procedure Send_To_All (Collection: in Collection_Type;
				P_Buffer: access LLU.Buffer_Type) is

	
		Aux: Cell_A := Collection.P_First;
	begin

		while Aux /= null loop
			
			LLU.Send (Aux.Client_EP, P_Buffer);

			Aux := Aux.Next;
		end loop;

	end Send_To_All;      


	procedure Divide_EP (EP_Image: in out ASU.Unbounded_String;
				Nick: in ASU.Unbounded_String;
				Add_EP: out Unbounded_String) is

		IP_Image:   	Unbounded_String;
		Port_Image: 	Unbounded_String;
		Position:   	Integer;
		Delimiter:  	String := " ";
		
	begin
		for I in 1..2 loop
			Position := ASU.Index(EP_Image, Delimiter);
			ASU.Tail(EP_Image, ASU.Length(EP_Image) - Position);
		end loop;

		Position := ASU.Index(EP_Image, Delimiter);
		IP_Image := ASU.Head (EP_Image, Position - 2);
		ASU.Tail(EP_Image, ASU.Length(EP_Image) - Position);

		Position := ASU.Index(EP_Image, Delimiter);
		Port_Image := ASU.Tail(EP_Image, ASU.Length(EP_Image) - Position - 1);

		Add_EP := IP_Image & ":" & Port_Image & " " & ASU.To_String(Nick);

	end Divide_EP;


	function Collection_Image (Collection: in Collection_Type) return String is

		Aux: 	  Cell_A := Collection.P_First;
		EP_Image: ASU.Unbounded_String;
		Add_EP:   Unbounded_String;	
		Result:   ASU.Unbounded_String;
	begin

		Aux := Collection.P_First;
		while Aux /= null loop

			EP_Image := ASU.To_Unbounded_String(LLU.Image(Aux.Client_EP));
			Divide_EP (EP_Image, Aux.Nick, Add_EP);
			Result := Result & ASCII.LF & Add_EP; 
			Aux := Aux.Next;
		end loop;

		return ASU.To_String(Result);
	end Collection_Image;

end Client_Collections;

