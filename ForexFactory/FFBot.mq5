//+------------------------------------------------------------------+
//|                                                  NewsScalper.mq5 |
//|                        Copyright 2020, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

   int Stoploss = 25;
   int Takeprofit = 80;   
   int OrderDiff = 60;

   string filename = "MyDataFile";
   string stuff[];
   string times[];
   string currency[];
   datetime testtime = D'2020.03.04 13:21:00';
   string symbol = Symbol();
   string Eur_Usd = "EURUSD";


   
   string sep=",";                // A separator as a character
   ushort u_sep=StringGetCharacter(sep,0);
   string sem=";";                // A separator as a character
   ushort u_sem=StringGetCharacter(sem,0);
   
   
   void ReadFileToAlert(string FileName){
      int h=FileOpen(FileName,FILE_READ|FILE_ANSI|FILE_TXT);
      int numReports = StringToInteger(FileReadString(h));
      ArrayResize(stuff,numReports);
      int count=0;
      if(h==INVALID_HANDLE){
         Alert("Error opening file");
         return;
      }   
      while(!FileIsEnding(h)){
           string str   = FileReadString(h);
           Print(str);
           stuff[count] = str;
           count++;
   
      }
      FileClose(h);
      }

   bool isPositionOpenAndNoOrders (string symbol)
   {
     int postot = IntegerToString(PositionsTotal());
     int numPos =0;
     int numOrd =0;
     for(int i=OrdersTotal()-1; i>=0; i--)
      {
         ulong ordTicket=OrderGetTicket(i);
         if(OrderSelect(ordTicket) && OrderGetString(ORDER_SYMBOL) == symbol)
            numOrd++;
      }
      for(int i=PositionsTotal()-1; i>=0; i--)
         {
         //ulong posTicket=PositionGetTicket;
         if(PositionSelect(symbol))
            numPos++;
         }

         if(numPos==1 && numOrd==1)
         {
         deletepending();
         }
         if(numPos==0 && numOrd==0)
         {
         return(true);
         }
      else return (false);
   }
   
   
   
void deletepending()
  {
      int ord_total=OrdersTotal();
      for(int i=ord_total-1;i>=0;i--)
        {
         ulong ticket=OrderGetTicket(i);
         if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL)==Symbol())
           {
            CTrade *trade=new CTrade();
            trade.OrderDelete(ticket);
            delete trade;
           }
        }
   return;
  }
  
datetime plusFive(void)
   {
      datetime newTime = TimeCurrent()+PeriodSeconds(PERIOD_M10);
      return(newTime);
   }
   
void buylimit (string Sym) {  
         MqlTradeRequest requestBuy={0};
         MqlTradeResult  resultBuy={0};
         requestBuy.action       = TRADE_ACTION_PENDING;                                  // type of trade operation
         requestBuy.symbol       = Sym;                                                   // symbol
         requestBuy.volume       = 0.1;                                                   // volume of 0.1 lot
         requestBuy.deviation    = 2;                                                     // allowed deviation from the price
         requestBuy.type_time    = ORDER_TIME_SPECIFIED;
         requestBuy.expiration   = plusFive();
         requestBuy.magic        = 123456;                                                // MagicNumber of the order                                   
         double priceBuy;                                                                 // order triggering price
         double pointBuy         = SymbolInfoDouble(Sym,SYMBOL_POINT);                    // value of point
         int digitsBuy           = SymbolInfoInteger(Sym,SYMBOL_DIGITS);                  // number of decimal places (precision)
         requestBuy.type         = ORDER_TYPE_BUY_STOP;                                   // order type
         priceBuy                = SymbolInfoDouble(Sym,SYMBOL_ASK);                      // price for opening 
         requestBuy.price        = NormalizeDouble(priceBuy,digitsBuy)+(OrderDiff*pointBuy);// normalized opening price    
         requestBuy.sl           = priceBuy-(Stoploss*pointBuy);                                               // Stop Loss is not specified
         requestBuy.tp           = priceBuy + ((OrderDiff + Takeprofit) * pointBuy);       // Take Profit is not specified
         OrderSend(requestBuy, resultBuy);
}
  
  
void selllimit (string Sym) {
         MqlTradeRequest request={0};
         MqlTradeResult  result={0};
         request.action          = TRADE_ACTION_PENDING;                                   // type of trade operation
         request.symbol          = Sym;                                                    // symbol
         request.volume          = 0.1;                                                    // volume of 0.1 lot
         request.deviation       = 2;                                                      // allowed deviation from the price
         request.magic           = 234567;                                                 // MagicNumber of the order
         request.type_time       = ORDER_TIME_SPECIFIED;
         request.expiration      = plusFive();
         double price;                                                                     // order triggering price
         double point            = SymbolInfoDouble(Sym,SYMBOL_POINT);                     // value of point
         int digits              = SymbolInfoInteger(Sym,SYMBOL_DIGITS);                   // number of decimal places (precision)
         request.type            = ORDER_TYPE_SELL_STOP;                                   // order type
         price                   = SymbolInfoDouble(Sym,SYMBOL_BID)-(OrderDiff*point);      // price for opening 
         request.price           = NormalizeDouble(price,digits);                          // normalized opening price 
         request.sl              = price+(Stoploss * point);                               // Take Profit 
         request.tp              = price-((OrderDiff + Takeprofit) * point);               // Take Profit 
         OrderSend(request, result);
}
   
   
   
   

int OnInit()
  {
//---
   //--- open the file
   ResetLastError();
   int file_handle=FileOpen("MyDataFile",FILE_READ|FILE_BIN|FILE_ANSI);
                           //C:\Users\natep\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075\MQL5\Experts
   if(file_handle!=INVALID_HANDLE)
     {
      PrintFormat("%s file is available for reading","MyDataFile");
      PrintFormat("File path: %s\\Files\\",TerminalInfoString(TERMINAL_DATA_PATH));
      //--- additional variables
      int    str_size;
      string str;
      //--- read data from the file
      while(!FileIsEnding(file_handle))
        {
         //--- find out how many symbols are used for writing the time
         str_size=FileReadInteger(file_handle,INT_VALUE);
         //--- read the string
         str=FileReadString(file_handle,str_size);
         //--- print the string
         PrintFormat(str);
        }
      //--- close the file
      FileClose(file_handle);
      PrintFormat("Data is read, %s file is closed","MyDataFile");
     }
   else
      PrintFormat("Failed to open %s file, Error code = %d","MyDataFile",GetLastError());
   
   ReadFileToAlert(filename);
//   ArrayPrint(stuff);
   
//---
   ArrayResize(times,ArraySize(stuff));
   ArrayResize(currency,ArraySize(stuff));

   for(int i=0; i<ArraySize(stuff); i++){
      string temptime[];
      StringSplit(stuff[i], u_sep, temptime); 
      times[i] = temptime[0];   
      currency[i] = temptime[1];
   }
 
   
   EventSetTimer(PERIOD_D1);

//---
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
    for(int i=0; i<=ArraySize(times)-1; i++) {     
      if(TimeCurrent() == StringToTime(times[i]) + PeriodSeconds(PERIOD_H6)){
            string currencies[];    
            StringSplit(currency[i], u_sem, currencies);
            for(int k=0; k<=ArraySize(currencies)-1; k++){
               isPositionOpenAndNoOrders(currencies[k]);
               selllimit(currencies[k]);
               buylimit(currencies[k]);         
            }
      }
    }



//   for(int i=0; i<=ArraySize(times)-1; i++)
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---

   ReadFileToAlert(filename);
   ArrayResize(times,ArraySize(stuff));
   ArrayResize(currency,ArraySize(stuff));
   for(int i=0; i<ArraySize(stuff); i++){
      string temptime[];
      StringSplit(stuff[i], u_sep, temptime); 
      times[i] = temptime[0];   
      currency[i] = temptime[1];
   }
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
