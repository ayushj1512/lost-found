import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart' show sha1;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});
  @override State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final trainController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String selectedType = 'Lost', selectedCategory = 'Wallet';
  File? selectedImage; bool isUploading = false;
  final _notifications = FlutterLocalNotificationsPlugin();

  @override void initState() { super.initState(); _initNotifications(); }
  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) {
        if (resp.payload == "matches") {
          navigatorKey.currentState?.pushNamed("/matches");
        }
      },
    );
  }

  Future<void> _showNotification() async {
    const android = AndroidNotificationDetails('match_channel','Matches',
        importance: Importance.high, priority: Priority.high);
    await _notifications.show(
      0,'🎉 Match Found!','We found similar items to your post. Tap to view.',
      const NotificationDetails(android: android, iOS: DarwinNotificationDetails()),
      payload: "matches",
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => selectedImage = File(picked.path));
  }

  Future<String?> _uploadToCloudinary(File f) async {
    try {
      final c = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      final k = dotenv.env['API_KEY'];
      final s = dotenv.env['API_SECRET'];
      final t = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final sig = sha1.convert(utf8.encode('timestamp=$t$s')).toString();
      final req = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/$c/image/upload'))
        ..fields['api_key'] = k! ..fields['timestamp'] = t ..fields['signature'] = sig
        ..files.add(await http.MultipartFile.fromPath('file', f.path));
      final res = await req.send();
      if (res.statusCode == 200) return jsonDecode(await res.stream.bytesToString())['secure_url'];
    } catch (e) { debugPrint("❌ Upload failed: $e"); }
    return null;
  }

  Future<List<String>> _getLabels(File f) async {
    final l = ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.7));
    final labels = await l.processImage(InputImage.fromFile(f)); await l.close();
    return labels.map((e) => e.label).toList();
  }

  Future<List<Map<String,dynamic>>> _findMatches(List<String> labels) async {
    final snap = await FirebaseFirestore.instance.collection('items').get();
    return snap.docs.map((d)=>d.data()).where((data){
      final stored = List<String>.from(data['labels'] ?? []);
      final t = (data['title']??'').toString().toLowerCase();
      final desc = (data['description']??'').toString().toLowerCase();
      return labels.any((l)=> t.contains(l.toLowerCase()) || desc.contains(l.toLowerCase()) || stored.contains(l));
    }).toList();
  }

  Future<void> _submit() async {
    if(!_formKey.currentState!.validate() || selectedImage==null) return;
    setState(()=>isUploading=true);
    final url = await _uploadToCloudinary(selectedImage!);
    if(url==null) return _error("Image upload failed");
    final labels = await _getLabels(selectedImage!);
    final matches = await _findMatches(labels);
    if(matches.isNotEmpty) await _showNotification();
    final u = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance.collection('items').add({
      'type': selectedType, 'title': titleController.text.trim(),
      'description': descController.text.trim(), 'photoUrl': url,
      'trainNumber': trainController.text.trim(), 'category': selectedCategory,
      'date': DateTime.now().toIso8601String().split('T').first,
      'postedBy': u.displayName ?? 'Anonymous', 'uid': u.uid,
      'labels': labels, 'timest': Timestamp.now(),
    });
    _reset(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Item Posted Successfully")));
  }

  void _error(String m){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m),backgroundColor:Colors.red)); setState(()=>isUploading=false); }
  void _reset(){ titleController.clear(); descController.clear(); trainController.clear(); setState((){selectedImage=null;selectedType='Lost';selectedCategory='Wallet';isUploading=false;}); }

  @override Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Item'), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key:_formKey,
          child:Column(children:[
            Row(children:["Lost","Found"].map((t)=>ChoiceChip(label:Text(t),selected:selectedType==t,onSelected:(_)=>setState(()=>selectedType=t))).toList()),
            const SizedBox(height:16),
            _field(titleController,"Title",Icons.title),
            const SizedBox(height:16),
            _field(descController,"Description",Icons.description,max:3),
            const SizedBox(height:16),
            DropdownButtonFormField(value:selectedCategory,
              items:['Wallet','Electronics','Documents','Clothing'].map((c)=>DropdownMenuItem(value:c,child:Text(c))).toList(),
              onChanged:(v)=>setState(()=>selectedCategory=v!), decoration:_dec("Category",Icons.category)),
            const SizedBox(height:16),
            _field(trainController,"Train No. / Station",Icons.train),
            const SizedBox(height:16),
            GestureDetector(onTap:_pickImage,child:Container(
              height:150,decoration:BoxDecoration(border:Border.all(color:Colors.grey),borderRadius:BorderRadius.circular(12)),
              child:selectedImage!=null?Image.file(selectedImage!,fit:BoxFit.cover):const Center(child:Text("Tap to upload image")),
            )),
            const SizedBox(height:20),
            ElevatedButton.icon(onPressed:isUploading?null:_submit,icon:const Icon(Icons.check),label:Text(isUploading?"Uploading...":"Submit")),
            const SizedBox(height:12),
            ElevatedButton.icon(onPressed:_showNotification,icon:const Icon(Icons.notifications_active),style:ElevatedButton.styleFrom(backgroundColor:Colors.orange),label:const Text("Test Notification"))
          ]),
        ),
      ),
    );
  }

  TextFormField _field(TextEditingController c,String l,IconData i,{int max=1}) =>
    TextFormField(controller:c,maxLines:max,validator:(v)=>v==null||v.isEmpty?"Enter $l":null,decoration:_dec(l,i));
  InputDecoration _dec(String l,IconData i)=>InputDecoration(labelText:l,prefixIcon:Icon(i),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)));
}
