import 'package:flutter/material.dart';
import 'package:collection/collection.dart' show lowerBound;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:core';
import 'package:rxdart/rxdart.dart';

enum LeaveBehindDemoAction {
  reset,
  horizontalSwipe,
  leftSwipe,
  rightSwipe
}

void main() {
  runApp(new MyApp());
}

class LeaveBehindItem implements Comparable<LeaveBehindItem> {
  LeaveBehindItem({ this.index, this.name, this.subject, this.to, this.read });

  LeaveBehindItem.from(LeaveBehindItem item)
      : index = item.index, name = item.name, subject = item.subject, to = item.to, read = item.read;

  final int index;
  final String name;
  final String subject;
  final String to;
  bool read;

  @override
  int compareTo(LeaveBehindItem other) => index.compareTo(other.index);
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Inbox App',
      theme: new ThemeData(
        accentColor: Colors.white,
      ),
          // primarySwatch: Colors.blue,
          // accentColor: Colors.red),
      home: new MyHomePage(title: 'Inbox'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  DismissDirection _dismissDirection = DismissDirection.horizontal;
  List<LeaveBehindItem> leaveBehindItems;
  //Iterator x = Iterator(); 
  //NewEmail newEmail = new NewEmail();

  void initListItems() {
    leaveBehindItems = new List<LeaveBehindItem>.generate(16, (int index) {
      return new LeaveBehindItem(
          index: index,
          name: '$index',
          subject: '$index',
          to: '$index',
          read: false
      );
    });
  }

  @override
  void initState() {
    super.initState();
    initListItems();
  }

  void handleDemoAction(LeaveBehindDemoAction action) {
    switch (action) {
      case LeaveBehindDemoAction.reset:
        initListItems();
        break;
      case LeaveBehindDemoAction.horizontalSwipe:
        _dismissDirection = DismissDirection.horizontal;
        break;
      case LeaveBehindDemoAction.leftSwipe:
        _dismissDirection = DismissDirection.endToStart;
        break;
      case LeaveBehindDemoAction.rightSwipe:
        _dismissDirection = DismissDirection.startToEnd;
        break;
    }
  }

  void handleUndo(LeaveBehindItem item) {
    final int insertionIndex = lowerBound(leaveBehindItems, item);
    setState(() {
      leaveBehindItems.insert(insertionIndex, item);
    });
  }

  Widget buildItem(LeaveBehindItem item) {
    final ThemeData theme = Theme.of(context);
    return new Dismissible(
        key: new ObjectKey(item),
        direction: _dismissDirection,
        onDismissed: (DismissDirection direction) {
          setState(() {
            leaveBehindItems.remove(item);
          });
          final String action = (direction == DismissDirection.endToStart) ? 'archived' : 'deleted';
          _scaffoldKey.currentState.showSnackBar(new SnackBar(
              content: new Text('You $action item ${item.index}'),
              action: new SnackBarAction(
                  label: 'UNDO',
                  onPressed: () { handleUndo(item); }
              )
          ));
        },
        background: new Container(
            color: Colors.green,
            child: const ListTile(
                leading: const Icon(Icons.done, color: Colors.white, size: 36.0)
            )
        ),
        secondaryBackground: new Container(
            color: Colors.orange,
            child: const ListTile(
                trailing: const Icon(Icons.query_builder, color: Colors.white, size: 36.0)
            )
        ),
        child: GestureDetector(
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (context) => EmailBody(emailno: leaveBehindItems[item.index])) );
                  item.read = true;                 
                  },       
                child: new Container(
                    decoration: new BoxDecoration(
                        color: theme.canvasColor,
                        border: new Border(bottom: new BorderSide(color: theme.dividerColor, width: 3.0))
                    ),
                      child:IntrinsicHeight(
                        child: new Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Container(
                              color: Colors.grey[200],
                              width: 72.0,
                              child: Image.asset('assets/fl_icon.png'),
                            ),
                            Container(padding: EdgeInsets.all(10.0)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                new Text(""),
                                new Row(children:[new Text('Item', style: TextStyle(fontWeight: FontWeight.bold)), new Text(' ${item.name} '), new Text('Sender')]),
                                new Row(children:[new Text('Subject: ', style: TextStyle(fontWeight: FontWeight.bold)), new Text('${item.subject}') ]),
                                new Row(children:[new Text('To: ', style: TextStyle(fontWeight: FontWeight.bold)), new Text('${item.to}') ]), 
                                new Text(""),
                              ],
                            ),
                            Container( padding: EdgeInsets.only(right: 180.0)),
                            Container(
                              child: tick(item),
                            ),
                          ],
                        ),
                      ),
                  )
        )
    );
  }

  tick(LeaveBehindItem item){
    if(item.read == false){
      return new Icon(Icons.done, color: Colors.red);
    } else {
      return new Icon(Icons.done, color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new ListView(
          children: leaveBehindItems.map(buildItem).toList()
      ),
      floatingActionButton: new FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: (){
         Navigator.push(context, MaterialPageRoute(builder: (context) => NewEmail()));
        },
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), 
    );
  }
}

class Emailbody {
  final String id;
  final int identifier;
  final String subject;
  final String msgDate;
  final String from;
  final String to;

  Emailbody({this.id, this.identifier, this.subject, this.msgDate, this.from, this.to});

  factory Emailbody.fromJson(Map<dynamic, dynamic> json){
    //THIS  IS RETURNING A LIST TYPE OBJECT CONTAINING A MAP, NEED TO RETURN A LIST OF MAPS      
    return new Emailbody(
      id: json['_id'].toString(),
      identifier: json['Id'],
      subject: json['Subject'],
      msgDate: json['MsgDate'],
      from: json['From'],
      to: json['To'],
    );        
  }
}

class EmailbodyList {
  final List<Emailbody> emailbodies;

  EmailbodyList({this.emailbodies});

  factory EmailbodyList.fromJson(List<dynamic> parsedJson) {

    List<Emailbody> emailbodies = new List<Emailbody>();
    emailbodies = parsedJson.map((i) => Emailbody.fromJson(i)).toList();

    return new EmailbodyList(
      emailbodies: emailbodies
    );
  }
}

class EmailBody extends StatelessWidget{
  //final LeaveBehindItem item;
  final LeaveBehindItem emailno;
  
  EmailBody({Key key, @required this.emailno}): super(key: key);
  
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      home: Scaffold(
      appBar: AppBar(
        title: Text("Content"),
        leading: IconButton(icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false))
      ),
      body: 
          Center(
            child: Container(
              decoration: new BoxDecoration(
                image:  new DecorationImage(
                  image: new AssetImage("assets/background.png"),
                fit: BoxFit.cover,
                )
              ),
              child: FutureBuilder<EmailbodyList>(
                future: fetchPost(emailno), //sets the getQuote method as the expected Future
                builder: (context, snapshot) {
                  if (snapshot.hasData) { //checks if the response returns valid data              
                    return Center(
                      child: Column(
                        children: <Widget>[
                          Text("From: " + snapshot.data.emailbodies[0].from, style: TextStyle(color: Colors.white)),
                          Text("To: " + snapshot.data.emailbodies[0].to, style: TextStyle(color: Colors.white)),
                          Text("Id number: " + snapshot.data.emailbodies[0].id, style: TextStyle(color: Colors.white)),
                          Text("Subject: " + snapshot.data.emailbodies[0].subject, style: TextStyle(color: Colors.white)),            
                          //displays the quote
                          SizedBox(
                            height: 10.0,
                          ),//displays the quote's author
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) { //checks if the response throws an error
                    return Text("${snapshot.error}");
                  }
                  return CircularProgressIndicator();
                },
              ),
            ),
          ),
      ),
    );
  }
}

Future<EmailbodyList> fetchPost(emailno) async{
   int emailid = emailno.index;
   var response = await http.get('http://10.69.96.128:3000/notes/$emailid', headers: {"Accept": "application/json"});

   if(response.statusCode == 200) {
     return EmailbodyList.fromJson(json.decode(response.body));
   } else {
     throw Exception('Failed to load');
   }
}

// class Iterator{
//   final LeaveBehindItem item;
//   Iterator({this.item});
//   static int iterator(item){
//     int x = item.index;
//     while(x>0){
//       x = x + 1;
//     }
//     return x;
//   }
// }
//Provides a random number in the range of 0 - 100 000 in order to uniquely identify the message sent, 
//however there is an upper limit to this, * may need to rather set an integer to increment instead
class RandomNumber {
  static int randomiser(){
    var random = new Random();
    final id = random.nextInt(100000); 
    return id;
  }
}

//This stateless widget builds the UI and posts the email to the required address
class NewEmail extends StatelessWidget{ 

  final bloc = new StreamBloc(); 

  //create an instance of the class object in order to package for the post
  // final NewEmailContent content = new NewEmailContent();

  //declare the content type for the header of the http post, so that the api can know what to format to expect
  final Map<String, String> header = <String, String>{
      "Content-Type": "application/json"
  };

  final client = new http.Client(); 
   Widget build(context){
      return new Scaffold(
        appBar: new AppBar(
          title: new Text("New Email"),
        ),
      body: new Container(
          decoration: new BoxDecoration(
            image:  new DecorationImage(
              image: new AssetImage("assets/background.png"),
              fit: BoxFit.cover,
            )
          ),
          child: Column(
            children: <Widget>[
              StreamBuilder(
                stream: bloc.to,
                builder: (context, snapshot){
                  return TextField(
                    decoration: InputDecoration(
                      labelText: 'To:',
                       fillColor: Colors.white,
                       filled: true,
                    ),
                    onChanged: bloc.setTo,
                  );
                },
              ),
              Divider(color: Colors.white),
              StreamBuilder(
                stream: bloc.subject,
                builder: (context, snapshot){
                  return TextField(
                    decoration: InputDecoration(
                      labelText: "Enter Text",
                       fillColor: Colors.white,
                       filled: true,
                    ),
                    onChanged: bloc.setSubject,
                  maxLines: 5
                  );
                },
              ),
              Divider(color: Colors.white),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlatButton(
                    onPressed: () async {
                      print("sending");
                      StreamBloc content = StreamBloc();
                      http.Response response = await http.post(
                        'http://10.69.96.128:3000/notes',headers: header, body: json.encode(content)
                      );
                      String body = (response.body).toString();
                      print("http code: ${response.statusCode}");
                      print('response: $body');
                    },
                    child: Text("Send",
                                style: TextStyle(
                                    color: Colors.white,
                                ),
                               ),
                  )
                ],
              ),
            ],
          ),
        ),
      );
  }
}

class StreamBloc { 

   //final EmailModel _email = new EmailModel();
   //create subject
   static final _toSubject = new BehaviorSubject<String>();
   //final _fromSubject = new BehaviorSubject<String>();
   static final _subjectSubject = new BehaviorSubject<String>();

   static LeaveBehindItem item;   
   //add subject to sink/stream
   Function(String) get setTo => _toSubject.sink.add;
   //Function(String) get setFrom => _toSubject.sink.add;
   Function(String) get setSubject => _subjectSubject.sink.add;
   //create stream 
   Stream<String> get to => _toSubject.stream;
   //Stream<String> get from => _fromSubject.stream;
   Stream<String> get subject => _subjectSubject.stream;


   int id = RandomNumber.randomiser();
   static String date = new DateTime.now().toString();
   String msgDate = date;
   String from = "Peter";    
   String subjects = _subjectSubject.value;
   String too = _toSubject.value;
  
   Map toJson(){
    Map map = new Map();
    map['Id'] = this.id;
    map['Subject'] = this.subjects;
    map['MsgDate'] = this.msgDate;
    map['From'] = this.from;
    map['To'] = this.too;
    return map;
  }

   //close stream
   Future close() async{
     await _toSubject.drain();
     _toSubject.close();
     await _subjectSubject.drain();
    _subjectSubject.close();
   }
}
