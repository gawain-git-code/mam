//+------------------------------------------------------------------+
//|                                             TradeTransaction.mqh |
//|                                        Copyright © 2018, Amr Ali |
//|                             https://www.mql5.com/en/users/amrali |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input bool InpIsLogging=true; // Verbose information

//+------------------------------------------------------------------+
//| Macro definitions.                                               |
//+------------------------------------------------------------------+
//--- check the expectation of transaction
#define IS_TRANSACTION_ORDER_PLACED            (trans.type == TRADE_TRANSACTION_REQUEST && request.action == TRADE_ACTION_PENDING && OrderSelect(result.order) && (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
#define IS_TRANSACTION_ORDER_MODIFIED          (trans.type == TRADE_TRANSACTION_REQUEST && request.action == TRADE_ACTION_MODIFY && OrderSelect(result.order) && (ENUM_ORDER_STATE)OrderGetInteger(ORDER_STATE) == ORDER_STATE_PLACED)
#define IS_TRANSACTION_ORDER_DELETED           (trans.type == TRADE_TRANSACTION_HISTORY_ADD && (trans.order_type >= 2 && trans.order_type < 6) && trans.order_state == ORDER_STATE_CANCELED)
#define IS_TRANSACTION_ORDER_EXPIRED           (trans.type == TRADE_TRANSACTION_HISTORY_ADD && (trans.order_type >= 2 && trans.order_type < 6) && trans.order_state == ORDER_STATE_EXPIRED)
#define IS_TRANSACTION_ORDER_TRIGGERED         (trans.type == TRADE_TRANSACTION_HISTORY_ADD && (trans.order_type >= 2 && trans.order_type < 6) && trans.order_state == ORDER_STATE_FILLED)

#define IS_TRANSACTION_POSITION_OPENED         (trans.type == TRADE_TRANSACTION_DEAL_ADD && HistoryDealSelect(trans.deal) && (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_IN)
#define IS_TRANSACTION_POSITION_STOP_TAKE      (trans.type == TRADE_TRANSACTION_DEAL_ADD && HistoryDealSelect(trans.deal) && (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT && ((ENUM_DEAL_REASON)HistoryDealGetInteger(trans.deal, DEAL_REASON) == DEAL_REASON_SL || (ENUM_DEAL_REASON)HistoryDealGetInteger(trans.deal, DEAL_REASON) == DEAL_REASON_TP))
#define IS_TRANSACTION_POSITION_CLOSED         (trans.type == TRADE_TRANSACTION_DEAL_ADD && HistoryDealSelect(trans.deal) && (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT && ((ENUM_DEAL_REASON)HistoryDealGetInteger(trans.deal, DEAL_REASON) != DEAL_REASON_SL && (ENUM_DEAL_REASON)HistoryDealGetInteger(trans.deal, DEAL_REASON) != DEAL_REASON_TP))
#define IS_TRANSACTION_POSITION_CLOSEBY        (trans.type == TRADE_TRANSACTION_DEAL_ADD && HistoryDealSelect(trans.deal) && (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT_BY)
#define IS_TRANSACTION_POSITION_MODIFIED       (trans.type == TRADE_TRANSACTION_REQUEST && request.action == TRADE_ACTION_SLTP)
//+------------------------------------------------------------------+
//| Class CTradeTransaction.                                         |
//| Purpose: Base class for trade transactions.                      |
//+------------------------------------------------------------------+
class CTradeTransaction
  {
public:
                     CTradeTransaction(void)  {   }
                    ~CTradeTransaction(void)  {   }
   //--- event handler
   void              OnTradeTransaction(const MqlTradeTransaction &trans,
                                        const MqlTradeRequest &request,
                                        const MqlTradeResult &result);
protected:
   //--- trade transactions
   //--- these methods should be overridden in the derived class
   virtual void      TradeTransactionOrderPlaced(ulong order)                      {   }
   virtual void      TradeTransactionOrderModified(ulong order)                    {   }
   virtual void      TradeTransactionOrderDeleted(ulong order)                     {   }
   virtual void      TradeTransactionOrderExpired(ulong order)                     {   }
   virtual void      TradeTransactionOrderTriggered(ulong order)                   {   }

   virtual void      TradeTransactionPositionOpened(ulong position, ulong deal)    {   }
   virtual void      TradeTransactionPositionStopTake(ulong position, ulong deal)  {   }
   virtual void      TradeTransactionPositionClosed(ulong position, ulong deal)    {   }
   virtual void      TradeTransactionPositionCloseBy(ulong position, ulong deal)   {   }
   virtual void      TradeTransactionPositionModified(ulong position)              {   }
  };
//+------------------------------------------------------------------+
//| Method of verification of trade transactions.                    |
//+------------------------------------------------------------------+
void CTradeTransaction::OnTradeTransaction(const MqlTradeTransaction &trans,
                                           const MqlTradeRequest &request,
                                           const MqlTradeResult &result)
  {
//---
   if(InpIsLogging)
     {
      if(trans.type!=TRADE_TRANSACTION_REQUEST)
        {
         //--- displays information on transactions
         Print("---===Transaction===---");
         string desc="Type: "+EnumToString(trans.type)+"\n";
         desc += "Symbol: " + trans.symbol + "\n";
         desc += "Deal ticket: " + (string)trans.deal + "\n";
         desc += "Deal type: " + EnumToString(trans.deal_type) + "\n";
         desc += "Order ticket: " + (string)trans.order + "\n";
         desc += "Order type: " + EnumToString(trans.order_type) + "\n";
         desc += "Order state: " + EnumToString(trans.order_state) + "\n";
         desc += "Order time type: " + EnumToString(trans.time_type) + "\n";
         desc += "Order expiration: " + TimeToString(trans.time_expiration) + "\n";
         desc += "Price: " + StringFormat("%G", trans.price) + "\n";
         desc += "Price trigger: " + StringFormat("%G", trans.price_trigger) + "\n";
         desc += "Stop Loss: " + StringFormat("%G", trans.price_sl) + "\n";
         desc += "Take Profit: " + StringFormat("%G", trans.price_tp) + "\n";
         desc += "Volume: " + StringFormat("%G", trans.volume) + "\n";
         desc += "Position: " + (string)trans.position + "\n";
         desc += "Position by: " + (string)trans.position_by + "\n";
         Print(desc);
        }

      //--- if a request has been processed by server
      if(trans.type==TRADE_TRANSACTION_REQUEST)
        {
         //--- displays type of transaction
         Print("---===Transaction===---");
         string desc="Type: "+EnumToString(trans.type)+"\n";
         Print(desc);

         //--- displays information on the request
         Print("---===Request===---");
         desc="Action: "+EnumToString(request.action)+"\n";
         desc += "Symbol: " + request.symbol + "\n";
         desc += "Magic Number: " + StringFormat("%d", request.magic) + "\n";
         desc += "Order ticket: " + (string)request.order + "\n";
         desc += "Order type: " + EnumToString(request.type) + "\n";
         desc += "Order filling: " + EnumToString(request.type_filling) + "\n";
         desc += "Order time type: " + EnumToString(request.type_time) + "\n";
         desc += "Order expiration: " + TimeToString(request.expiration) + "\n";
         desc += "Price: " + StringFormat("%G", request.price) + "\n";
         desc += "Deviation points: " + StringFormat("%G", request.deviation) + "\n";
         desc += "Stop Loss: " + StringFormat("%G", request.sl) + "\n";
         desc += "Take Profit: " + StringFormat("%G", request.tp) + "\n";
         desc += "Stop Limit: " + StringFormat("%G", request.stoplimit) + "\n";
         desc += "Volume: " + StringFormat("%G", request.volume) + "\n";
         desc += "Comment: " + request.comment + "\n";
         desc += "Position: " + (string)request.position + "\n";
         desc += "Position by: " + (string)request.position_by + "\n";
         Print(desc);

         //--- displays information about result
         Print("---===Result===---");
         desc="Retcode: "+(string)result.retcode+"\n";
         desc += "Order ticket: " + (string)result.order + "\n";
         desc += "Deal ticket: " + (string)result.deal + "\n";
         desc += "Volume: " + StringFormat("%G", result.volume) + "\n";
         desc += "Price: " + StringFormat("%G", result.price) + "\n";
         desc += "Bid: " + StringFormat("%G", result.bid) + "\n";
         desc += "Ask: " + StringFormat("%G", result.ask) + "\n";
         desc += "Comment: " + result.comment + "\n";
         desc += "Request ID: " + StringFormat("%d", result.request_id) + "\n";
         desc += "Retcode external: " + (string)result.retcode_external + "\n";
         Print(desc);
        }
     }

//---
   if(IS_TRANSACTION_ORDER_PLACED)
      TradeTransactionOrderPlaced(result.order);

   else if(IS_TRANSACTION_ORDER_MODIFIED)
      TradeTransactionOrderModified(result.order);

   else if(IS_TRANSACTION_ORDER_DELETED)
      TradeTransactionOrderDeleted(trans.order);

   else if(IS_TRANSACTION_ORDER_EXPIRED)
      TradeTransactionOrderExpired(trans.order);

   else if(IS_TRANSACTION_ORDER_TRIGGERED)
      TradeTransactionOrderTriggered(trans.order);

   else if(IS_TRANSACTION_POSITION_OPENED)
      TradeTransactionPositionOpened(trans.position,trans.deal);

   else if(IS_TRANSACTION_POSITION_STOP_TAKE)
      TradeTransactionPositionStopTake(trans.position,trans.deal);

   else if(IS_TRANSACTION_POSITION_CLOSED)
      TradeTransactionPositionClosed(trans.position,trans.deal);

   else if(IS_TRANSACTION_POSITION_CLOSEBY)
      TradeTransactionPositionCloseBy(trans.position,trans.deal);

   else if(IS_TRANSACTION_POSITION_MODIFIED)
      TradeTransactionPositionModified(request.position);
  }
//+------------------------------------------------------------------+