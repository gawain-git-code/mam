//+------------------------------------------------------------------+
//|                                                       Broker.mqh |
//|                                                   Gunther Schulz |
//|                        https://github.com/khramkov/MQL5-JSON-API |
//+------------------------------------------------------------------+
#property copyright "Gunther Schulz"
#property link      "https://github.com/khramkov/MQL5-JSON-API"



//+------------------------------------------------------------------+
//| Fetch positions information                                      |
//+------------------------------------------------------------------+
void GetPositions(CJAVal &dataObject)
  {
   CPositionInfo myposition;
   CJAVal data, position;

// Get positions
   int positionsTotal=PositionsTotal();
// Create empty array if no positions
   if(!positionsTotal)
      data["positions"].Add(position);
// Go through positions in a loop
   for(int i=0; i<positionsTotal; i++)
     {
      mControl.mResetLastError();
      ulong ticket = PositionGetTicket(i);

      if(ticket>0)
        {
         PositionSelectByTicket(ticket);
         position["id"]=PositionGetInteger(POSITION_IDENTIFIER);
         position["magic"]=PositionGetInteger(POSITION_MAGIC);
         position["symbol"]=PositionGetString(POSITION_SYMBOL);
         position["type"]=EnumToString(ENUM_POSITION_TYPE(PositionGetInteger(POSITION_TYPE)));
         // Hard fixed to avoid string convertion error!
         mControl.mResetLastError();
         position["time_setup"]=PositionGetInteger(POSITION_TIME);
         position["open"]=PositionGetDouble(POSITION_PRICE_OPEN);
         position["stoploss"]=PositionGetDouble(POSITION_SL);
         position["takeprofit"]=PositionGetDouble(POSITION_TP);
         position["volume"]=PositionGetDouble(POSITION_VOLUME);
         position["comment"]=PositionGetString(POSITION_COMMENT);
         mControl.mResetLastError();
         data["error"]=(bool) false;
         data["positions"].Add(position);
        }
      CheckError(__FUNCTION__);
     }

   string t=data.Serialize();
   if(debug)
      Print(t);
   InformClientSocket(dataSocket,t);
  }

//+------------------------------------------------------------------+
//| Fetch orders information                                         |
//+------------------------------------------------------------------+
void GetOrders(CJAVal &dataObject)
  {
   mControl.mResetLastError();

   COrderInfo myorder;
   CJAVal data, order;

// Get orders
   if(HistorySelect(0,TimeCurrent()))
     {
      int ordersTotal = OrdersTotal();
      // Create empty array if no orders
      if(!ordersTotal)
        {
         data["error"]=(bool) false;
         data["orders"].Add(order);
        }

      for(int i=0; i<ordersTotal; i++)
        {
         if(myorder.Select(OrderGetTicket(i)))
           {
            order["id"]=(string) myorder.Ticket();
            order["magic"]=OrderGetInteger(ORDER_MAGIC);
            order["symbol"]=OrderGetString(ORDER_SYMBOL);
            order["type"]=EnumToString(ENUM_ORDER_TYPE(OrderGetInteger(ORDER_TYPE)));
            order["time_setup"]=OrderGetInteger(ORDER_TIME_SETUP);
            order["open"]=OrderGetDouble(ORDER_PRICE_OPEN);
            order["stoploss"]=OrderGetDouble(ORDER_SL);
            order["takeprofit"]=OrderGetDouble(ORDER_TP);
            order["volume"]=OrderGetDouble(ORDER_VOLUME_INITIAL);

            data["error"]=(bool) false;
            data["orders"].Add(order);
           }
         // Error handling
         CheckError(__FUNCTION__);
        }
     }

   string t=data.Serialize();
   if(debug)
      Print(t);
   InformClientSocket(dataSocket,t);
  }

//+------------------------------------------------------------------+
//| Trading module                                                   |
//+------------------------------------------------------------------+
void TradingModule(CJAVal &dataObject)
  {
   mControl.mResetLastError();
   CTrade trade;

   string   actionType = dataObject["actionType"].ToStr();
   string   symbol=dataObject["symbol"].ToStr();
   SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
   CheckError(__FUNCTION__);

   int      idNimber=dataObject["id"].ToInt();
   double   volume=dataObject["volume"].ToDbl();
   double   SL=dataObject["stoploss"].ToDbl();
   double   TP=dataObject["takeprofit"].ToDbl();
   double   price=NormalizeDouble(dataObject["price"].ToDbl(),_Digits);
   double   deviation=dataObject["deviation"].ToDbl();
   string   comment=dataObject["comment"].ToStr();

// Order expiration section
   ENUM_ORDER_TYPE_TIME exp_type = ORDER_TIME_GTC;
   datetime expiration = 0;
   if(dataObject["expiration"].ToInt() != 0)
     {
      exp_type = ORDER_TIME_SPECIFIED;
      expiration=dataObject["expiration"].ToInt();
     }

// Market orders
   if(actionType=="ORDER_TYPE_BUY" || actionType=="ORDER_TYPE_SELL")
     {
      ENUM_ORDER_TYPE orderType=ORDER_TYPE_BUY;
      price = SymbolInfoDouble(symbol,SYMBOL_ASK);
      if(actionType=="ORDER_TYPE_SELL")
        {
         orderType=ORDER_TYPE_SELL;
         price=SymbolInfoDouble(symbol,SYMBOL_BID);
        }

      if(trade.PositionOpen(symbol,orderType,volume,price,SL,TP,comment))
        {
         OrderDoneOrError(false, __FUNCTION__, trade);
         return;
        }
     }

// Pending orders
   else
      if(actionType=="ORDER_TYPE_BUY_LIMIT" || actionType=="ORDER_TYPE_SELL_LIMIT" || actionType=="ORDER_TYPE_BUY_STOP" || actionType=="ORDER_TYPE_SELL_STOP")
        {
         if(actionType=="ORDER_TYPE_BUY_LIMIT")
           {
            if(trade.BuyLimit(volume,price,symbol,SL,TP,ORDER_TIME_GTC,expiration,comment))
              {
               OrderDoneOrError(false, __FUNCTION__, trade);
               return;
              }
           }
         else
            if(actionType=="ORDER_TYPE_SELL_LIMIT")
              {
               if(trade.SellLimit(volume,price,symbol,SL,TP,ORDER_TIME_GTC,expiration,comment))
                 {
                  OrderDoneOrError(false, __FUNCTION__, trade);
                  return;
                 }
              }
            else
               if(actionType=="ORDER_TYPE_BUY_STOP")
                 {
                  if(trade.BuyStop(volume,price,symbol,SL,TP,ORDER_TIME_GTC,expiration,comment))
                    {
                     OrderDoneOrError(false, __FUNCTION__, trade);
                     return;
                    }
                 }
               else
                  if(actionType=="ORDER_TYPE_SELL_STOP")
                    {
                     if(trade.SellStop(volume,price,symbol,SL,TP,ORDER_TIME_GTC,expiration,comment))
                       {
                        OrderDoneOrError(false, __FUNCTION__, trade);
                        return;
                       }
                    }
        }
      // Position modify
      else
         if(actionType=="POSITION_MODIFY")
           {
            if(trade.PositionModify(idNimber,SL,TP))
              {
               OrderDoneOrError(false, __FUNCTION__, trade);
               return;
              }
           }
         // Position close partial
         else
            if(actionType=="POSITION_PARTIAL")
              {
               if(trade.PositionClosePartial(idNimber,volume))
                 {
                  OrderDoneOrError(false, __FUNCTION__, trade);
                  return;
                 }
              }
            // Position close by id
            else
               if(actionType=="POSITION_CLOSE_ID")
                 {
                  if(trade.PositionClose(idNimber))
                    {
                     OrderDoneOrError(false, __FUNCTION__, trade);
                     return;
                    }
                 }
               // Position close by symbol
               else
                  if(actionType=="POSITION_CLOSE_SYMBOL")
                    {
                     if(trade.PositionClose(symbol))
                       {
                        OrderDoneOrError(false, __FUNCTION__, trade);
                        return;
                       }
                    }
                  // Modify pending order
                  else
                     if(actionType=="ORDER_MODIFY")
                       {
                        if(trade.OrderModify(idNimber,price,SL,TP,ORDER_TIME_GTC,expiration))
                          {
                           OrderDoneOrError(false, __FUNCTION__, trade);
                           return;
                          }
                       }
                     // Cancel pending order
                     else
                        if(actionType=="ORDER_CANCEL")
                          {
                           if(trade.OrderDelete(idNimber))
                             {
                              OrderDoneOrError(false, __FUNCTION__, trade);
                              return;
                             }
                          }
                        // Action type dosen't exist
                        else
                          {
                           mControl.mSetUserError(65538, GetErrorID(65538));
                           CheckError(__FUNCTION__);
                          }

// This part of the code runs if order was not completed
   OrderDoneOrError(true, __FUNCTION__, trade);
  }

//+------------------------------------------------------------------+
//| Return a description of the trade transaction type               |
//+------------------------------------------------------------------+
string TradeTransactionTypeDescription(const ENUM_TRADE_TRANSACTION_TYPE transaction,const bool ext_descr=false)
  {
//--- "Cut out" the transaction type from the string obtained from enum
   string res=StringSubstr(EnumToString(transaction),18);
//--- Convert all obtained symbols to lower case and replace the first letter from small to capital
   if(res.Lower())
      res.SetChar(0,ushort(res.GetChar(0)-0x20));
//--- Replace all underscore characters with space in the resulting line
   StringReplace(res,"_"," ");
   string descr="";
   switch(transaction)
     {
      case TRADE_TRANSACTION_ORDER_ADD       :  descr=" (Adding a new open order)";                                                                   break;
      case TRADE_TRANSACTION_ORDER_UPDATE    :  descr=" (Updating an open order)";                                                                    break;
      case TRADE_TRANSACTION_ORDER_DELETE    :  descr=" (Removing an order from the list of the open ones)";                                          break;
      case TRADE_TRANSACTION_DEAL_ADD        :  descr=" (Adding a deal to the history)";                                                              break;
      case TRADE_TRANSACTION_DEAL_UPDATE     :  descr=" (Updating a deal in the history)";                                                            break;
      case TRADE_TRANSACTION_DEAL_DELETE     :  descr=" (Deleting a deal from the history)";                                                          break;
      case TRADE_TRANSACTION_HISTORY_ADD     :  descr=" (Adding an order to the history as a result of execution or cancellation)";                   break;
      case TRADE_TRANSACTION_HISTORY_UPDATE  :  descr=" (Changing an order located in the orders history)";                                           break;
      case TRADE_TRANSACTION_HISTORY_DELETE  :  descr=" (Deleting an order from the orders history)";                                                 break;
      case TRADE_TRANSACTION_POSITION        :  descr=" (Changing a position not related to a deal execution)";                                       break;
      case TRADE_TRANSACTION_REQUEST         :  descr=" (The trade request has been processed by a server and processing result has been received)";  break;
      default: break;
     }
   return res+(!ext_descr ? "" : descr);
   /* Sample output:
      Order add (Adding a new open order)
   */
  }

//+------------------------------------------------------------------+
//| Returns transaction textual description                          |
//+------------------------------------------------------------------+
string TransactionDescription(const MqlTradeTransaction &trans)
  {
//--- 
   string desc=EnumToString(trans.type)+"\r\n";
   desc+="Symbol: "+trans.symbol+"\r\n";
   desc+="Deal ticket: "+(string)trans.deal+"\r\n";
   desc+="Deal type: "+EnumToString(trans.deal_type)+"\r\n";
   desc+="Order ticket: "+(string)trans.order+"\r\n";
   desc+="Order type: "+EnumToString(trans.order_type)+"\r\n";
   desc+="Order state: "+EnumToString(trans.order_state)+"\r\n";
   desc+="Order time type: "+EnumToString(trans.time_type)+"\r\n";
   desc+="Order expiration: "+TimeToString(trans.time_expiration)+"\r\n";
   desc+="Price: "+StringFormat("%G",trans.price)+"\r\n";
   desc+="Price trigger: "+StringFormat("%G",trans.price_trigger)+"\r\n";
   desc+="Stop Loss: "+StringFormat("%G",trans.price_sl)+"\r\n";
   desc+="Take Profit: "+StringFormat("%G",trans.price_tp)+"\r\n";
   desc+="Volume: "+StringFormat("%G",trans.volume)+"\r\n";
   desc+="Position: "+(string)trans.position+"\r\n";
   desc+="Position by: "+(string)trans.position_by+"\r\n";
//--- return the obtained string
   return desc;
  }

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {

    ENUM_TRADE_TRANSACTION_TYPE  trans_type=trans.type;
    // string desc = TradeTransactionTypeDescription(trans_type, true);
    // Print(desc);
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
    {
      CJAVal data, transaction, req, res;
      // Fill transaction data
      transaction["type"]=EnumToString(trans.type);
      transaction["symbol"]=(string) trans.symbol;
      transaction["deal_ticket"]=(int) trans.deal;
      transaction["deal_type"]=EnumToString(trans.deal_type);
      transaction["order_ticket"]=(int) trans.order;
      transaction["order_type"]=EnumToString(trans.order_type);
      transaction["order_state"]=EnumToString(trans.order_state);
      transaction["time_type"]=EnumToString(trans.time_type);
      transaction["time_expiration"]=TimeToString(trans.time_expiration);
      transaction["price"]=(double) trans.price;
      transaction["price_trigger"]=(double) trans.price_trigger;
      transaction["sl"]=(double) trans.price_sl;
      transaction["tp"]=(double) trans.price_tp;
      transaction["volume"]=(double) trans.volume;
      transaction["position"]=(int) trans.position;
      transaction["position_by"]=(int) trans.position_by;
  
      // Fill request data
      req["action"]=EnumToString(request.action);
      req["order"]=(int) request.order;
      req["symbol"]=(string) request.symbol;
      req["volume"]=(double) request.volume;
      req["price"]=(double) request.price;
      req["stoplimit"]=(double) request.stoplimit;
      req["sl"]=(double) request.sl;
      req["tp"]=(double) request.tp;
      req["deviation"]=(int) request.deviation;
      req["type"]=EnumToString(request.type);
      req["type_filling"]=EnumToString(request.type_filling);
      req["type_time"]=EnumToString(request.type_time);
      req["expiration"]=(int) request.expiration;
      req["comment"]=(string) request.comment;
      req["position"]=(int) request.position;
      req["position_by"]=(int) request.position_by;
  
      // Fill result data
      res["retcode"]=(int) result.retcode;
      res["result"]=(string) GetRetcodeID(result.retcode);
      res["deal"]=(int) result.order;
      res["order"]=(int) result.order;
      res["volume"]=(double) result.volume;
      res["price"]=(double) result.price;
      res["comment"]=(string) result.comment;
      res["request_id"]=(int) result.request_id;
      res["retcode_external"]=(int) result.retcode_external;
  
      data["transaction"].Set(transaction);
      data["request"].Set(req);
      data["result"].Set(res);
  
      string t=data.Serialize();
      if(debug)
         Print(t);
      InformClientSocket(streamSocket,t);
  
      string desc = TransactionDescription(trans);
      Print(desc);
    }

  //  switch(trans.type)
  //    {
  //     case  TRADE_TRANSACTION_REQUEST:
  //       {
  //        CJAVal data, req, res;

  //        req["action"]=EnumToString(request.action);
  //        req["order"]=(int) request.order;
  //        req["symbol"]=(string) request.symbol;
  //        req["volume"]=(double) request.volume;
  //        req["price"]=(double) request.price;
  //        req["stoplimit"]=(double) request.stoplimit;
  //        req["sl"]=(double) request.sl;
  //        req["tp"]=(double) request.tp;
  //        req["deviation"]=(int) request.deviation;
  //        req["type"]=EnumToString(request.type);
  //        req["type_filling"]=EnumToString(request.type_filling);
  //        req["type_time"]=EnumToString(request.type_time);
  //        req["expiration"]=(int) request.expiration;
  //        req["comment"]=(string) request.comment;
  //        req["position"]=(int) request.position;
  //        req["position_by"]=(int) request.position_by;

  //        res["retcode"]=(int) result.retcode;
  //        res["result"]=(string) GetRetcodeID(result.retcode);
  //        res["deal"]=(int) result.order;
  //        res["order"]=(int) result.order;
  //        res["volume"]=(double) result.volume;
  //        res["price"]=(double) result.price;
  //        res["comment"]=(string) result.comment;
  //        res["request_id"]=(int) result.request_id;
  //        res["retcode_external"]=(int) result.retcode_external;

  //        data["request"].Set(req);
  //        data["result"].Set(res);

  //        string t=data.Serialize();
  //        if(debug)
  //           Print(t);
  //        InformClientSocket(streamSocket,t);
  //       }
  //     break;
  //     default:
  //     {
  //        string desc = TransactionDescription(trans);
  //        Print(desc);
  //      }
  //      break;
    //  }
  }
//+------------------------------------------------------------------+
