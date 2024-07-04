#property link      "CEO Neo-Bite Wave"
#property version   "Nova Noir Bank"

#include <Trade/Trade.mqh>

double Lots=0.1;
int takeProfits=100;
int stopLoss=100;
int magic=11;

CTrade trade;

int OnInit(){

   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){

}

void OnTick(){

   //trade
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   
   ask=NormalizeDouble(ask,_Digits);
   bid=NormalizeDouble(bid,_Digits);
   
   //buying
   double tpB=ask+takeProfits*_Point;
   double slB=ask-stopLoss*_Point;
   
   tpB=NormalizeDouble(tpB,_Digits);
   slB=NormalizeDouble(slB,_Digits);
   
   //selling
   double tpS=bid-takeProfits*_Point;
   double slS=bid+takeProfits*_Point;
   
   tpS=NormalizeDouble(tpS,_Digits);
   slS=NormalizeDouble(slS,_Digits);
   
   //Higher High --> Higher Low, Lower High --> Lower Low
   double high=iHigh(_Symbol,PERIOD_M15,1);
   high=NormalizeDouble(high,_Digits);
  
   double low=iLow(_Symbol,PERIOD_M15,1);
   low=NormalizeDouble(low,_Digits);
   
   //MACD indicator Code=
   double MACDMainLine[];
   double MACDSignalLine[];
   
   int MACDDef= iMACD(_Symbol,PERIOD_M15,12,26,9,PRICE_CLOSE);
   
   ArraySetAsSeries(MACDMainLine,true);
   ArraySetAsSeries(MACDSignalLine,true);
   
   CopyBuffer(MACDDef,0,0,3,MACDMainLine);
   CopyBuffer(MACDDef,1,0,3,MACDSignalLine);
   
   float MACDMainLineVal= (MACDMainLine[0]);
   float MACDSignalLineVal= (MACDSignalLine[0]);
   
   /*
   Strategy One=
   MACD main line > 0= Bullish Setup
   MACD main line < 0= Bearish Setup
   */
   if(MACDMainLineVal>0){
     Comment("Bullish Setup as MACD mainline is ",MACDMainLineVal);
   }
   if(MACDMainLineVal<0){
     Comment("Bearish Setup as MACD mainline is ",MACDMainLineVal);
   }
   
   //Stop infinite Orders
   int totalPositions = PositionsTotal();
   bool orderOpenBuy = false;
   bool orderOpenSell = false;

   for(int i = totalPositions - 1; i >= 0; i--) {
      if(PositionSelectByTicket(i)){
          if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == magic){
              if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY){
                 orderOpenBuy = true;
              }else if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL){
                 orderOpenSell = true;
              }
          }
      }
   }
   
   /*
   Strategy Two=
   MACD main line > MACD signal line = Buying signal
   MACD main line < MACD signal line = Shorting signal
   */
   if(MACDMainLineVal>MACDSignalLineVal && !orderOpenBuy){
     //buying
     trade.Buy(Lots,_Symbol,ask,slB,tpB);
   }
   if(MACDMainLineVal<MACDSignalLineVal && !orderOpenSell){
     //selling
     trade.Sell(Lots,_Symbol,bid,slS,tpS);
   } 
   
   //Modify the stopLoss
   for(int i=PositionsTotal()-1; i>=0; i--){
    ulong posTicket=PositionGetTicket(i);
    CPositionInfo pos;
    if(pos.SelectByTicket(posTicket)){
      if(pos.PositionType()==POSITION_TYPE_BUY){
        if(low>pos.StopLoss()){
          trade.PositionModify(pos.Ticket(),low,pos.TakeProfit());
        }
      }
    }else if(pos.PositionType()==POSITION_TYPE_SELL){
      if(high<pos.StopLoss()){
        trade.PositionModify(pos.Ticket(),high,pos.TakeProfit());
      }
    }
  }
}