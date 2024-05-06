//+------------------------------------------------------------------+
//|                                                    pyconnect.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

int socket;
int lrlenght = 100;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
string socketreceive(int sock,int timeout)
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
void drawlr(string points)
  {
   string res[];
   StringSplit(points,' ',res);

   if(ArraySize(res)==2)
     {
      Print(StringToDouble(res[0]));
      Print(StringToDouble(res[1]));
      datetime temp[];
      CopyTime(Symbol(),Period(),TimeCurrent(),lrlenght,temp);
      ObjectCreate(0,"regrline",OBJ_TREND,0,TimeCurrent(),NormalizeDouble(StringToDouble(res[0]),_Digits),temp[0],NormalizeDouble(StringToDouble(res[1]),_Digits));
     }
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("OnInit");
   socket=SocketCreate();

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print("OnDeinit");
   SocketClose(socket);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   Print("OnTick");
   if(socket!=INVALID_HANDLE)
     {
      if(SocketConnect(socket,"localhost",9090,1000))
        {
         Print("Connected to "," localhost",":",9090);
        }
      else
        {
         Print("Connection ","localhost",":",9090," error ",GetLastError());
        }

      double clpr[];
      int copyed = CopyClose(_Symbol,PERIOD_CURRENT,0,lrlenght,clpr);

      string tosend;
      for(int i=0; i<ArraySize(clpr); i++)
         tosend+=(string)clpr[i]+" ";
      string received;
      received = socksend(socket, tosend) ? socketreceive(socket, 10) : "";
      drawlr(received);
     }
   else
      Print("Socket creation error ",GetLastError());
  }
//+------------------------------------------------------------------+
