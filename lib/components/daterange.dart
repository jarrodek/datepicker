
import 'dart:html';
import 'dart:async';
import 'dart:collection';

import 'package:web_ui/web_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class DateRange extends WebComponent{
  ///Value to be displayed in display
  String get displayValue => (dateFormat == null || startDate == null || endDate == null) ? '' : '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';
  
  @observable DateFormat dateFormat;
  String locale = 'en';
  
  @observable DateTime startDate;
  @observable DateTime endDate;
  
  int calendars = 3;
  @observable List<dynamic> get  calendarsList => _calendarsData();
  
  DateRange(){
    locale = window.navigator.language;
    initializeDateFormatting(window.navigator.language, null).then((_){
      dateFormat = new DateFormat.yMMMMd(window.navigator.language); 
    });
  }
  
  List<dynamic> _calendarsData(){
    
  }
}


class AppCalendar {
  
}