//+------------------------------------------------------------------+
//|                                                         YYEA.mq4 |
//|                                    Copyright 2018, Yosuke Adachi |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, Yosuke Adachi"
#property link      ""
#property version   "1.40"
#property description ""

//high low pair
struct HighLowPair {
  double high;
  double low;
};

//RSI
int rsiPesiod = 14;
double rsiLimitUpper = 70;
double rsiLimitLower = 30;
int rsiPreiodType = PERIOD_M5;

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

// //UpperLowerShadow
// double UpperLowerShadowMagnificationLargeShadow = 1.0;
// double UpperLowerShadowMagnificationSmallShadow = 0.5;

// //zigzag
// struct ZZ_param {
//     int depth;
//     int deviation;
//     int backstep;
// };
// struct ZZ_result {
//     double last;
//     HighLowPair pair;
// };

// struct ZZ_point {
//   int barIds[2];    //バーID
//   double values[2]; //現在=0 一つ前=1
// };
// ZZ_point zzPointLong;
// ZZ_point zzPointShort;

//MA乖離
int MA_Period=21;
int MA_Method=1;
double MAKairiLimit = 0.02;

//Order
#define MAGICMA 20180826
int ticket = -1;
double closePrise = 0;
extern int closeTimeMinute = 15;
int closeTimeOffset = closeTimeMinute*60;//間隔 秒
datetime openedTime = D'1970.01.01 00:01:02';
int orderArrowIndex = 0;
string orderArrowObjNameBase = "orderArrow";

//+------------------------------------------------------------------+
//| OnInit function                                                  |
//+------------------------------------------------------------------+
void OnInit()
{
  for(int i = 0; i < ArraySize(hllBuffers); i++) {
    hllBuffers[i].dayIndex = i;
    hllBuffers[i].date = 0;
    hllBuffers[i].highest = 0;
    hllBuffers[i].lowest = 999999999.9;
  }
}

void OnDeinit(const int reason)
{
  DeleteOrderArrows();
}

//+------------------------------------------------------------------+
//| OnTick function                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
  // //--- go calculate only for first tiks of new bar
  // if(Volume[0]>1) return;

  int i = 0;

  //------
  //個別エントリー条件

  // //ZigZag
  // ZZ_param zzpl = { 15, 5, 3};
  // ZZ_param zzps = { 5, 5, 3};
  // int _mode = 0;
  // //転換点を取得
  // int bar = 0;
  // int pointIndex = 0;
  // //Long
  // pointIndex = 0;
  // for(bar = 0; bar < Bars; bar++) {
  //   ZZ_result zzResultLong = {0,{0,0}};
  //   zzResultLong.last = iCustom(NULL,period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+0, bar);
  //   zzResultLong.pair.high = iCustom(NULL,period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+1, bar);
  //   zzResultLong.pair.low = iCustom(NULL,period,"ZigZag",zzpl.depth, zzpl.deviation, zzpl.backstep, _mode+2, bar);
  //   if(zzResultLong.last != 0) {
  //     zzPointLong.values[pointIndex] = zzResultLong.last;
  //     zzPointLong.barIds[pointIndex] = bar;
  //     pointIndex++;
  //     if(pointIndex >= ArraySize(zzPointLong.values)) {
  //       break;
  //     }
  //   }
  // }
  // // printf("Long [0](%d:%f) [1](%d:%f)", 
  // //   zzPointLong.barIds[0], zzPointLong.values[0],
  // //   zzPointLong.barIds[1], zzPointLong.values[1]);
  // //Short
  // pointIndex = 0;
  // for(bar = 0; bar < Bars; bar++) {
  //   ZZ_result zzResultShort = {0,{0,0}};
  //   zzResultShort.last = iCustom(NULL,period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+0, bar);
  //   zzResultShort.pair.high = iCustom(NULL,period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+1, bar);
  //   zzResultShort.pair.low = iCustom(NULL,period,"ZigZag",zzps.depth, zzps.deviation, zzps.backstep, _mode+2, bar);
  //   if(zzResultShort.last != 0) {
  //     zzPointShort.values[pointIndex] = zzResultShort.last;
  //     zzPointShort.barIds[pointIndex] = bar;
  //     pointIndex++;
  //     if(pointIndex >= ArraySize(zzPointShort.values)) {
  //       break;
  //     }
  //   }
  // }

  //zzエントリーチェック
  // printf("Short [0](%d:%f) [1](%d:%f)", 
  //   zzPointShort.barIds[0], zzPointShort.values[0],
  //   zzPointShort.barIds[1], zzPointShort.values[1]);
  // //転換点が重なっているか
  // // かつ　転換点が高値安値範囲か
  // bool _isZZOverlap = false;
  // if((zzPointLong.values[0] == zzPointShort.values[0]) &&
  //    (zzPointLong.barIds[0] == 1) &&
  //    (zzPointShort.barIds[0] == 1))
  // {
  //   double _targetValue = zzPointLong.values[0];
  //   if(_targetValue >= Low[1] && _targetValue <= High[1]) {
  //     _isZZOverlap = true;
  //   }
  //   // printf("Long [0](%d:%f) [1](%d:%f)", 
  //   //   zzPointLong.barIds[0], zzPointLong.values[0],
  //   //   zzPointLong.barIds[1], zzPointLong.values[1]);
  //   // printf("Short [0](%d:%f) [1](%d:%f)", 
  //   //   zzPointShort.barIds[0], zzPointShort.values[0],
  //   //   zzPointShort.barIds[1], zzPointShort.values[1]);
  // }

  //RSI
  double _rsi = iCustom(NULL,rsiPreiodType,"RSI",rsiPesiod,0,1);
  bool _isOkRsi = false;
  if((_rsi <= rsiLimitLower) || (_rsi >= rsiLimitUpper))
  {
    _isOkRsi = true;
  }

  //タッチ条件
  //HighLowLines
  UpdateHighLowLinesAll(hllBuffers);
  for(i = 0; i < ArraySize(hllResults); i++) {
    hllResults[i].high = hllBuffers[i].highest;
    hllResults[i].low = hllBuffers[i].lowest;
  }
  //HighLowの1~4までが今のバーのOpenClose範囲に入っていればタッチとする
  bool _isTouch = false;
  double _prevLow = Low[0];
  double _prevHigh = High[0];
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

  // //ヒゲチェック
  // bool _isShadow = false;
  // int _shadowResult = getUpperLowerShadow(1);
  // if(_shadowResult != 0) {
  //   _isShadow = true;
  //   // printf("isShadow TRUE result:%d", _shadowResult);
  // }

  //EMA乖離
  double _ma = iMA(NULL,PERIOD_CURRENT,MA_Period,0,MA_Method,PRICE_CLOSE,1);
  double _maKairi = (Close[1]-_ma)/_ma*100;
  bool _isEntryMAKairi = (MathAbs(_maKairi) > MAKairiLimit);

  //------
  //エントリーまとめ
  bool _isEntry = false;
  // printf("_isOkRsi:%d _isTouch:%d _isShadow:%d", 
  //   _isOkRsi, _isTouch, _isShadow);
  if(_isEntryMAKairi && _isOkRsi)
  {
    _isEntry = true;
  }

  //------
  //エントリー処理
  if(ticket == -1) {
    //Order Open
    // エントリーフラグが立っていたら処理する
    if(_isEntry) {
      int _cmd = OP_SELL;
      if(_maKairi < 0) {
        _cmd = OP_BUY;
      }
      else if(_maKairi > 0) {
        _cmd = OP_SELL;
      }
      ticket = SendOrder(_cmd);
      if(ticket != -1) {
        openedTime = Time[0];
      }
      // printf("SendOrder ticket:%d", ticket);
    }
  } else {
    //Order Close
    // if(Volume[0]<=1) 
    {
      bool _result = CloseOrder(ticket);
      if(_result) {
        ticket = -1;
      }
      // printf("CloseOrder _result:%d", _result);
    }
  }
}
//+------------------------------------------------------------------+

// // UpperLowerShadow
// // return 0= どちらでもない, -1=Lower 1=Upper
// int getUpperLowerShadow(int aBar) {
//   if(aBar <= 0) {
//     return 0;
//   }

//   //実体の計算
//   double Real_Body = MathAbs(Open[aBar] - Close[aBar]);
//   //上ヒゲの計算
//   double Upper_Shadow = MathMin(High[aBar] - Open[aBar], High[aBar] - Close[aBar]);
//   //下ヒゲの計算
//   double Lower_Shadow = MathMin(Open[aBar] - Low[aBar], Close[aBar] - Low[aBar]);
//   // printf("Real_Body:%f",Real_Body);
//   // printf("Upper_Shadow:%f",Upper_Shadow);
//   // printf("Lower_Shadow:%f",Lower_Shadow);
//   //実体 < ヒゲ
//   if((Real_Body < Upper_Shadow) || (Real_Body < Lower_Shadow)) {
//     if(Real_Body * UpperLowerShadowMagnificationLargeShadow <= Lower_Shadow &&
//     Upper_Shadow * UpperLowerShadowMagnificationLargeShadow <= Lower_Shadow) {
//       return -1;
//     }
//     if(Real_Body * UpperLowerShadowMagnificationLargeShadow <= Upper_Shadow && 
//     Lower_Shadow * UpperLowerShadowMagnificationLargeShadow <= Upper_Shadow) {
//       return 1;
//     }
//   } else {
//   //実体　>= ヒゲ
//     if(Real_Body * UpperLowerShadowMagnificationSmallShadow <= Lower_Shadow &&
//     Upper_Shadow * UpperLowerShadowMagnificationSmallShadow <= Lower_Shadow) {
//       return -1;
//     }
//     if(Real_Body * UpperLowerShadowMagnificationSmallShadow <= Upper_Shadow && 
//     Lower_Shadow * UpperLowerShadowMagnificationSmallShadow <= Upper_Shadow) {
//       return 1;
//     }
//   }

//   return 0;
// }

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
int SendOrder(int aCmd)
{
  int res = -1;  
  if(aCmd == OP_BUY)
  {
//--- buy conditions
    res=OrderSend(Symbol(),OP_BUY,LotsOptimized(),Ask,3,0,0,"",MAGICMA,0,Blue);
    if(OrderSelect(res,SELECT_BY_TICKET)) {
      CreateOrderAllow(OP_BUY, Time[1], Low[1]);
    }
    return res;
  }
  else
  {
//--- sell conditions
    res=OrderSend(Symbol(),OP_SELL,LotsOptimized(),Bid,3,0,0,"",MAGICMA,0,Red);
    if(OrderSelect(res,SELECT_BY_TICKET)) {
      CreateOrderAllow(OP_SELL, Time[1], High[1]);
    }
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

//オーダー入れた時の矢印作成
void CreateOrderAllow(int aOrderType, int aTimeBar, double aEntryValue) {
  int chart_id = 0;
  string obj_name = orderArrowObjNameBase + IntegerToString(orderArrowIndex);
  ObjectCreate(chart_id,obj_name,                                     // オブジェクト作成
              OBJ_ARROW,                                             // オブジェクトタイプ
              0,                                                       // サブウインドウ番号
              aTimeBar,                                               // 1番目の時間のアンカーポイント
              aEntryValue                                         // 1番目の価格のアンカーポイント
              );
  color _color = clrBlue;
  int _code_up = 233;  //上矢印
  int _code_down = 234;  //下矢印
  int _code = _code_up;//上矢印
  int _anchor_up = ANCHOR_TOP;
  int _anchor_down = ANCHOR_BOTTOM;
  int _anchor = _anchor_up;
  if(aOrderType == OP_BUY) {
    _color = clrBlue;
    _code = _code_up;
    _anchor = _anchor_up;
  } else if(aOrderType == OP_SELL) {
    _color = clrRed;
    _code = _code_down;
    _anchor = _anchor_down;
  }
  ObjectSetInteger(chart_id,obj_name,OBJPROP_COLOR,_color);    // 色設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_WIDTH,1);             // 幅設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_BACK,false);           // オブジェクトの背景表示設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_SELECTABLE,true);     // オブジェクトの選択可否設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_SELECTED,false);      // オブジェクトの選択状態
  ObjectSetInteger(chart_id,obj_name,OBJPROP_HIDDEN,true);         // オブジェクトリスト表示設定
  ObjectSetInteger(chart_id,obj_name,OBJPROP_ZORDER,0);            // オブジェクトのチャートクリックイベント優先順位
  ObjectSetInteger(chart_id,obj_name,OBJPROP_ANCHOR,_anchor); // アンカータイプ
  ObjectSetInteger(chart_id,obj_name,OBJPROP_ARROWCODE,_code);      // アローコード
  orderArrowIndex++;
  // printf("CreateOrderAllow %d %f", aOrderType, aEntryValue);
}

//オーダー矢印削除
void DeleteOrderArrows() {
  for(int i = 0; i < orderArrowIndex; i++) {
    ObjectDelete(orderArrowObjNameBase + IntegerToString(i));
  }
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