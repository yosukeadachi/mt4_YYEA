//+------------------------------------------------------------------+
//|                                                         YYEA.mq4 |
//|                                    Copyright 2018, Yosuke Adachi |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Yosuke Adachi"
#property link      ""
#property version   "0.01"
#property description ""

int period = PERIOD_M5;

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

struct ZZ_point {
  int barIds[2];    //バーID
  double values[2]; //現在=0 一つ前=1
};
ZZ_point zzPointLong;
ZZ_point zzPointShort;

//HighLowLines
HighLowPair hllResults[4];

//Order
#define MAGICMA 20180826
int ticket = -1;
bool isEntry = false;
double closePrise = 0;

//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
  //HighLowLines
  for(int i = 0; i < ArraySize(hllResults); i++) {
    hllResults[i].high = iCustom(NULL,period,"HighLowLines",(i*2)+0,0);
    hllResults[i].low = iCustom(NULL,period,"HighLowLines",(i*2)+1,0);
  }
  // printf("%s highlow:0[H%.3f:L%.3f],1[H%.3f:L%.3f],2[H%.3f:L%.3f],3[H%.3f:L%.3f]", 
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

  //転換点を取得
  int bar = 0;
  int pointIndex = 0;
  //Long
  pointIndex = 0;
  for(bar = 0; bar < Bars; bar++) {
    ZZ_result zzResultLong = {0,{0,0}};
    zzResultLong.last = iCustom(NULL,period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+0, bar);
    zzResultLong.pair.high = iCustom(NULL,period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+1, bar);
    zzResultLong.pair.low = iCustom(NULL,period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+2, bar);
    if(zzResultLong.last != 0) {
      zzPointLong.values[pointIndex] = zzResultLong.last;
      zzPointLong.barIds[pointIndex] = bar;
      pointIndex++;
      if(pointIndex >= ArraySize(zzPointLong.values)) {
        break;
      }
    }
  }
  // printf("Long [0](%d:%f) [1](%d:%f)", 
  //   zzPointLong.barIds[0], zzPointLong.values[0],
  //   zzPointLong.barIds[1], zzPointLong.values[1]);
  //Short
  pointIndex = 0;
  for(bar = 0; bar < Bars; bar++) {
    ZZ_result zzResultShort = {0,{0,0}};
    zzResultShort.last = iCustom(NULL,period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+0, bar);
    zzResultShort.pair.high = iCustom(NULL,period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+1, bar);
    zzResultShort.pair.low = iCustom(NULL,period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+2, bar);
    if(zzResultShort.last != 0) {
      zzPointShort.values[pointIndex] = zzResultShort.last;
      zzPointShort.barIds[pointIndex] = bar;
      pointIndex++;
      if(pointIndex >= ArraySize(zzPointShort.values)) {
        break;
      }
    }
  }
  // printf("Short [0](%d:%f) [1](%d:%f)", 
  //   zzPointShort.barIds[0], zzPointShort.values[0],
  //   zzPointShort.barIds[1], zzPointShort.values[1]);

  //エントリーチェック
  if((zzPointLong.values[0] == zzPointShort.values[0]) &&
     (zzPointLong.barIds[0] == 1) &&
     (zzPointShort.barIds[0] == 1))
  {
    printf("Long [0](%d:%f) [1](%d:%f)", 
      zzPointLong.barIds[0], zzPointLong.values[0],
      zzPointLong.barIds[1], zzPointLong.values[1]);
    printf("Short [0](%d:%f) [1](%d:%f)", 
      zzPointShort.barIds[0], zzPointShort.values[0],
      zzPointShort.barIds[1], zzPointShort.values[1]);

    double _rangeOffset[] = {-0.05,0.05};
    double _target = zzPointLong.values[0];
    if(isTouch(hllResults, _target, _rangeOffset)) {
      isEntry = true;
      printf("touch %f", _target);
      Comment(_target);
    }
  }

  //エントリー処理
  if(ticket == -1) {
    //Order Open
    ticket = CheckSendOrder(zzPointLong);
    // printf("CheckSendOrder ticket:%d", ticket);
  } else {
    //Order Close
    bool _result = CheckCloseOrder(ticket);
    if(_result) {
      ticket = -1;
    }
    // printf("CheckCloseOrder _result:%d", _result);
  }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//Order
//+------------------------------------------------------------------+
//Check for open order conditions 
int CheckSendOrder(ZZ_point &aZZPoint)
{
  int    res;
  //--- go trading only for first tiks of new bar
  if(Volume[0]>1) return -1;

  // エントリーフラグが立っていたら処理する
  if(!isEntry) return -1;
  
//--- sell conditions
  printf("CheckSendOrder aZZPoint.values:%f,%f",aZZPoint.values[0],aZZPoint.values[1]);
  if(aZZPoint.values[0] > aZZPoint.values[1])
  {
    res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
    if(res != -1) {
      isEntry = false;
    }
    return res;
  }
//--- buy conditions
  if(aZZPoint.values[0] < aZZPoint.values[1])
  {
    res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
    if(res != -1) {
      isEntry = false;
    }
    return res;
  }
  return -1;
//---
}

bool CheckCloseOrder(int aTicket) {
  //--- go trading only for first tiks of new bar
  if(Volume[0]>1) return false;

  // エントリーフラグが立っていたら処理する
  if(!isEntry) return false;

  if(!OrderSelect(aTicket,SELECT_BY_TICKET)) {
    return false;
  }

  double _lots = OrderLots();
  printf("CheckCloseOrder ticket:%d lots:%f",aTicket, _lots);
  bool _closeResult = false;
  if(OrderType() == OP_BUY) {
    _closeResult = OrderClose(OrderTicket(),OrderLots(),Bid,3,Green);
  } else if(OrderType() == OP_SELL) {
    _closeResult = OrderClose(OrderTicket(),OrderLots(),Ask,3,Green);
  }
  if(_closeResult) {
    isEntry = false;
  }
  return _closeResult;
}
//最適なロットサイズを計算
double LotsOptimized()
{
  return 0.1;
}

//+------------------------------------------------------------------+
//Utility
bool isTouch(HighLowPair &aHLLResults[], double aTarget, double &aRangeOffset[]) {
  bool _isTouch = false;
  
  for(int i = 0; i < ArraySize(aHLLResults); i++) {
    HighLowPair _hll = aHLLResults[i];
    double _range[] = {0,0};
    _range[0] = aRangeOffset[0] + _hll.high;
    _range[1] = aRangeOffset[1] + _hll.high;
    printf("isToush[%d] high %.3f(%f+%f) < %.3f < %.3f(%f+%f)", 
      i, _range[0], aRangeOffset[0], _hll.high, aTarget, _range[1], aRangeOffset[1], _hll.high);
    if(_range[0] <= aTarget && aTarget <= _range[1]) {
      _isTouch = true;
      break;
    }
    //low
    _range[0] = aRangeOffset[0] + _hll.low;
    _range[1] = aRangeOffset[1] + _hll.low;
    printf("isToush[%d] low %.3f(%f+%f) < %.3f < %.3f(%f+%f)", 
      i, _range[0], aRangeOffset[0], _hll.low, aTarget, _range[1], aRangeOffset[1], _hll.low);
    if(_range[0] <= aTarget && aTarget <= _range[1]) {
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