import 'dart:convert';
import 'dart:io';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:realtime/firebase_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  // bool showEmojiPicker = false;

  File? pickedImage;
  File? recordedVoicePreview;


  void sendMessage() async {
    final text = messageController.text.trim();

    if (recordedVoicePreview != null) {
      await sendVoiceMessageLocal(recordedVoicePreview!.path);
      setState(() {
        recordedVoicePreview = null;
      });
      return;
    }

    if (text.isEmpty && pickedImage == null) return;

    await sendChatMessage(text.isEmpty ? "[IMAGE]" : text, imageFile: pickedImage);

    setState(() {
      messageController.clear();
      pickedImage = null;
    });
  }



  // void onEmojiSelected(Emoji emoji) {
  //   messageController.text += emoji.emoji;
  // }

  bool isRecording = false;
  late AudioService audioService;
  String? recordedPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFE1BEE7),
        elevation: 3,
        centerTitle: true,
        title: const Text(
          "Chat 💬",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF000000),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: getChatStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!.snapshot.value as Map?;
                  if (data == null) return Center(child: Text("No messages"));

                  final messages = data.entries.toList()
                    ..sort((a, b) => (a.value['timestamp'] as int)
                        .compareTo(b.value['timestamp'] as int));

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final item = messages[messages.length - 1 - index].value;
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFE1BEE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['imageBase64'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Image.memory(
                                    base64Decode(item['imageBase64']),
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              if (item['text'] != null
                                  && item['text'].toString().isNotEmpty
                                  && item['text'] != "[IMAGE]"
                                  && item['text'] != "[VOICE]"
                                  && item['text'] != item['localAudioPath'])
                                Text(
                                  item['text'],
                                  style: const TextStyle(fontSize: 16),
                                ),

                              if (item['localAudioPath'] != null)
                                VoiceMessageBubble(audioPath: item['localAudioPath']),

                              // Padding(
                                //   padding: const EdgeInsets.only(top: 8.0),
                                //   child: IconButton(
                                //     icon: Icon(Icons.play_arrow),
                                //     onPressed: () async {
                                //       final player = FlutterSoundPlayer();
                                //       await player.openPlayer();
                                //       await player.startPlayer(fromURI: item['localAudioPath']);
                                //     },
                                //   ),
                                // ),

                              const SizedBox(height: 6),
                              Text(
                                _formatTimestamp(item['timestamp']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ],
                          ),

                        ),
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error loading chat"));
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),


          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pickedImage != null)
                    Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                            image: DecorationImage(
                              image: FileImage(pickedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                pickedImage = null;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (recordedVoicePreview != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Icon(Icons.audiotrack, color: Color(0xFFD66BE8)),
                          SizedBox(width: 8),
                          Text("Voice message ready", style: TextStyle(fontSize: 14)),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                recordedVoicePreview = null;
                              });
                            },
                          )
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isRecording ? Icons.stop : Icons.mic),
                        color: isRecording ? Colors.red : Colors.black,
                        onPressed: () async {
                          await checkMicPermission();

                          if (!isRecording) {
                            audioService = AudioService();
                            await audioService.init();
                            await audioService.startRecording();
                            setState(() {
                              isRecording = true;
                            });
                          } else {
                            recordedPath = await audioService.stopRecording();
                            audioService.dispose();

                            setState(() {
                              isRecording = false;
                              if (recordedPath != null) {
                                recordedVoicePreview = File(recordedPath!);
                              }
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) {
                            return CustomDialogImagePicker(
                              onGalleryClick: pickFile,
                              onCameraClick: captureImage,
                            );
                          },
                        ),
                      ),
                      // IconButton(
                      //   icon: const Icon(Icons.emoji_emotions),
                      //   onPressed: () {
                      //     setState(() {
                      //       showEmojiPicker = !showEmojiPicker;
                      //     });
                      //   },
                      // ),
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: "Type a message...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send_sharp),
                        onPressed: sendMessage,
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          // if (showEmojiPicker)
          //   SizedBox(
          //     height: 250,
          //     child: EmojiPicker(
          //       onEmojiSelected: (category, emoji) {
          //         onEmojiSelected(emoji);
          //       },
          //       config: const Config(
          //         emojiSizeMax: 28,
          //         bgColor: Color(0xFFF0F0F0),
          //         columns: 7,
          //         verticalSpacing: 0,
          //         horizontalSpacing: 0,
          //         initCategory: Category.SMILEYS,
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
      allowMultiple: false,
    );
    if (result != null) {
      setState(() {
        pickedImage = File(result.files.single.path!);
        print("Picked from gallery: ${pickedImage?.path}");

      });
    }
  }

  Future<void> captureImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        pickedImage = File(pickedFile.path);
        print("Picked from camera: ${pickedImage?.path}");

      });

    }
  }

  Future<void> checkMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      var result = await Permission.microphone.request();
      if (result.isGranted) {
        print("🎤 Microphone permission granted");
      } else {
        print("❌ Microphone permission denied");
      }
    }
  }

}

String _formatTimestamp(dynamic timestamp) {
  try {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();

    if (now.difference(dateTime).inDays == 0) {
      // Today → show time only
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } else {
      // Older → show full date
      return "${dateTime.day} ${_monthName(dateTime.month)} ${dateTime.year}";
    }
  } catch (e) {
    return '';
  }
}

String _monthName(int month) {
  const months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month];
}


class CustomDialogImagePicker extends StatelessWidget {
  final Function? onCameraClick;
  final Function? onGalleryClick;

  const CustomDialogImagePicker(
      {super.key, this.onCameraClick, this.onGalleryClick});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: SizedBox(
        child: ListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
              child: Text(
                "select_files",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (onCameraClick != null) onCameraClick!();
                  },
                  child: Column(
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 50,
                        color: Color(0xFFB882C1),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        "Camera",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  width: 70,
                ),
                InkWell(
                  onTap: () async {
                    if (onGalleryClick != null) {
                      await onGalleryClick!();
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.file_open_outlined,
                          size: 50,
                          color: Color(0xFFB882C1),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          "file",
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Padding(
                padding:
                const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    "cancel",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecorderInitialized = false;
  String? _recordedPath;

  Future<void> init() async {
    if (_isRecorderInitialized) return;
    await _recorder.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _recordedPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: _recordedPath, codec: Codec.aacADTS);
  }

  Future<String?> stopRecording() async {
    await _recorder.stopRecorder();
    return _recordedPath; // return the correct path
  }

  void dispose() {
    _recorder.closeRecorder();
  }
}

class VoiceMessageBubble extends StatefulWidget {
  final String audioPath;

  const VoiceMessageBubble({super.key, required this.audioPath});

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late final AudioPlayer _player;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.setFilePath(widget.audioPath);

    _player.durationStream.listen((d) {
      if (d != null) {
        setState(() => duration = d);
      }
    });

    _player.positionStream.listen((p) {
      setState(() => position = p);
    });

    _player.playerStateStream.listen((state) {
      setState(() => isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFD1C4E9), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlayPause,
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 20,
              color: Color(0xFFBA68C8),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 10,
            width: 120,
            child: AudioFileWaveforms(
              playerController: PlayerController()
                ..preparePlayer(
                  path: widget.audioPath,
                  shouldExtractWaveform: true,
                ),
              size: const Size(double.infinity, 30),
              playerWaveStyle:  PlayerWaveStyle(
                fixedWaveColor: Color(0xFF7B1FA2),
                liveWaveColor: Color(0xFFBA68C8),
                showSeekLine: false,
              ),

            ),
          ),
        ],
      ),
    );
  }

}
