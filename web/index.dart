import 'dart:html';

String date1 = "2013-07-01";
String date2;
String date3 = "1999-01-01";
String date4;

DateTime dateRangeRight = new DateTime.now();
DateTime dateSelectionRight = new DateTime.now().subtract(new Duration(days: 2));
DateTime dateSelectionLeft = new DateTime.now().subtract(new Duration(days: 12));
main(){
}

void callbackAction(Event e){
 print("Callback event action: ${e.type}"); 
}