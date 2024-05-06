//+------------------------------------------------------------------+
//|                                                       client.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+

string sep = "^";
string end = "!";
// -------------------------------------------------------------
// Class definition
// -------------------------------------------------------------
bool socksend(int sock,string request)
  {
   char req[];
   int  len=StringToCharArray(request,req)-1;
   if(len<0)
      return(false);
   return(SocketSend(sock,req,len)==len);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string sockrecv(int sock,int timeout)
  {
   char rsp[];
   string result="";
   uint len;
   uint timeout_check=GetTickCount()+timeout;
   do
     {
      len=SocketIsReadable(sock);
      if(len)
        {
         int rsp_len;
         rsp_len=SocketRead(sock,rsp,len,timeout);
         if(rsp_len>0)
           {
            result+=CharArrayToString(rsp,0,rsp_len);
           }
        }
     }
   while((GetTickCount()<timeout_check) && !IsStopped());
   return result;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Get_Static_Account_Info(void)
  {
//--- Demo, contest or real account
   ENUM_ACCOUNT_TRADE_MODE account_type=(ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE);
//--- Now transform the value of  the enumeration into an understandable form
   string trade_mode;
   switch(account_type)
     {
      case  ACCOUNT_TRADE_MODE_DEMO:
         trade_mode="demo";
         break;
      case  ACCOUNT_TRADE_MODE_CONTEST:
         trade_mode="contest";
         break;
      default:
         trade_mode="real";
         break;
     }
//--- Stop Out is set in percentage or money
   ENUM_ACCOUNT_STOPOUT_MODE stop_out_mode=(ENUM_ACCOUNT_STOPOUT_MODE)AccountInfoInteger(ACCOUNT_MARGIN_SO_MODE);
//--- Get the value of the levels when Margin Call and Stop Out occur
//double margin_call=AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL);
//double stop_out=AccountInfoDouble(ACCOUNT_MARGIN_SO_SO);
   string output;
   StringConcatenate(output,
                     sep, AccountInfoString(ACCOUNT_COMPANY), //company
                     sep, AccountInfoString(ACCOUNT_NAME),    //name
                     sep, IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)), //login
                     sep, AccountInfoString(ACCOUNT_SERVER), //server
                     sep, trade_mode,
                     sep, (AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)==true)? "True":"False",//trade_allowed
                     sep, IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE)),  //leverage
                     sep, AccountInfoString(ACCOUNT_CURRENCY), //currency
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE)), //balance
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_CREDIT)), //credit
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT)), //profit
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY)), //equity
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN)), //margin
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE)), // margin free
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)), //margin level
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL)), //margin_call
                     sep, DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)), //stop_out
                     sep, (stop_out_mode==ACCOUNT_STOPOUT_MODE_PERCENT)?"percentage":" money"
                    );

   /*   string company=AccountInfoString(ACCOUNT_COMPANY);
      string name=AccountInfoString(ACCOUNT_NAME);
      string login=IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN));
      string account_server=AccountInfoString(ACCOUNT_SERVER);
      string TradeAllowed =AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)? "True":"False";
   //--- Account currency
      string leverage = IntegerToString(AccountInfoInteger(ACCOUNT_LEVERAGE));
      string currency=AccountInfoString(ACCOUNT_CURRENCY);
      string balance = DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE));
      string credit = DoubleToString(AccountInfoDouble(ACCOUNT_CREDIT));
      string profit = DoubleToString(AccountInfoDouble(ACCOUNT_PROFIT));
      string equity = DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY));

      string margin = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN));
      string margin_free = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE));
      string margin_level = DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL));
   //--- Show brief account information
      string data;
      data = StringFormat("^%s^%d^%s^%s^%s^!",
                          name,login,trade_mode,company,account_server);*/
   return output;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Get_Instruments(void)
  {
   string data;
   int total_symbols = SymbolsTotal(0);
   Print(total_symbols);
   
   StringConcatenate(data, sep, IntegerToString(total_symbols));
   
   for(int i=0; i<SymbolsTotal(0); i++)
     {
      StringAdd(data, sep);
      StringAdd(data, SymbolName(i,0));
     }

   return data;
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int cmdhandler(int socket)
  {
   string sep="^";                // A separator as a character
   ushort u_sep;                  // The code of the separator character
   string cmd[];
   string data;
   string msg = sockrecv(socket, 10);

   if(StringLen(msg) <= 0)
     {
      // check incoming message
      return -1;
     }
   Print("Received msg: ", msg);
//--- Split the string to substrings
//--- Get the separator code
   u_sep=StringGetCharacter(sep,0);
   int k=StringSplit(msg,u_sep,cmd);
   if(k>0)
     {
      for(int i=0; i<k; i++)
        {
         PrintFormat("cmd[%d]=\"%s\"",i,cmd[i]);
        }
     }

//--- Handle commands
   if(StringCompare(cmd[0], "F001") == 0)
     {
      Print("Executing ", cmd[0]);
      data = Get_Static_Account_Info();
     }
   else if(StringCompare(cmd[0], "F002") == 0)
     {
      Print("Executing ", cmd[0]);
      data = Get_Instruments();
     }
   else if(StringCompare(cmd[0], "F003") == 0)
     {
      data = "Not Available";
     }
   else
     {
      data = "Not Available";
     }

//Reply data to sesrver
   string output;
   StringConcatenate(output, cmd[0], data, sep, end);
   PrintFormat("Sending Payload output: %d.", StringLen(output));
   return socksend(socket, output);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool connect_to_server(int& sock, long id)
  {
   string msg = StringFormat("S001#%d#!",id);

   sock=SocketCreate();
   if(sock!=INVALID_HANDLE)
     {
      if(SocketConnect(sock,"localhost",9090,1000))
        {
         Print("Connected to "," localhost",":",9090);
        }
      else
        {
         Print("Connection ","localhost",":",9090," error ",GetLastError());
        }
      if(socksend(sock, msg) <= 0)
        {
         Print("Failed to send to server, error ", GetLastError());
         SocketClose(sock);
         return false;
        }
     }
   else
     {
      Print("Server socket creation error ",GetLastError());
      return false;
     }
   Print("Connected to server!");
   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool send_notification(string data)
  {
   bool sent = false;
   int retry = 0;
// Create notification message
   string msg = StringFormat("S002#%s#!",data);
// Create notifier socket to server
   int notifier=SocketCreate();
   if(notifier==INVALID_HANDLE)
     {
      Print("Notifer socket creation error ",GetLastError());
      return false;
     }

   while(!sent && retry < 10)
     {
      if(SocketConnect(notifier,"localhost",9090,1000))
        {
         // Send notification to server
         Print("Notifier connect to"," localhost",":",9090);
         if(socksend(notifier, msg) > 0)
           {
            // Check reply from server
            string reply = sockrecv(notifier,10);
            if(StringLen(reply) > 0)
              {
               if(StringCompare(reply, "OK") == 0)
                 {
                  //resent
                  sent = true;
                 }
               else
                 {
                  Print("Notifier: Server reply not OK."," error ",GetLastError());
                 }
              }
            else
              {
               Print("Notifier: Server didn't reply."," error ",GetLastError());
              }
           }
        }
      else
        {
         Print("Failed to notify server, error ", GetLastError());
        }
      retry++;
     }
   SocketClose(notifier);
   return sent;
  }
//+------------------------------------------------------------------+
