//+------------------------------------------------------------------+
//|                                                         Test.mq5 |
//|                             Copyright 2000-2024, Gabriele Ligetta|
//|                                         https://www.gligetta.dev |
//+------------------------------------------------------------------+
#property copyright "Copyright 2000-2024, Gabriele Ligetta"
#property link      "https://www.gligetta.dev"
#property version   "0.01"

#include <Trade/Trade.mqh>;

double LOTS = 0.1;
double STOP_LOSS_PRICE;
int STOP_LOSS_SIZE = 20;
int STOP_LOSS_MIN;
int STOP_LOSS_PIPS;
int PIP_MULTIPLIER;
double TAKE_PROFIT_PRICE;
int TAKE_PROFIT_PIPS;
double BID_PRICE;
double ASK_PRICE;
double SMA_T1;
double SMA_T2;
double SMA_FAST_T1;
double SMA_FAST_T2;
double SMA_SLOW_T1;
double SMA_SLOW_T2;
MqlRates SYMBOL_PRICES[];
CTrade TRADE_COMMANDS;
double FAST_SMA_Vector [];
int FAST_SMA_Handler;
int FAST_SMA_Buffer_Value;
double SLOW_SMA_Vector [];
int SLOW_SMA_Handler;
int SLOW_SMA_Buffer_Value;
int PRICES_DATA;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   ArraySetAsSeries(FAST_SMA_Vector, true);
   ArraySetAsSeries(SLOW_SMA_Vector, true);
   ArraySetAsSeries(SYMBOL_PRICES, true);
   FAST_SMA_Handler = iMA(_Symbol, _Period, 15, 0, MODE_SMA, PRICE_CLOSE);
   SLOW_SMA_Handler = iMA(_Symbol, _Period, 30, 0, MODE_SMA, PRICE_CLOSE);
   PIP_MULTIPLIER = (_Digits == 5 || _Digits == 3 || _Digits == 1) ? 10 : 1;
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   IndicatorRelease(FAST_SMA_Handler);
   IndicatorRelease(SLOW_SMA_Handler);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//variables initialization
   STOP_LOSS_PIPS = STOP_LOSS_SIZE * PIP_MULTIPLIER;
   TAKE_PROFIT_PIPS = 2 * STOP_LOSS_PIPS;
   PRICES_DATA = CopyRates(_Symbol, _Period, 0, 10, SYMBOL_PRICES);
   BID_PRICE = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ASK_PRICE = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   FAST_SMA_Buffer_Value = CopyBuffer(FAST_SMA_Handler, _Period, 0, 3, FAST_SMA_Vector);
   SMA_FAST_T1 = FAST_SMA_Vector[1];
   SMA_FAST_T2 = FAST_SMA_Vector[2];
   SLOW_SMA_Buffer_Value = CopyBuffer(SLOW_SMA_Handler, _Period, 0, 3, SLOW_SMA_Vector);
   SMA_SLOW_T1 = SLOW_SMA_Vector[1];
   SMA_SLOW_T2 = SLOW_SMA_Vector[2];
//exit market rules
   if(PositionSelect(_Symbol) == true) {
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         //for long positions
         if((SMA_FAST_T1 < SMA_SLOW_T1) && (SMA_FAST_T2 > SMA_SLOW_T2)) {
            TRADE_COMMANDS.PositionClose(_Symbol);
         }
      }
      //for short positions
      if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         if((SMA_FAST_T1 > SMA_SLOW_T1) && (SMA_FAST_T2 < SMA_SLOW_T2)) {
            TRADE_COMMANDS.PositionClose(_Symbol);
         }
      }
   }
//enter market rules
   else if(PositionSelect(_Symbol) == false) {
      //for long positions
      STOP_LOSS_MIN = (int)(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
      STOP_LOSS_PIPS = (MathMax(STOP_LOSS_SIZE * PIP_MULTIPLIER, STOP_LOSS_MIN));
      if((SMA_FAST_T1 > SMA_SLOW_T1) && (SMA_FAST_T2 < SMA_SLOW_T2)) {
         STOP_LOSS_PRICE = ASK_PRICE - STOP_LOSS_PIPS * _Point;
         TAKE_PROFIT_PRICE = ASK_PRICE + TAKE_PROFIT_PIPS * _Point;
         TRADE_COMMANDS.PositionOpen(_Symbol, ORDER_TYPE_BUY, LOTS, ASK_PRICE, STOP_LOSS_PRICE, TAKE_PROFIT_PRICE, "apro trade long");
      }
      //for short positions
      else if((SMA_FAST_T1 < SMA_SLOW_T1) && (SMA_FAST_T2 > SMA_SLOW_T2)) {
         STOP_LOSS_PRICE = BID_PRICE + STOP_LOSS_PIPS * _Point;
         TAKE_PROFIT_PRICE = BID_PRICE - TAKE_PROFIT_PIPS * _Point;
         TRADE_COMMANDS.PositionOpen(_Symbol, ORDER_TYPE_SELL, LOTS, ASK_PRICE, STOP_LOSS_PRICE, TAKE_PROFIT_PRICE, "apro trade long");
      }
   }
//modify position rules
   if(PositionSelect(_Symbol) == true) {
      STOP_LOSS_MIN = (int)(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + SymbolInfoInteger(_Symbol, SYMBOL_SPREAD));
      STOP_LOSS_PIPS = (MathMax(STOP_LOSS_SIZE * PIP_MULTIPLIER, STOP_LOSS_MIN));
      TAKE_PROFIT_PIPS = STOP_LOSS_PIPS;
      if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
         if (ASK_PRICE == PositionGetDouble(POSITION_PRICE_OPEN) + (0.8 * (PositionGetDouble(POSITION_TP) - PositionGetDouble(POSITION_PRICE_OPEN)))) {
            STOP_LOSS_PRICE = PositionGetDouble(POSITION_PRICE_OPEN);
            TAKE_PROFIT_PRICE = ASK_PRICE + TAKE_PROFIT_PIPS * _Point;
            TRADE_COMMANDS.PositionModify(_Symbol, STOP_LOSS_PRICE, TAKE_PROFIT_PRICE);
         }
      }
      if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
         if (BID_PRICE == PositionGetDouble(POSITION_PRICE_OPEN) - (0.8 * (PositionGetDouble(POSITION_PRICE_OPEN) - PositionGetDouble(POSITION_TP)))) {
            STOP_LOSS_PRICE = PositionGetDouble(POSITION_PRICE_OPEN);
            TAKE_PROFIT_PRICE = BID_PRICE - TAKE_PROFIT_PIPS * _Point;
            TRADE_COMMANDS.PositionModify(_Symbol, STOP_LOSS_PRICE, TAKE_PROFIT_PRICE);
         }
      }
   }
}
//+------------------------------------------------------------------+
