//+------------------------------------------------------------------+
//|                                                         YYEA.mq4 |
//|                                    Copyright 2018, Yosuke Adachi |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Yosuke Adachi"
#property link      ""
#property version   "0.01"
#property description ""

//high low pair
struct HighLowPair {
  double high;
  double low;
};

//zigzag
struct ZZ_param {
    int depth;
    int deviation;
    int backstep;
};
struct ZZ_result {
    double last;
    HighLowPair pair;
};

ZZ_result lastResult;

//HighLowLines
HighLowPair hllResults[4];

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
  int _period = PERIOD_M15;

  //HighLowLines
  for(int i = 0; i < ArraySize(hllResults); i++) {
    hllResults[i].high = iCustom(NULL,_period,"HighLowLines",(i*2)+0,0);
    hllResults[i].low = iCustom(NULL,_period,"HighLowLines",(i*2)+1,0);
  }
  // printf("%s highlow:0[H%.2f:L%.2f],1[H%.2f:L%.2f],2[H%.2f:L%.2f],3[H%.2f:L%.2f]", 
  //     generateTickTimeStr(),
  //     hllResults[0].high,hllResults[0].low,
  //     hllResults[1].high,hllResults[1].low,
  //     hllResults[2].high,hllResults[2].low,
  //     hllResults[3].high,hllResults[3].low
  // );

  //ZigZag
  ZZ_param zzpl = { 15, 5, 3};
  ZZ_param zzps = { 5, 5, 3};
  int _mode = 0;
  int _shift = 0;

  ZZ_result zzResultLong = {0,{0,0}};
  ZZ_result zzResultShort = {0,{0,0}};
  ZZ_result zzResultLong_1 = {0,{0,0}};
  ZZ_result zzResultShort_1 = {0,{0,0}};
  zzResultLong.last = iCustom(NULL,_period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+0, _shift+0);
  zzResultLong.pair.high = iCustom(NULL,_period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+1, _shift+0);
  zzResultLong.pair.low = iCustom(NULL,_period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+2, _shift+0);
  zzResultShort.last = iCustom(NULL,_period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+0, _shift+0);
  zzResultShort.pair.high = iCustom(NULL,_period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+1, _shift+0);
  zzResultShort.pair.low = iCustom(NULL,_period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+2, _shift+0);

  zzResultLong_1.last = iCustom(NULL,_period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+0, _shift+1);
  zzResultLong_1.pair.high = iCustom(NULL,_period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+1, _shift+1);
  zzResultLong_1.pair.low = iCustom(NULL,_period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+2, _shift+1);
  zzResultShort_1.last = iCustom(NULL,_period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+0, _shift+1);
  zzResultShort_1.pair.high = iCustom(NULL,_period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+1, _shift+1);
  zzResultShort_1.pair.low = iCustom(NULL,_period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+2, _shift+1);

  //変動があるか？
  if(zzResultLong.last != 0) {
    //変動が同じか？
    if((zzResultLong.last == zzResultShort.last) &&
        (zzResultLong.pair.high == zzResultShort.pair.high) &&
        (zzResultLong.pair.low == zzResultShort.pair.low))
    {
      printf("%s 0 Long:La[%.2f],Hi[%.2f],Lo[%.2f] Short:La[%.2f],Hi[%.2f],Lo[%.2f]", 
          generateTickTimeStr(),
          zzResultLong.last,zzResultLong.pair.high,zzResultLong.pair.low,
          zzResultShort.last,zzResultShort.pair.high,zzResultShort.pair.low
      );
      printf("%s 1 Long:La[%.2f],Hi[%.2f],Lo[%.2f] Short:La[%.2f],Hi[%.2f],Lo[%.2f]", 
          generateTickTimeStr(),
          zzResultLong_1.last,zzResultLong_1.pair.high,zzResultLong_1.pair.low,
          zzResultShort_1.last,zzResultShort_1.pair.high,zzResultShort_1.pair.low
      );

      double _rangeOffset[] = {-0.1,0.1};
      //保存と違うか？
      if((zzResultLong.pair.high != 0 ) && (lastResult.pair.high != zzResultLong.pair.high))
      {
        //高値更新
        lastResult.pair.high = zzResultLong.pair.high;
        printf("%s update:High[%f]", 
            generateTickTimeStr(),lastResult.pair.high
        );
        // if(isTouch(hllResults, lastResult, _rangeOffset)) {
        //   printf("touch high %f", lastResult.pair.high);
        //   Comment(lastResult.pair.high);
        // }
      }
      if((zzResultLong.pair.low != 0 ) && (lastResult.pair.low != zzResultLong.pair.low))
      {
        //安値更新
        lastResult.pair.low = zzResultLong.pair.low;
        printf("%s update:Low[%f]", 
            generateTickTimeStr(),lastResult.pair.low
        );
        // if(isTouch(hllResults, lastResult, _rangeOffset)) {
        //   printf("touch low %f", lastResult.pair.low);
        //   Comment(lastResult.pair.low);
        // }
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

//+------------------------------------------------------------------+
//Utility
bool isTouch(HighLowPair &aHLLResults[], ZZ_result &aZZResult, double &aRangeOffset[]) {
  bool _isTouch = false;
  
  for(int i = 0; i < ArraySize(aHLLResults); i++) {
    HighLowPair _hll = aHLLResults[i];
    double _range[] = {0,0};
    double _target = 0;
    //high
    _range[0] = aRangeOffset[0] + _hll.high;
    _range[1] = aRangeOffset[1] + _hll.high;
    _target = aZZResult.pair.high;
    printf("isToush[%d] high %.3f(%f+%f) < %.3f < %.3f(%f+%f)", i, _range[0], aRangeOffset[0], _hll.high, _target, _range[1], aRangeOffset[1], _hll.high);
    if(_range[0] <= _target && _target <= _range[1]) {
      _isTouch = true;
      break;
    }
    //low
    _range[0] = aRangeOffset[0] + _hll.low;
    _range[1] = aRangeOffset[1] + _hll.low;
    _target = aZZResult.pair.low;
    printf("isToush[%d] low %.3f(%f+%f) < %.3f < %.3f(%f+%f)", i, _range[0], aRangeOffset[0], _hll.low, _target, _range[1], aRangeOffset[1], _hll.low);
    if(_range[0] <= _target && _target <= _range[1]) {
      _isTouch = true;
      break;
    }
  }
  return _isTouch;
}

//+------------------------------------------------------------------+
//Debug
string generateTickTimeStr() {
  string _result = "";
  _result += "(";
  _result += IntegerToString(Year());
  _result += "/";
  _result += IntegerToString(Month());
  _result += "/";
  _result += IntegerToString(Day());
  _result += " ";
  _result += IntegerToString(Hour());
  _result += ":";
  _result += IntegerToString(Minute());
  _result += ":";
  _result += IntegerToString(Seconds());
  _result += ")";
  return _result;
}