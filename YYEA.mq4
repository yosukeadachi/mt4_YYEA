//+------------------------------------------------------------------+
//|                                                         YYEA.mq4 |
//|                                    Copyright 2018, Yosuke Adachi |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Yosuke Adachi"
#property link      ""
#property version   "0.1"
#property description ""

struct ZZ_param {
    int depth;
    int deviation;
    int backstep;
};
struct ZZ_result {
    double last;
    double high;
    double low;
};

ZZ_result lastResult;

// //+------------------------------------------------------------------+
// //| Calculate open positions                                         |
// //+------------------------------------------------------------------+
// int CalculateCurrentOrders(string symbol)
// {
//   int buys=0,sells=0;
// //---
//   for(int i=0;i<OrdersTotal();i++)
//     {
//     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==false) break;
//     if(OrderSymbol()==Symbol() && OrderMagicNumber()==MAGICMA)
//       {
//         if(OrderType()==OP_BUY)  buys++;
//         if(OrderType()==OP_SELL) sells++;
//       }
//     }
// //--- return orders volume
//   if(buys>0) return(buys);
//   else       return(-sells);
// }

// //+------------------------------------------------------------------+
// //| Check for open order conditions                                  |
// //+------------------------------------------------------------------+
// void CheckForOpen()
// {
//   double ma;
//   int    res;
// //--- go trading only for first tiks of new bar
//   if(Volume[0]>1) return;
// //--- get Moving Average 
//   ma=iMA(NULL,0,MovingPeriod,MovingShift,MODE_SMA,PRICE_CLOSE,0);
// //--- sell conditions
//   if(Open[1]>ma && Close[1]<ma)
//     {
//     res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
//     return;
//     }
// //--- buy conditions
//   if(Open[1]<ma && Close[1]>ma)
//     {
//     res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
//     return;
//     }
// //---
// }

//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
{

  ZZ_param zzParamLong = { 15, 5, 3};
  ZZ_param zzParamShort = { 5, 5, 3};
  int _period = PERIOD_M15;
  int _mode = 0;
  int _shift = 0;

  ZZ_result zzResultLong = {0,0,0};
  ZZ_result zzResultShort = {0,0,0};
  zzResultLong.last = iCustom(NULL,_period,"ZigZag",zzParamLong.depth, zzParamLong.deviation, zzParamLong.backstep, _mode+0, _shift);
  zzResultLong.high = iCustom(NULL,_period,"ZigZag",zzParamLong.depth, zzParamLong.deviation, zzParamLong.backstep, _mode+1, _shift);
  zzResultLong.low = iCustom(NULL,_period,"ZigZag",zzParamLong.depth, zzParamLong.deviation, zzParamLong.backstep, _mode+2, _shift);
  zzResultShort.last = iCustom(NULL,_period,"ZigZag",zzParamShort.depth, zzParamShort.deviation, zzParamShort.backstep, _mode+0, _shift);
  zzResultShort.high = iCustom(NULL,_period,"ZigZag",zzParamShort.depth, zzParamShort.deviation, zzParamShort.backstep, _mode+1, _shift);
  zzResultShort.low = iCustom(NULL,_period,"ZigZag",zzParamShort.depth, zzParamShort.deviation, zzParamShort.backstep, _mode+2, _shift);
//   Comment(_tmp0);

  //変動があるか？
  if(zzResultLong.last != 0) {
    //変動が同じか？
    if((zzResultLong.last == zzResultShort.last) &&
        (zzResultLong.high == zzResultShort.high) &&
        (zzResultLong.low == zzResultShort.low))
    {
        // printf("(%d/%d/%d %d:%d:%d) Long:La[%.2f],Hi[%.2f],Lo[%.2f] Short:La[%.2f],Hi[%.2f],Lo[%.2f] Last:La[%.2f],Hi[%.2f],Lo[%.2f]", 
        //     Year(),Month(),Day(),
        //     Hour(),Minute(),Seconds(),
        //     zzResultLong.last,zzResultLong.high,zzResultLong.low,
        //     zzResultShort.last,zzResultShort.high,zzResultShort.low,
        //     lastResult.last,lastResult.high,lastResult.low
        // );
      //保存と違うか？
      if((zzResultLong.high != 0 ) && (lastResult.high != zzResultLong.high))
      {
        lastResult.high = zzResultLong.high;
        printf("(%d/%d/%d %d:%d:%d) last:La[%f],Hi[%f],Lo[%f]", 
            Year(),Month(),Day(),
            Hour(),Minute(),Seconds(),
            lastResult.last,lastResult.high,lastResult.low
        );
      }
      if((zzResultLong.low != 0 ) && (lastResult.low != zzResultLong.low))
      {
        lastResult.low = zzResultLong.low;
        printf("(%d/%d/%d %d:%d:%d) last:La[%f],Hi[%f],Lo[%f]", 
            Year(),Month(),Day(),
            Hour(),Minute(),Seconds(),
            lastResult.last,lastResult.high,lastResult.low
        );
      }
    }
  }

// //--- check for history and trading
//   if(Bars<100 || IsTradeAllowed()==false)
//     return;

// //--- calculate open orders by current symbol
//   if(CalculateCurrentOrders(Symbol())==0) CheckForOpen();
//   else                                    CheckForClose();
// //---
}
//+------------------------------------------------------------------+
