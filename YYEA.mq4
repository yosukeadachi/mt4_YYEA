//+------------------------------------------------------------------+
//|                                                         YYEA.mq4 |
//|                                    Copyright 2018, Yosuke Adachi |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Yosuke Adachi"
#property link      ""
#property version   "1.30"
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
#define HIGH_LOW_LINES_DAYS  4  //日数
struct StructHllBufferInfo {
  int dayIndex;
  datetime date;
  double highest;
  double lowest;
};
StructHllBufferInfo hllBuffers[HIGH_LOW_LINES_DAYS];
HighLowPair hllResults[HIGH_LOW_LINES_DAYS];

//UpperLowerShadow
double UpperLowerShadowMagnificationLargeShadow = 1.0;
double UpperLowerShadowMagnificationSmallShadow = 0.5;

//Order
#define MAGICMA 20180826
int ticket = -1;
double closePrise = 0;
int closeTimeOffset = 5*60;//間隔 秒
datetime openedTime = D'1970.01.01 00:01:02';

//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
  //--- go calculate only for first tiks of new bar
  if(Volume[0]>1) return;

  int i = 0;

  //HighLowLines
  UpdateHighLowLinesAll(hllBuffers);
  for(i = 0; i < ArraySize(hllResults); i++) {
    hllResults[i].high = hllBuffers[i].highest;
    hllResults[i].low = hllBuffers[i].lowest;
  }
  // printf("%s highlow:0[H%.3f:L%.3f],1[H%.3f:L%.3f],2[H%.3f:L%.3f],3[H%.3f:L%.3f]", 
  //     generateTickTimeStr(),
  //     hllResults[0].high,hllResults[0].low,
  //     hllResults[1].high,hllResults[1].low,
  //     hllResults[2].high,hllResults[2].low,
  //     hllResults[3].high,hllResults[3].low
  // );

  //RSI
  double _rsi = iCustom(NULL,period,"RSI",rsiPesiod,0,1);

  //エントリーチェック
  bool _isOkRsi = false;
  if((_rsi <= rsiLimitLower) || (_rsi >= rsiLimitUpper))
  {
    _isOkRsi = true;
  }

  //タッチ条件
  //HighLowの1~4までが1つ前のバーのOpenClose範囲に入っていればタッチとする
  bool _isTouch = false;
  double _prevLow = Low[1];
  double _prevHigh = High[1];
  for(i = 1; i < ArraySize(hllResults); i++) {
    double _target = 0;
    _target = hllResults[i].low;
    if((_prevLow <= _target) && (_target <= _prevHigh)) {
      _isTouch = true;
      // printf("isTouch Low:%d (%f < %f < %f)", i, _prevLow, _target, _prevHigh);
      break;
    }
    _target = hllResults[i].high;
    if((_prevLow <= _target) && (_target <= _prevHigh)) {
      _isTouch = true;
      // printf("isTouch high:%d (%f < %f < %f)", i, _prevLow, _target, _prevHigh);
      break;
    }
  }

  //ヒゲチェック
  bool _isShadow = false;
  int _shadowResult = getUpperLowerShadow(1);
  if(_shadowResult != 0) {
    _isShadow = true;
    // printf("isShadow TRUE result:%d", _shadowResult);
  }

  //エントリーまとめ
  bool _isEntry = false;
  // printf("_isOkRsi:%d _isTouch:%d _isShadow:%d", 
  //   _isOkRsi, _isTouch, _isShadow);
  if(_isOkRsi && _isTouch && _isShadow)
  {
    _isEntry = true;
  }

  //エントリー処理
  if(ticket == -1) {
    //Order Open
    // エントリーフラグが立っていたら処理する
    if((Volume[0]<=1) && _isEntry) {
      bool _isBuy = false;
      if(_rsi <= rsiLimitLower) {
        _isBuy = true;
      }
      else if(_rsi >= rsiLimitUpper) {
        _isBuy = false;
      }
      ticket = SendOrder(_isBuy);
      if(ticket != -1) {
        openedTime = Time[0];
      }
      // printf("SendOrder ticket:%d", ticket);
    }
  } else {
    //Order Close
    if(Volume[0]<=1) {
      bool _result = CloseOrder(ticket);
      if(_result) {
        ticket = -1;
      }
      // printf("CloseOrder _result:%d", _result);
    }
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
  // printf("Real_Body:%f",Real_Body);
  // printf("Upper_Shadow:%f",Upper_Shadow);
  // printf("Lower_Shadow:%f",Lower_Shadow);
  //実体 < ヒゲ
  if((Real_Body < Upper_Shadow) || (Real_Body < Lower_Shadow)) {
    if(Real_Body * UpperLowerShadowMagnificationLargeShadow <= Lower_Shadow &&
    Upper_Shadow * UpperLowerShadowMagnificationLargeShadow <= Lower_Shadow) {
      return -1;
    }
    if(Real_Body * UpperLowerShadowMagnificationLargeShadow <= Upper_Shadow && 
    Lower_Shadow * UpperLowerShadowMagnificationLargeShadow <= Upper_Shadow) {
      return 1;
    }
  } else {
  //実体　>= ヒゲ
    if(Real_Body * UpperLowerShadowMagnificationSmallShadow <= Lower_Shadow &&
    Upper_Shadow * UpperLowerShadowMagnificationSmallShadow <= Lower_Shadow) {
      return -1;
    }
    if(Real_Body * UpperLowerShadowMagnificationSmallShadow <= Upper_Shadow && 
    Lower_Shadow * UpperLowerShadowMagnificationSmallShadow <= Upper_Shadow) {
      return 1;
    }
  }

  return 0;
}

//HighLowLine
//日付更新
bool UpdateHighLowLinesDatetime(StructHllBufferInfo &aBuffer) {
  bool _doUpdate = false;
  //日付更新
  datetime _new = getNowDatetime() - (aBuffer.dayIndex * 60 * 60 *24);
  if(aBuffer.date != _new) {
    aBuffer.date = _new;
    _doUpdate = true;
  }
  if(_new == getNowDatetime()) {
    _doUpdate = true;
  }
  return _doUpdate;
}
//高値安値更新
void UpdateHighLowLinesValue(StructHllBufferInfo &aBuffer) {
  aBuffer.highest = 0;
  aBuffer.lowest = 999999999.0f;
  //highest,lowest 更新
  datetime _beginDatetime = StrToTime(TimeToStr(aBuffer.date, TIME_DATE) + " 00:00:00");
  datetime _endDatetime = StrToTime(TimeToStr(aBuffer.date, TIME_DATE) + " 23:59:59");
  for(int bar = 0; bar < Bars; bar++) {
    datetime _barDatetime = Time[bar];
    //範囲が終わっていれば終了
    if(_barDatetime < _beginDatetime) { 
      break;
    }
    //範囲外なら次へ
    if((_beginDatetime > _barDatetime) || (_barDatetime > _endDatetime)) {
      continue;
    }

    //更新
    if(aBuffer.highest < High[bar]) {
      aBuffer.highest = High[bar];
    }
    if(aBuffer.lowest > Low[bar]) {
      aBuffer.lowest = Low[bar];
    }
  }
}
//　HighLowLines全て更新
void UpdateHighLowLinesAll(StructHllBufferInfo &aBuffers[]) {
  for(int day = 0; day < ArraySize(aBuffers); day++) {
    if(UpdateHighLowLinesDatetime(aBuffers[day])){
      UpdateHighLowLinesValue(aBuffers[day]);
    }
  }
}


//+------------------------------------------------------------------+
//Order
//+------------------------------------------------------------------+
//Open order conditions
// aIsBuy 
int SendOrder(bool aIsBuy)
{
  int res = -1;  
  if(aIsBuy)
  {
//--- buy conditions
    res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
    return res;
  }
  else
  {
//--- sell conditions
    res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
    return res;
  }
  return -1;
}

//Close order conditions 
bool CloseOrder(int aTicket) {
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
  return _closeResult;
}

//最適なロットサイズを計算
double LotsOptimized()
{
  return 0.01;
}

//+------------------------------------------------------------------+
//Utility
datetime getNowDatetime() {
  return StrToTime(
        "" + 
        IntegerToString(Year()) + "." +
        IntegerToString(Month()) + "." + 
         IntegerToString(Day())+ " 00:00");
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