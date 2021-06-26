
		--PRÁCTICA 2: César Borao Moratinos (chat_client)


	with Ada.Text_IO;
	with Chat_Messages;
	with Lower_Layer_UDP;
	with Ada.Command_Line;
	with Client_Collections;
	with Ada.Strings.Unbounded;

procedure Chat_Client is

	package ATI renames Ada.Text_IO;
	package CM renames Chat_Messages;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package CC renames Client_Collections;
	package ASU renames Ada.Strings.Unbounded;
	
	use type CM.Message_Type;

	Server_EP:  LLU.End_Point_Type;
  	Client_EP:  LLU.End_Point_Type;
   	Buffer:     aliased LLU.Buffer_Type(1024);
   	Expired:    Boolean;
	Port: 	    Integer;
	Mess:	    CM.Message_Type;	
	Nick:	    ASU.Unbounded_String;
	Comment:    ASU.Unbounded_String;
	
begin

	--IP and Port Selection (Binding)
	Port := Integer'Value(ACL.Argument(2));
   	Server_EP := LLU.Build(LLU.To_IP(ACL.Argument(1)), Port);
  	LLU.Bind_Any(Client_EP);
	Nick := ASU.To_Unbounded_String(ACL.Argument(3));
	LLU.Reset(Buffer);

	--Client Init
	Mess := CM.Init;
	CM.Message_Type'Output(Buffer'Access, Mess);	
	LLU.End_Point_Type'Output(Buffer'Access, Client_EP);
	ASU.Unbounded_String'Output(Buffer'Access, Nick);
	LLU.Send (Server_EP, Buffer'Access);
	LLU.Reset(Buffer);
                         

	if ASU.To_String(Nick) = "reader" then
		
		loop
			LLU.Receive (Client_EP, Buffer'Access, 1000.0, Expired);
			
			if Expired then
				ATI.Put_Line ("Please, try again");
			else
			
				--Server messages to readers
				Mess := CM.Message_Type'Input(Buffer'Access);
				Nick := ASU.Unbounded_String'Input(Buffer'Access);
				Comment := ASU.Unbounded_String'Input(Buffer'Access);

				ATI.Put_Line(ASU.To_String(Nick) & ": " & ASU.To_String(Comment));
				LLU.Reset(Buffer);
			end if;
		end loop;

	else
		loop
		
			ATI.Put("Message: ");
			Comment := ASU.To_Unbounded_String(ATI.Get_Line);

			--Client Writer
			Mess := CM.Writer;
			CM.Message_Type'Output(Buffer'Access, Mess);
			LLU.End_Point_Type'Output(Buffer'Access, Client_EP);
			ASU.Unbounded_String'Output(Buffer'Access, Comment);
			
			if ASU.To_String(Comment) /= ".quit" then
					
				LLU.Send(Server_EP, Buffer'Access);

			end if;
			
			LLU.Reset(Buffer);
			
			exit when ASU.To_String(Comment) = ".quit";
		end loop;
	end if;

	LLU.Finalize;

end Chat_Client;
