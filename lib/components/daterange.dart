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
  String get displayValue => (dateFormat == null || startDate == null || endDate == null) ? '' : '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
  /// Display date format
  @observable DateFormat dateFormat;
  /// Current locale
  @observable String _locale = 'en';
  String get locale => _locale;
  set locale(String l){
    _locale = l;
    initializeDateFormatting(locale, null)
      .then((_) => _initializeTexts(new DateFormat.E().dateSymbols));
  }
  
  @observable int firstDayOfWeek;
  @observable static List<String> monthTexts;
  @observable static List<String> weekdayTexts;
  DateFormat _format = new DateFormat.yMd();
  set format(String f) => new DateFormat(f,locale);
  
  @observable DateTime startDate = new DateTime.now();
  @observable DateTime endDate = new DateTime.now();
  
  /// Limit selector to dates before [limitright] date (exclusive).
  DateTime limitright;
  /// Limit selector to dates after [limitleft] date (exclusive).
  DateTime limitleft;
  
  int calendars = 3;
  @observable List<AppCalendar> get  calendarsList => _calendarsData();
  
  DateRange(){
    locale = window.navigator.language;
    initializeDateFormatting(window.navigator.language, null).then((_){
      dateFormat = new DateFormat.yMMMMd(window.navigator.language); 
    });
  }
  
  @observable DateTime startMonth;
  List<AppCalendar> _calendarsData(){
    if(!initialized) return [];
    
    List<AppCalendar> result = [];
    if(startMonth == null){
      if(startDate.month == endDate.month){
        //startDate.month must be in the middle
        startMonth = new DateTime(startDate.year, startDate.month-1, 1).subtract(new Duration(days:1));
      } else if(endDate.month-startDate.month == 2){
        startMonth = startDate;
      } else {
        startMonth = new DateTime(startDate.year, startDate.month+1, 1).subtract(new Duration(days:1));
      }
    }
    for(int i=0; i<calendars; i++){
      
      int y = startMonth.year;
      int m = startMonth.month;
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
    if(locale != null){
      initializeDateFormatting(locale, null)
      .then((_) => _initializeTexts(new DateFormat.E().dateSymbols));
    } else {
      findSystemLocale()
        .then((_) => initializeDateFormatting(Intl.systemLocale, null))
        .then((_) => _initializeTexts(new DateFormat.E().dateSymbols));
    }
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
  
  
  
  
  
  void inserted() {
    if(locale != null){
      initializeDateFormatting(locale, null)
        .then((_) => _format = new DateFormat.yMd(locale))
        .then((_) => _initializeTexts(new DateFormat.E(locale).dateSymbols));
    }
  }
  
  void previousMonth(){
    startMonth = new DateTime(startMonth.year, startMonth.month-1, startMonth.day);
  }
  
  void nextMonth(){
    startMonth = new DateTime(startMonth.year, startMonth.month+1, startMonth.day);
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