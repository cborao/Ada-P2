
		--PRÁCTICA 2: César Borao Moratinos (chat_server)

	
	with Ada.Text_IO;
	with Chat_Messages;
	with Lower_Layer_UDP;
	with Ada.Command_Line;
	with Client_Collections;
	with Ada.Strings.Unbounded;

procedure Chat_Server is

	package ATI renames Ada.Text_IO;
	package CM renames Chat_Messages;
	package LLU renames Lower_Layer_UDP;
	package ACL renames Ada.Command_Line;
	package CC renames Client_Collections;
	package ASU renames Ada.Strings.Unbounded;

	use type CM.Message_Type;

   	Server_EP: 	LLU.End_Point_Type;
   	EP: 		LLU.End_Point_Type;
	Expired: 	Boolean;
	Port: 		Integer; 
   	Buffer_In:    	aliased LLU.Buffer_Type(1024);
	Buffer_Out: 	aliased LLU.Buffer_Type(1024);
	Collection_W: 	CC.Collection_Type;
	Collection_R: 	CC.Collection_Type;
	Unique: 	Boolean;
	Mess: 		CM.Message_Type;
	Nick: 		ASU.Unbounded_String;
	Comment: 	ASU.Unbounded_String;
	Nick_Server:	ASU.Unbounded_String;
	Password:	ASU.Unbounded_String;
	Data: 		ASU.Unbounded_String;
	Admin_EP:	LLU.End_Point_Type;
	Admin_Pass:	ASU.Unbounded_String;
	Shutdown:	Boolean;

begin
	
	-- Asignación y bindeado del Servidor
	Port := Integer'Value(ACL.Argument(1));
	Password := ASU.To_Unbounded_String(ACL.Argument(2));
	Server_EP := LLU.Build (LLU.To_IP(LLU.Get_Host_Name), Port);
	LLU.Bind (Server_EP);

	Shutdown := False;

   loop
	LLU.Reset (Buffer_In);
	LLU.Reset (Buffer_Out);

   	LLU.Receive (Server_EP, Buffer_In'Access, 1000.0, Expired);

	if Expired then
		ATI.Put_Line ("Please, try again");
	else
		Mess := CM.Message_Type'Input (Buffer_In'Access);
	
		if Mess = CM.Init then
			EP := LLU.End_Point_Type'Input (Buffer_In'Access);
			Nick := ASU.Unbounded_String'Input (Buffer_In'Access);
			ATI.Put("INIT received from " & ASU.To_String(Nick));
			
			if ASU.To_String (Nick) = "reader" then
				
				Unique := False; 
			
				CC.Add_Client (Collection_R, EP, Nick, Unique);
			else
				Unique := True;

				begin
					CC.Add_Client (Collection_W, EP, Nick, Unique);
				
					--Aviso de entrada al servidor
					Mess := CM.Server;
					CM.Message_Type'Output(Buffer_Out'Access, Mess);	
					Nick_Server := ASU.To_Unbounded_String("server");
					ASU.Unbounded_String'Output(Buffer_Out'Access, 
					Nick_Server);
					Comment := ASU.To_Unbounded_String(ASU.To_String(Nick) 
					& " joins the chat");
					ASU.Unbounded_String'Output(Buffer_Out'Access, Comment);
					CC.Send_To_All (Collection_R, Buffer_Out'Access);
				
				exception
					when CC.Client_Collection_Error =>
						ATI.Put (". IGNORED, nick already used");
				end;

			end if;

			ATI.New_Line;
			LLU.Reset(Buffer_In);
			LLU.Reset(Buffer_Out);

		elsif Mess = CM.Writer then
		
			begin
				EP := LLU.End_Point_Type'Input (Buffer_In'Access);
				Comment := ASU.Unbounded_String'Input (Buffer_In'Access);

				Nick := CC.Search_Client (Collection_W, EP);
	
				--reenvío del mensaje a los readers
				Mess := CM.Server;
				CM.Message_Type'Output(Buffer_Out'Access, Mess);	
				ASU.Unbounded_String'Output(Buffer_Out'Access, Nick);
				ASU.Unbounded_String'Output(Buffer_Out'Access, Comment);
				CC.Send_To_All (Collection_R, Buffer_Out'Access);
				Ada.Text_IO.Put_Line ("WRITER received from " & ASU.To_String
				(Nick) & ": " & ASU.To_String(Comment));	
	
				LLU.Reset(Buffer_In);
				LLU.Reset(Buffer_Out);

			exception
				when CC.Client_Collection_Error =>
				ATI.Put_Line ("WRITER received from unknown client. IGNORED");

			end;
	
		elsif Mess = CM.Collection_Request then
			ATI.Put_Line("LIST_REQUEST received");

			Admin_EP := LLU.End_Point_Type'Input (Buffer_In'Access);
			Admin_Pass := ASU.Unbounded_String'Input (Buffer_In'Access);
	
			if ASU.To_String(Admin_Pass) = ASU.To_String(Password) then
		
				--Enviamos respuesta
				Mess := CM.Collection_Data;
				Data := ASU.To_Unbounded_String(CC.Collection_Image(Collection_W));
		
				CM.Message_Type'Output (Buffer_Out'Access, Mess);
				ASU.Unbounded_String'Output (Buffer_Out'Access, Data);
		
				LLU.Send(Admin_EP, Buffer_Out'Access);
	
				LLU.Reset(Buffer_In);
				LLU.Reset(Buffer_Out);
			end if;	

		elsif Mess = CM.Ban then
	
			begin
				Admin_Pass := ASU.Unbounded_String'Input (Buffer_In'Access);
				Nick := ASU.Unbounded_String'Input (Buffer_In'Access);
				ATI.Put_Line("BAN received for " & ASU.To_String(Nick));

				if ASU.To_String(Admin_Pass) = ASU.To_String(Password) then
					CC.Delete_Client (Collection_W, Nick);
				end if;
			
			exception
				when CC.Client_Collection_Error =>
				ATI.Put_Line ("BAN received for " & ASU.To_String(Nick) & ". IGNORED, nick not found");

			end;
			
		elsif Mess = CM.Shutdown then
			ATI.Put_Line("SHUTDOWN received");
			Admin_Pass := ASU.Unbounded_String'Input (Buffer_In'Access);

			if ASU.To_String(Admin_Pass) = ASU.To_String(Password) then
				Shutdown := True;
			end if;
		end if;

	end if;

	exit when Shutdown;
   end loop;

      LLU.Finalize;

end Chat_Server;
