//+------------------------------------------------------------------+
//|                                                HelloWorld0MQ.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Zmq/Zmq.mqh>
//+------------------------------------------------------------------+
//| Hello World server in MQL                                        |
//| Binds REP socket to tcp://*:5555                                 |
//| Expects "Hello" from client, replies with "World"                |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Context context("helloworld");
   Socket socket(context,ZMQ_REP);

   socket.bind("tcp://*:5555");

   while(true)
     {
      ZmqMsg request;

      // Wait for next request from client

      // MetaTrader note: this will block the script thread
      // and if you try to terminate this script, MetaTrader
      // will hang (and crash if you force closing it)
      socket.recv(request);
      Print("Receive Hello");

      Sleep(1000);

      ZmqMsg reply("World");
      // Send reply back to client
      socket.send(reply);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

  }
//+------------------------------------------------------------------+
