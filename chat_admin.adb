
		--PRÁCTICA 2: César Borao Moratinos (chat_admin)


	with Ada.Text_IO;
	with Chat_Messages;
	with Lower_Layer_UDP;
	with Ada.Command_Line;
	with Client_Collections;
	with Ada.Strings.Unbounded;

procedure Chat_Admin is

	package ATI renames Ada.Text_IO;
	package CM renames Chat_Messages;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package CC renames Client_Collections;
	package ASU renames Ada.Strings.Unbounded;
	
	use type CM.Message_Type;

	Server_Host: 	ASU.Unbounded_String;
	Server_Port: 	Integer; 
	Server_IP:	ASU.Unbounded_String;
	Password:	ASU.Unbounded_String;
	Option:		Integer;
	Mess:		CM.Message_Type;
	Nick: 		ASU.Unbounded_String;
	Buffer:    	aliased LLU.Buffer_Type(1024);
	Admin_EP:	LLU.End_Point_Type;
	Server_EP:	LLU.End_Point_Type;
	Expired:	Boolean;
	Data:		ASU.Unbounded_String;
	Incorrect_Pass:	Boolean;

begin

	Server_Host := ASU.To_Unbounded_String(ACL.Argument(1));
	Server_Port := Integer'Value(ACL.Argument(2));
	Password := ASU.To_Unbounded_String(ACL.Argument(3));
   
	LLU.Bind_Any(Admin_EP);

	Server_IP := ASU.To_Unbounded_String(LLU.To_IP(ASU.To_String(Server_Host)));
	Server_EP := LLU.Build(ASU.To_String(Server_IP), Server_Port);

	Incorrect_Pass := False;

	loop
			
		ATI.Put_Line("Options");
		ATI.Put_Line("1 Show writers collection");
		ATI.Put_Line("2 Ban writer");
		ATI.Put_Line("3 Shutdown Server");
		ATI.Put_Line("4 Quit");
		ATI.New_Line;
		ATI.Put("Your option? ");
		Option := Integer'Value(ATI.Get_Line);

		case Option is
			when 1 =>
				Mess := CM.Collection_Request;	

				--Collection Request Message
				CM.Message_Type'Output(Buffer'Access, Mess);
				LLU.End_Point_Type'Output(Buffer'Access, Admin_EP);
				ASU.Unbounded_String'Output(Buffer'Access, Password);
	
				LLU.Send(Server_EP, Buffer'Access);
				LLU.Reset(Buffer);

				LLU.Receive(Admin_EP, Buffer'Access, 5.0, Expired);
				
				if Expired then
					ATI.Put_Line("Incorrect password");
					Incorrect_Pass := True;
				else
					Mess := CM.Message_Type'Input (Buffer'Access);
					Data := ASU.Unbounded_String'Input (Buffer'Access);
					ATI.Put_Line(ASU.To_String(Data));
				end if;	
				ATI.New_Line;
				
				LLU.Reset(Buffer);

			when 2 =>
				Mess := CM.Ban;	
				ATI.Put("Nick to ban? ");
				Nick := ASU.To_Unbounded_String(ATI.Get_Line);
				ATI.New_Line;
				
				--Ban Message
				CM.Message_Type'Output(Buffer'Access, Mess);
				ASU.Unbounded_String'Output(Buffer'Access, Password);
				ASU.Unbounded_String'Output(Buffer'Access, Nick);
	
				LLU.Send(Server_EP, Buffer'Access);
				LLU.Reset(Buffer);

			when 3 =>
				Mess := CM.Shutdown;	
				ATI.Put_Line("Server shutdown sent");
				ATI.New_Line;
				
				--Shutdown Message
				CM.Message_Type'Output(Buffer'Access, Mess);
				ASU.Unbounded_String'Output(Buffer'Access, Password);
	
				LLU.Send(Server_EP, Buffer'Access);
				LLU.Reset(Buffer);	

			when 4 =>
				ATI.New_Line;
			when others =>
				ATI.Put_Line("Not implemented");
		end case;

		exit when Option = 4 or Incorrect_Pass;
	end loop;
		
	LLU.Finalize;
end Chat_Admin;
