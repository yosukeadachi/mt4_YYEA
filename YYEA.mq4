//+------------------------------------------------------------------+
//|                                                         YYEA.mq4 |
//|                                    Copyright 2018, Yosuke Adachi |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Yosuke Adachi"
#property link      ""
#property version   "1.10"
#property description ""

int period = PERIOD_M5;

//high low pair
struct HighLowPair {
  double high;
  double low;
};

//RSI
int rsiPesiod = 14;
double rsiLimitUpper = 70;
double rsiLimitLower = 30;

//HighLowLines
HighLowPair hllResults[4];

//UpperLowerShadow
double UpperLowerShadowMagnification = 1.0;

//Order
#define MAGICMA 20180826
int ticket = -1;
bool isEntry = false;
double closePrise = 0;
int closeTimeOffset = 15*60;//間隔 秒
datetime openedTime = D'1970.01.01 00:01:02';

//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
  //--- go calculate only for first tiks of new bar
  if(Volume[0]>1) return;

  //HighLowLines
  for(int i = 0; i < ArraySize(hllResults); i++) {
    int _timeframe = PERIOD_D1;
    hllResults[i].high = iHigh(NULL,_timeframe,i);
    hllResults[i].low = iLow(NULL,_timeframe,i);
  }
  // printf("%s highlow:0[H%.3f:L%.3f],1[H%.3f:L%.3f],2[H%.3f:L%.3f],3[H%.3f:L%.3f]", 
  //     generateTickTimeStr(),
  //     hllResults[0].high,hllResults[0].low,
  //     hllResults[1].high,hllResults[1].low,
  //     hllResults[2].high,hllResults[2].low,
  //     hllResults[3].high,hllResults[3].low
  // );

  //RSI
  double _rsi = iCustom(NULL,period,"RSI",rsiPesiod,0,0);

  //エントリーチェック
  if((_rsi <= rsiLimitLower) || (_rsi >= rsiLimitUpper))
  {
    double _rangeOffset[] = {-0.05,0.05};
    double _target = Open[0];
    if(isTouch(hllResults, _target, _rangeOffset)) {
      // printf("touch %f", _target);
      int shadow = getUpperLowerShadow(1);
      // printf("shadow:%d", shadow);
      if(shadow != 0) {
        isEntry = true;
      }
    }
  }

  //エントリー処理
  if(ticket == -1) {
    //Order Open
    ticket = CheckSendOrder(_rsi);
    if(ticket != -1) {
      openedTime = Time[0];
    }
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

// UpperLowerShadow
// return 0= どちらでもない, -1=Lower 1=Upper
int getUpperLowerShadow(int aBar) {
  if(aBar <= 0) {
    return 0;
  }

  //実体の計算
  double Real_Body = MathAbs(Open[aBar] - Close[aBar]);
  //上ヒゲの計算
  double Upper_Shadow = MathMin(High[aBar] - Open[aBar], High[aBar] - Close[aBar]);
  //下ヒゲの計算
  double Lower_Shadow = MathMin(Open[aBar] - Low[aBar], Close[aBar] - Low[aBar]);
  if(Real_Body * UpperLowerShadowMagnification <= Lower_Shadow &&
  Upper_Shadow * UpperLowerShadowMagnification <= Lower_Shadow) {
    //  printf("!!!!^%d^!!!!",i);
    return -1;
  }
  if(Real_Body * UpperLowerShadowMagnification <= Upper_Shadow && 
  Lower_Shadow * UpperLowerShadowMagnification <= Upper_Shadow) {
    //  printf("!!!!_%d_!!!!",i);
    return 1;
  }
  return 0;
}


//+------------------------------------------------------------------+
//Order
//+------------------------------------------------------------------+
//Check for open order conditions 
int CheckSendOrder(double aRsi)
{
  int    res;
  //--- go trading only for first tiks of new bar
  if(Volume[0]>1) return -1;

  // エントリーフラグが立っていたら処理する
  if(!isEntry) return -1;
  
//--- sell conditions
  // printf("CheckSendOrder aZZPoint.values:%f,%f",aZZPoint.values[0],aZZPoint.values[1]);
  if(aRsi >= rsiLimitUpper)
  {
    res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
    if(res != -1) {
      isEntry = false;
    }
    return res;
  }
//--- buy conditions
  if(aRsi <= rsiLimitLower)
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

//Check for close order conditions 
bool CheckCloseOrder(int aTicket) {
  //--- go trading only for first tiks of new bar
  if(Volume[0]>1) return false;

  // printf("openedTime:%d closeTimeOffset:%d (%d) Time[0]:%d",
    // openedTime,closeTimeOffset,(openedTime + closeTimeOffset),Time[0]);
  if((openedTime + closeTimeOffset) > Time[0]) {
    return false;
  }

  if(!OrderSelect(aTicket,SELECT_BY_TICKET)) {
    return false;
  }

  double _lots = OrderLots();
  // printf("CheckCloseOrder ticket:%d lots:%f",aTicket, _lots);
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
  return 0.01;
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
    // printf("isToush[%d] high %.3f(%f+%f) < %.3f < %.3f(%f+%f)", 
    //   i, _range[0], aRangeOffset[0], _hll.high, aTarget, _range[1], aRangeOffset[1], _hll.high);
    if(_range[0] <= aTarget && aTarget <= _range[1]) {
      _isTouch = true;
      break;
    }
    //low
    _range[0] = aRangeOffset[0] + _hll.low;
    _range[1] = aRangeOffset[1] + _hll.low;
    // printf("isToush[%d] low %.3f(%f+%f) < %.3f < %.3f(%f+%f)", 
    //   i, _range[0], aRangeOffset[0], _hll.low, aTarget, _range[1], aRangeOffset[1], _hll.low);
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