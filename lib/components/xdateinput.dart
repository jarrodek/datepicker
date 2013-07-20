import 'package:web_ui/web_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_browser.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbols.dart';
import 'dart:html';
import 'dart:async';

class XDateInput extends WebComponent{
  
  String locale;
  /// Today.
  DateTime _today = new DateTime.now();
  /// Date randge to show.
  /// By default it is today.
  /// When the user click on input it will change to [DateTime] object for current [value]
  @observable DateTime _view_date = new DateTime.now();
  @observable DateTime _value_date = new DateTime.now();
  
  ///Current date value (selected value)
  set value(String _value) {
    try{
      _value_date = _format.parse(_value);
      _view_date = _value_date;
      if(initialized)
        _generateCalendar();
    }catch(e){
      print(e);
      /*if(_value_date == null){
        _value_date = new DateTime.now();
        _view_date = _value_date;
      }*/
    }
    
  }
  DateFormat _format = new DateFormat.yMd();
  set format(String f) => new DateFormat(f,locale);
  
  String get value => _format.format(_value_date);
  
  
  @observable static bool initializing = false;
  @observable static bool initialized = false;
  @observable static int firstDayOfWeek;
  @observable static List<String> monthTexts;
  @observable static List<String> weekdayTexts;
  
  @observable bool showDiv = false;
  @observable bool closing = false;
  @observable String inputid = "";
  @observable String inputplaceholder = "";
  @observable int inputmaxlength = 9999;
  @observable List calendarList = toObservable([]);
  
  void _generateCalendar(){
    calendarList.clear();
    DateTime first = new DateTime(_view_date.year,_view_date.month,1);
    DateTime last = new DateTime(_view_date.year,_view_date.month+1,1).subtract(new Duration(days:1));
     
    List<int> weekList = [null,null,null,null,null,null,null];
    int pos = first.weekday - firstDayOfWeek;
    if(pos >= 7)
      pos -= 7;
    if(pos < 0)
      pos += 7;
    for(int i=1; i<=last.day; i++){      
      weekList[pos] = i;
      pos++;
      if(pos >= 7){
        calendarList.add(weekList);
        weekList = [null,null,null,null,null,null,null];
        pos = 0;
      }
    }
    if(pos > 0){
      calendarList.add(weekList);
    }
  }
  
  
  bool isToday(int day){
    if(_view_date.year == _today.year && _view_date.month == _today.month && day == _today.day)
      return true;
    else
      return false;
  }
  
  /// Check if a [day] is one of selected days.
  bool isSelected(int day){
    
  }
  
  /// Name of the month
  String get monthText => monthTexts[_view_date.month-1];
  
  void chooseDay(int day){
    _value_date = new DateTime(_view_date.year, _view_date.month, day);
    showDiv = false;
  }
  
  void onValueChange(){
    try{
      _value_date = _format.parse(value);
    }catch(e){
      print(e);
      _value_date = new DateTime.now();
    }
    _generateCalendar();
  }
  
  /// Schow the calendar
  void show(){
    if(calendarList.length == 0){
      _generateCalendar();
    }
    showDiv = true;
    closing = false;
  }
  
  void close(){
    closing = true;
    showDiv = false;
  }
  
  void previousMonth(){
    _view_date = new DateTime(_view_date.year, _view_date.month-1, 1);
    _generateCalendar(); 
  }
  
  void nextMonth(){
    _view_date = new DateTime(_view_date.year, _view_date.month+1, 1);
    _generateCalendar();
  }
  
  
  
  void _initializeTexts(DateSymbols ds){
    firstDayOfWeek = ds.FIRSTDAYOFWEEK;
    weekdayTexts = [];
    for(int i=0; i<7; i++){
      int k = firstDayOfWeek+i;
      if(k>=7)
        k = k - 7;
      weekdayTexts.add(ds.NARROWWEEKDAYS[k]);
    }
    monthTexts = ds.STANDALONESHORTMONTHS;
    initialized = true;
  }
  
  void created(){
    if(!initializing){
      initializing = true;
      if(locale != null){
        initializeDateFormatting(locale, null)
          .then((_) => _initializeTexts(new DateFormat.E().dateSymbols));
      } else {
        findSystemLocale()
          .then((_) => initializeDateFormatting(Intl.systemLocale, null))
          .then((_) => _initializeTexts(new DateFormat.E().dateSymbols));
      }
    }
  }
  
  void attributeChanged(String name, String oldValue, String newValue) {
    print(name);
  }
  
  void inserted() {
    if(locale != null){
      initializeDateFormatting(locale, null)
        .then((_) => _format = new DateFormat.yMd(locale))
        .then((_) => _initializeTexts(new DateFormat.E(locale).dateSymbols));
    }
    
  }
}
