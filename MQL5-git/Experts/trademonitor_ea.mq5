//+------------------------------------------------------------------+
//|                                              TradeMonitor_EA.mq5 |
//|                                        Copyright © 2018, Amr Ali |
//|                             https://www.mql5.com/en/users/amrali |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Amr Ali"
#property link      "https://www.mql5.com/en/users/amrali"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include "TradeTransaction.mqh"
//+------------------------------------------------------------------+
//| Class CExtTransaction.                                           |
//| Derives from base class CTradeTransaction.                       |
//+------------------------------------------------------------------+
class CExtTransaction : public CTradeTransaction
  {
protected:
   //--- trade transactions
   virtual void      TradeTransactionOrderPlaced(ulong order)                      { PrintFormat("Pending order is placed. (order %I64u)", order); }
   virtual void      TradeTransactionOrderModified(ulong order)                    { PrintFormat("Pending order is modified. (order %I64u)", order); }
   virtual void      TradeTransactionOrderDeleted(ulong order)                     { PrintFormat("Pending order is deleted. (order %I64u)", order); }
   virtual void      TradeTransactionOrderExpired(ulong order)                     { PrintFormat("Pending order is expired. (order %I64u)", order); }
   virtual void      TradeTransactionOrderTriggered(ulong order)                   { PrintFormat("Pending order is triggered. (order %I64u)", order); }

   virtual void      TradeTransactionPositionOpened(ulong position, ulong deal)    { PrintFormat("Position is opened. (position %I64u, deal %I64u)", position, deal); }
   virtual void      TradeTransactionPositionStopTake(ulong position, ulong deal)  { PrintFormat("Position is closed on sl or tp. (position %I64u, deal %I64u)", position, deal); }
   virtual void      TradeTransactionPositionClosed(ulong position, ulong deal)    { PrintFormat("Position is closed. (position %I64u, deal %I64u)", position, deal); }
   virtual void      TradeTransactionPositionCloseBy(ulong position, ulong deal)   { PrintFormat("Position is closed by opposite position. (position %I64u, deal %I64u)", position, deal); }
   virtual void      TradeTransactionPositionModified(ulong position)              { PrintFormat("Position is modified. (position %I64u)", position); }
  };

//+------------------------------------------------------------------+
//| Global transaction object                                        |
//+------------------------------------------------------------------+
CExtTransaction ExtTransaction;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("OnInit");
//---
   return (INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("OnDeinit");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   //Print("OnTick");
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
int InpTradePause = 500;
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---
   Print("OnTradeTransaction");
   Sleep(InpTradePause);
   DebugBreak();
   //ExtTransaction.OnTradeTransaction(trans,request,result);
  }
//+------------------------------------------------------------------+