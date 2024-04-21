import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
var random=Random();
List<String> res_msg=[
  "Your data has been successfully added to the database. You can access it anytime you want. Is there anything else I can help you with?",
  "Data insertion into the database is complete. Feel free to access it whenever needed. How else can I assist you?",
  "The database has been updated with your data. It's now ready for retrieval whenever you require. What's your next step?",
  "Your information has been securely stored in the database. Whenever you're ready, you can retrieve it. What else would you like to do?",
  "Your data has been securely saved in our database. You can access it whenever needed. Do you have any other requests?",
  "Your data has been successfully stored in our database. It's available for you whenever you need it. Do you need assistance with anything else?",
  "Your data has been granted access to our database. It's available for you whenever you need it. Do you have any other requests?",
  "Your data is now safely stored in our database. Whenever you require it, it's ready for use. Is there anything more I can do for you?",
  "Your data is now part of our database. Whenever you require it, it's ready for use. Is there anything more I can do for you?",
  "Your data has been added to our database. It's ready for use whenever you need it. What would you like to do next?",
  "Your data has been successfully uploaded to the database. It's available for you to access whenever you need it. How else may I assist you?",
  "The database has been updated with your information. You can now access it whenever needed. Do you require any further assistance?",
  "Your information has been securely saved in our database. Whenever you need it, you can access it. What else can I help you with?",
  "Your data has been safely stored in our database. It's available for you whenever you need it. Do you require any other assistance?",
  "Your data has been added to our database. It's now ready for you to access whenever needed. Is there anything else you need assistance with?",
  "Your data has been successfully inserted into the database. You can now access it whenever you want. Do you need help with anything else?",
  "Data insertion into the database has been completed. It's now available for you to access. How else can I assist you?",
  "The database has been updated with your data. It's now ready for retrieval whenever you require. What's your next step?",
  "Your information has been securely stored in the database. Whenever you're ready, you can retrieve it. What else would you like to do?",
  "Your data has been securely saved in our database. You can access it whenever needed. Do you have any other requests?",
  "Your data has been successfully stored in our database. It's available for you whenever you need it. Do you need assistance with anything else?",
  "Your data has been granted access to our database. It's available for you whenever you need it. Do you have any other requests?"
];
void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: ChatPage(),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<types.Message> _messages = [];
  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
  );

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 144,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed (types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
    if(!textMessage.text.contains("#")&&!textMessage.text.contains(":")&&!textMessage.text.contains("dex --getAll")){
      var value=textMessage.text.toString();
      var url = Uri.parse('http://127.0.0.1:5000/chat');
      var headers = {'Content-Type': 'application/json'};
      var body = jsonEncode({'query':value});

      try {
        var response = await http.post(url, headers: headers, body: body);
        Map<String, dynamic> jsonMap = json.decode(response.body);

        print(response.body);
        final reply = types.TextMessage(
          author: const types.User(
              id: "datadexapi"
          ),

          createdAt: DateTime
              .now()
              .millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: jsonMap["response"],
        );
        _addMessage(reply);
      }
      catch(e){
        final reply = types.TextMessage(
          author: const types.User(
              id: "datadexapi"
          ),

          createdAt: DateTime
              .now()
              .millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: "DataDex server is not responding try again later :)",
        );
        _addMessage(reply);
      }
  }
  else if(textMessage.text.contains("#")&&textMessage.text.contains(":")){
    var msg=textMessage.text;
    int idx=msg.indexOf("#");
    int idx1=msg.indexOf(":");
    var key=msg.substring(idx+1,idx1);
    var value=msg.substring(idx1+1,msg.length);
    var url = Uri.parse('http://127.0.0.1:5000/ins_dex');
    var headers = {'Content-Type': 'application/json'};
    var body = jsonEncode({'key':key,'value':value});

    try {
      var response = await http.post(url, headers: headers, body: body);
      print('Response: ${response.body}');
      final reply = types.TextMessage(
        author: const types.User(
            id: "datadexapi"
        ),

        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),

          text:res_msg[random.nextInt(20)],



      );
      _addMessage(reply);


    } catch (e) {
      final reply = types.TextMessage(
        author: const types.User(
            id: "datadexapi"
        ),

        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text:"DataDex service is currently down kindly try after sometime 😊 ",
      );
      _addMessage(reply);
    }
  }
  else{
    if(textMessage.text.contains("#help")){
      final reply = types.TextMessage(
        author: const types.User(
            id: "datadexapi"
        ),

        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text:"Help",
      );
      _addMessage(reply);
    }
    else{
      if(textMessage.text.contains("dex --getAll")){
        try{
          var res = await http.get(Uri.parse("http://127.0.0.1:5000/getall"));
          if (res.statusCode == 200) {
            var jsonMap = json.decode(res.body);  // Decode the response body
            var formattedText = '';
            jsonMap.forEach((key, value) {
              formattedText += '$key: $value\n';
            });
            final reply = types.TextMessage(
              author: const types.User(
                  id: "datadexapi"
              ),
              createdAt: DateTime.now().millisecondsSinceEpoch,
              id: const Uuid().v4(),
              text: formattedText, // Set the text to the formatted key-value pairs
            );
            _addMessage(reply);
          } else {
            print('Failed to load data: ${res.statusCode}');
          }


        }
            catch(e){
              final reply = types.TextMessage(
                author: const types.User(
                    id: "datadexapi"
                ),

                createdAt: DateTime.now().millisecondsSinceEpoch,
                id: const Uuid().v4(),
                text:e.toString(),
              );
              _addMessage(reply);
            }
      }
      else{
      final reply = types.TextMessage(
        author: const types.User(
            id: "datadexapi"
        ),

        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text:"DataDex service is currently down kindly try after sometime 😊 ",
      );
      _addMessage(reply);
    }}
    }
  }

  void _loadMessages() async {
    final response = await rootBundle.loadString('assets/messages.json');
    final messages = (jsonDecode(response) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Chat(
        messages: _messages,
        onAttachmentPressed: _handleAttachmentPressed,
        onMessageTap: _handleMessageTap,
        onPreviewDataFetched: _handlePreviewDataFetched,
        onSendPressed: _handleSendPressed,
        showUserAvatars: true,
        showUserNames: true,
        user: _user,
        theme: const DefaultChatTheme(

          seenIcon: Text(
            'read',
            style: TextStyle(
              fontSize: 10.0,
            ),
          ),
        ),
      ),
    ),
  );



}