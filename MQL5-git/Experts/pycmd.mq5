//+------------------------------------------------------------------+
//|                                                        pycmd.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <client.mqh>
int server;
int lrlenght = 100;
long account_login = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("OnInit");
   EventSetTimer(2);
// get login id
   account_login=AccountInfoInteger(ACCOUNT_LOGIN);
   Print("Account login: ", account_login);

   connect_to_server(server, account_login);
   Print("Server sock: ", server);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("OnDeinit");
   SocketClose(server);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {


  }

//+------------------------------------------------------------------+
//| Timer function                                             |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   Print("OnTimer");
   bool result = true;

// Check server connection
   Print("Server sock: ", server);
   if(SocketIsConnected(server))
     {
      // process server request
      result=cmdhandler(server);
     }
   else
     {
      Print("Server disconnected. Attempt to reconnect ...");
      SocketClose(server);
      // server is disconnected. Reconnect to server.
      connect_to_server(server, account_login);
     }
// Send notification
   string notify_msg = StringFormat("%d",account_login);
   send_notification(notify_msg);
  }
//+------------------------------------------------------------------+
