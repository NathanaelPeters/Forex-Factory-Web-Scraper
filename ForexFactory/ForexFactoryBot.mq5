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

   //---As the name suggests, Takeprofit is the amount of potential profit that is set 
   int Takeprofit = 120;   
   
   //---Opposite of Takeprofit, the amount of potential loss
   int Stoploss = 80;

   //---OrderDiff is the difference between the current price and where the pending buy/sell order price is
   int OrderDiff = 60;

   //---Name of the file that contains the times and currency pairs sent over from the python file 
   string filename = "ForexFactoryData";
   
   //---Arrays necessary for extracting the data from MyDataFile
   string Filelines[];
   string times[];
   string currency[];

   //---Creating separators for the data
   string sep=",";                // A separator as a character
   ushort u_sep=StringGetCharacter(sep,0);
   string sem=";";                // A separator as a character
   ushort u_sem=StringGetCharacter(sem,0);
   
   //--- Function to Open and read data
   void ReadFileToAlert(string FileName){
      int h=FileOpen(FileName,FILE_READ|FILE_ANSI|FILE_TXT);
      double numReports = StringToInteger(FileReadString(h));
      ArrayResize(Filelines,numReports);
      int count=0;
      if(h==INVALID_HANDLE){
         Alert("Error opening file");
         return;
      }   
      while(!FileIsEnding(h)){
           string str       = FileReadString(h);
           Print(str);
           Filelines[count] = str;
           count++;
   
      }
         FileClose(h);
      }

   //---Function for checking if other positions are ongoing
   bool isPositionOpenAndNoOrders (string symbol){
     int postot =IntegerToString(PositionsTotal());
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
         if(PositionSelect(symbol))
            numPos++;
         }

         if(numPos==1)
         {
         deletepending();
         }
         if(numPos==0 && numOrd==0)
         {
         return(true);
         }
      else return (false);
   }
   
   
   //---Function for deleting pending orders
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
   
   //---Simple function for adding 10 mins to the current time for expiring pending orders
   datetime plusFive(void)
      {
         datetime newTime = TimeCurrent()+PeriodSeconds(PERIOD_M10);
         return(newTime);
      }
   
   //---I separated the pending Buy/Sell functions for future applications
   void buylimit (string Sym) {  
            MqlTradeRequest requestBuy={0};
            MqlTradeResult  resultBuy={0};
            requestBuy.action       = TRADE_ACTION_PENDING;                                  // type of trade operation
            requestBuy.symbol       = Sym;                                                   // symbol
            requestBuy.volume       = 0.1;                                                   // volume of 0.1 lot
            requestBuy.deviation    = 2;                                                     // allowed deviation from the price
            requestBuy.type_time    = ORDER_TIME_SPECIFIED;
            requestBuy.expiration   = plusFive();
            requestBuy.magic        = 123456;                                                 // MagicNumber of the order                                   
            double pointBuy         = SymbolInfoDouble(Sym,SYMBOL_POINT);                     // value of point
            int digitsBuy           = SymbolInfoInteger(Sym,SYMBOL_DIGITS);                   // number of decimal places (precision)
            requestBuy.type         = ORDER_TYPE_BUY_STOP;                                    // order type
            double priceBuy         = SymbolInfoDouble(Sym,SYMBOL_ASK)+(OrderDiff*pointBuy);  // price for opening 
            requestBuy.price        = NormalizeDouble(priceBuy,digitsBuy);                    // normalized opening price    
            requestBuy.sl           = priceBuy - (Stoploss * pointBuy);                       // Stop Loss is not specified
            requestBuy.tp           = priceBuy + (Takeprofit * pointBuy);                     // Take Profit is not specified
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
            double point            = SymbolInfoDouble(Sym,SYMBOL_POINT);                     // value of point
            int digits              = SymbolInfoInteger(Sym,SYMBOL_DIGITS);                   // number of decimal places (precision)
            request.type            = ORDER_TYPE_SELL_STOP;                                   // order type
            double price            = SymbolInfoDouble(Sym,SYMBOL_BID)-(OrderDiff*point);     // price for opening 
            request.price           = NormalizeDouble(price,digits);                          // normalized opening price 
            request.sl              = price + (Stoploss * point);                               // Take Profit 
            request.tp              = price - (Takeprofit * point);               // Take Profit 
            OrderSend(request, result);
   }

int OnInit()
  {
   //--- On intiation file is opened
   ResetLastError();
   int file_handle=FileOpen("MyDataFile",FILE_READ|FILE_BIN|FILE_ANSI);
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
   
//---Each line of the file is separated into the currency pairs and times
   ArrayResize(times,ArraySize(Filelines));
   ArrayResize(currency,ArraySize(Filelines));
   for(int i=0; i<ArraySize(Filelines); i++){
      string temptime[];
      StringSplit(Filelines[i], u_sep, temptime); 
      times[i] = temptime[0];
      currency[i] = temptime[1];
   }
   
//---Timer is set to recheck the file in 24 hours
   EventSetTimer(PERIOD_D1);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---The OnTick function is triggered when any change occurs in the exchange rate

//---For loop that checks all the times and if time is current time, trigger the pending orders 
    for(int i=0; i<=ArraySize(times)-1; i++) {     
      if(TimeCurrent() <= StringToTime(times[i]) + PeriodSeconds(PERIOD_H6) + PeriodSeconds(PERIOD_H1) + PeriodSeconds(1) && TimeCurrent() >= StringToTime(times[i]) + PeriodSeconds(PERIOD_H6) + PeriodSeconds(PERIOD_H1) - PeriodSeconds(1)){
            string currencies[];    
            StringSplit(currency[i], u_sem, currencies);
            for(int k=0; k<=ArraySize(currencies)-1; k++){
               if(isPositionOpenAndNoOrders(currencies[k])) {
               selllimit(currencies[k]);
               buylimit(currencies[k]);  
               }       
            }
      }
    }
   bool EUR = false;
   bool USD = false;
   bool GBP = false;
   bool CAD = false;
   bool AUD = false;
   bool NZD = false;
   bool JPY = false;
  for(int i=0; i<=ArraySize(currency)-1; i++) {
   for(int i=PositionsTotal()-1; i>=0; i--){
      int EUROrds = 0;
      int USDOrds = 0;
      int GBPOrds = 0;
      int CADOrds = 0;
      int AUDOrds = 0;
      int NZDOrds = 0;
      int JPYOrds = 0;
      ulong ordTicket=PositionGetTicket(i);
      if(PositionSelectByTicket(ordTicket) && PositionGetString(POSITION_SYMBOL) == "EURUSD"){
        EUROrds++;
      }
      if(PositionSelectByTicket(ordTicket) && PositionGetString(POSITION_SYMBOL) == "USDCHF"){
        USDOrds++;
      }      
      if(PositionSelectByTicket(ordTicket) && PositionGetString(POSITION_SYMBOL) == "USDCAD"){
        CADOrds++;
      }
      if(PositionSelectByTicket(ordTicket) && PositionGetString(POSITION_SYMBOL) == "AUDUSD"){
        AUDOrds++;
      }      
      if(PositionSelectByTicket(ordTicket) && PositionGetString(POSITION_SYMBOL) == "NZDUSD"){
        NZDOrds++;
      }
      if(PositionSelectByTicket(ordTicket) && PositionGetString(POSITION_SYMBOL) == "USDJPY"){
        JPYOrds++;
      }       
      if(PositionSelectByTicket(ordTicket) && PositionGetString(POSITION_SYMBOL) == "GBPUSD"){
        GBPOrds++;
      }
      if(EUROrds == 1)
         EUR = true;  
      if(USDOrds == 1)
         USD = true;
      if(CADOrds == 1)
         CAD = true;
      if(NZDOrds == 1)
         NZD = true;
      if(AUDOrds == 1)
         AUD = true;
      if(GBPOrds == 1)
         GBP = true;
   }
  }
  for(int i=0; i<=ArraySize(currency)-1; i++) {
   for(int i=OrdersTotal()-1; i>=0; i--){
      ulong ordTicket=OrderGetTicket(i);
      if(EUR && OrderGetString(ORDER_SYMBOL) == "EURUSD") {
        MqlTradeResult result={0};
        MqlTradeRequest request={0};
        request.symbol           ="EURUSD";
        request.order            =ordTicket;
        request.action           =TRADE_ACTION_REMOVE;
        OrderSend(request,result);
        EUR = true; 
        PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         //--- information about the operation   
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
      }       
      if(USD && OrderGetString(ORDER_SYMBOL) == "USDCHF") {
        MqlTradeResult result={0};
        MqlTradeRequest request={0};
        request.symbol           ="USDCHF";
        request.order            =ordTicket;
        request.action           =TRADE_ACTION_REMOVE;
        OrderSend(request,result);
        PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         //--- information about the operation   
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        USD = true; 
      }        
      if(CAD && OrderGetString(ORDER_SYMBOL) == "USDCAD") {
        MqlTradeResult result={0};
        MqlTradeRequest request={0};
        request.symbol           ="USDCAD";
        request.order            =ordTicket;
        request.action           =TRADE_ACTION_REMOVE;
        OrderSend(request,result); 
        PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         //--- information about the operation   
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
        CAD = true;
      }      
      if(GBP && OrderGetString(ORDER_SYMBOL) == "GBPUSD") {
        MqlTradeResult result={0};
        MqlTradeRequest request={0};
        request.symbol           ="GBPUSD";
        request.order            =ordTicket;
        request.action           =TRADE_ACTION_REMOVE;
        OrderSend(request,result);
        PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         //--- information about the operation   
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order); 
        GBP = true;
      }      
      if(NZD && OrderGetString(ORDER_SYMBOL) == "NZDUSD") {
        MqlTradeResult result={0};
        MqlTradeRequest request={0};
        request.symbol           ="NZDUSD";
        request.order            =ordTicket;
        request.action           =TRADE_ACTION_REMOVE;
        OrderSend(request,result);
        PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         //--- information about the operation   
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order); 
        NZD = true;
      }      
      if(AUD && OrderGetString(ORDER_SYMBOL) == "AUDUSD") {
        MqlTradeResult result={0};
        MqlTradeRequest request={0};
        request.symbol           ="AUDUSD";
        request.order            =ordTicket;
        request.action           =TRADE_ACTION_REMOVE;
        OrderSend(request,result);
        PrintFormat("OrderSend error %d",GetLastError());  // if unable to send the request, output the error code
         //--- information about the operation   
        PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order); 
        AUD = true;
      }      
   }
  }
}
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   //---After the 1 day timer goes off, refill currency/time array with the new times and currency pairs based on the news
   //ReadFileToAlert(filename);
  }