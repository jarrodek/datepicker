import 'dart:html';
import 'dart:async';
import 'dart:collection';

import 'package:web_ui/web_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/date_symbols.dart';
import 'package:intl/intl_browser.dart';
import 'package:intl/intl.dart';

class DateRange extends WebComponent{
  @observable bool initialized = false;
  ///Value to be displayed in display
  String get displayValue => (_dateFormat == null || startDate == null || endDate == null) ? '' : '${_dateFormat.format(startDate)} - ${_dateFormat.format(endDate)}';
  /// Display date format
  @observable DateFormat _dateFormat = new DateFormat.yMd();
  /// Current locale
  @observable String _locale;
  String get locale => _locale;
  set locale(String l){
    _locale = l;
    
    initializeDateFormatting(_locale, null)
      .then((_) => _dateFormat = new DateFormat.yMd(_locale))
      .then((_) => _initializeTexts(new DateFormat.E().dateSymbols));
  }
  
  @observable int firstDayOfWeek;
  @observable static List<String> monthTexts;
  @observable static List<String> weekdayTexts;
  set format(String f) => new DateFormat(f,locale);
  
  /// Currently selected (but not accepted) start day
  @observable DateTime selectedStartDate;
  /// Currently selected (but not accepted) end day
  @observable DateTime selectedEndDate;
  
  @observable DateTime startDate = new DateTime.now();
  @observable DateTime endDate = new DateTime.now();
   
  String _startDateInput;
  String _endDateInput;
  String get startDateInput => _startDateInput == null ? _dateFormat.format(selectedStartDate) : _startDateInput;
  String get endDateInput => _endDateInput == null ? selectedEndDate == null ? '' : _dateFormat.format(selectedEndDate) : _endDateInput;
  
  set startDateInput(String v){
    try{
      selectedStartDate = _dateFormat.parse(v);
      _startDateInput = v; //_dateFormat.format(selectedStartDate);
      startDate = selectedStartDate;
    }catch(e){
      print('Formated string: $v, locale: $locale');
      print(e);
    }
  }
  set endDateInput(String v){
    try{
      selectedEndDate = _dateFormat.parse(v);
      _endDateInput = v;
      endDate = selectedEndDate;
    }catch(e){
      print('Formated string: $v, locale: $locale');
      print(e);
    }
  }
  
  /// Limit selector to dates before [limitright] date (exclusive).
  DateTime limitright;
  /// Limit selector to dates after [limitleft] date (exclusive).
  DateTime limitleft;
  
  int calendars = 3;
  @observable List<AppCalendar> get  calendarsList => _calendarsData();
  
  DateRange(){
    DateTime d = new DateTime.now();
    selectedStartDate = new DateTime(d.year, d.month, d.day);
    selectedEndDate = new DateTime(d.year, d.month, d.day);
  }
    
  
  List<AppCalendar> _calendarsData(){
    if(!initialized) return [];
    
    List<AppCalendar> result = [];
    
    if(startDate.month == endDate.month){
      //startDate.month must be in the middle
      startDate = new DateTime(startDate.year, startDate.month-1, 1).subtract(new Duration(days:1));
    } else if(endDate.month-startDate.month == 2){
    } else {
      startDate = new DateTime(startDate.year, startDate.month+1, 1).subtract(new Duration(days:1));
    }
    
    for(int i=0; i<calendars; i++){
      
      int y = startDate.year;
      int m = startDate.month;
      m += i;
      if(m==13){
        m = 1;
        y++;
      }
      DateTime _date = new DateTime(y, m, 1);
      AppCalendar cal = _generateCalendar(_date);
      cal.calendarNo = i;
      result.add(cal);
    }
    
    return result;
  }
  
  AppCalendar _generateCalendar(DateTime date){
    
    AppCalendar calendar = new AppCalendar();
    List calendarList = [];
    
    DateTime first = new DateTime(date.year,date.month,1);
    DateTime last = new DateTime(date.year,date.month+1,1).subtract(new Duration(days:1));
     
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
    
    calendar.dates = calendarList;
    calendar.monthName = monthTexts[date.month-1];
    calendar.year = date.year;
    
    calendar.month = date.month;
    if(limitleft != null){
      if(date.year <= limitleft.year && date.month <= limitleft.month){
        calendar.limitLeft = limitleft;
      }
    }
    if(limitright != null){
      bool setLimit = false;
      if(date.year > limitright.year){
        setLimit = true;
      } else if(date.year == limitright.year){
        if(date.month >= limitright.month){
          setLimit = true;
        }
      }
      if(setLimit){
        calendar.limitRight = limitright;
      }
    }
    if(limitleft != null){
      bool setLimit = false;
      if(date.year < limitleft.year){
        setLimit = true;
      } else if(date.year == limitleft.year){
        if(date.month <= limitleft.month){
          setLimit = true;
        }
      }
      if(setLimit){
        calendar.limitLeft = limitleft;
      }
    }
    return calendar;
  }
  
  void created(){
    findSystemLocale()
      .then((_) => initializeDateFormatting(Intl.systemLocale, null))
      .then((_) => _dateFormat = new DateFormat.yMd(Intl.systemLocale))
      .then((_) => _initializeTexts(new DateFormat.E().dateSymbols));
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
  
  void previousMonth(){
    startDate = new DateTime(startDate.year, startDate.month-1, startDate.day);
  }
  
  void nextMonth(){
    startDate = new DateTime(startDate.year, startDate.month+1, startDate.day);
  }
  
  bool firstDaySelected = false;
  void selectDay(int year, int month, int day){
    DateTime d = new DateTime(year, month, day);
    if(firstDaySelected){
      selectedEndDate = d;
      firstDaySelected = false;
    } else {
      selectedEndDate = null;
      selectedStartDate = d;
      firstDaySelected = true;
    }
  }
  
  bool isSelected(int year, int month, int day){
    DateTime current = new DateTime(year, month, day);
    
    if(selectedStartDate == null){
      return false;
    }
    
    if(current.isAtSameMomentAs(selectedStartDate)){
      return true;
    }
    
    if(current.isAfter(selectedStartDate)){
      //check left bound
      if(selectedEndDate == null){
        return false;
      }
      if(current.isBefore(selectedEndDate) || current.isAtSameMomentAs(selectedEndDate)){
        return true;
      }
    }
    return false;
    
  }
}


class AppCalendar {
  ///Debug.
  int calendarNo;
  List dates;
  String monthName;
  int year;
  int month;
  bool get hasLimit => limitRight != null || limitLeft != null;
  ///Right limit for date range (limit for dates after this day)
  DateTime limitRight;
  ///Left limit for date range (limit for dates before this day)
  DateTime limitLeft;
  
  /// Return true if day can be selected.
  bool isSelectable(int day){
    if(!hasLimit) return true;
    //is limited right (the day is after limit)
    if(limitRight != null){
      return !new DateTime(year, month, day).isAfter(limitRight);
    }
    //is limited left (the day is before limit)
    if(limitLeft != null){
      return !new DateTime(year, month, day).isBefore(limitLeft);
    }
    return true;
  }
}