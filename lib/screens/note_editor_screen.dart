import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../providers/note_provider.dart';
import '../models/note_model.dart';
import '../models/checklist_model.dart';
import '../services/notification_service.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NoteModel? note;
  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  List<ChecklistItem> _checklistItems = [];
  String? _drawingImagePath;
  String? _audioFilePath;
  DateTime? _reminderDate;

  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPaused = false;
  bool _isPlaying = false;
  
  int _recordDuration = 0;
  Timer? _recordTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _checklistItems = widget.note!.checklistItems?.toList() ?? [];
      _drawingImagePath = widget.note!.drawingImagePath;
      _audioFilePath = widget.note!.audioFilePath;
      _reminderDate = widget.note!.reminderDate;
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _pulseController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty && _checklistItems.isEmpty && _drawingImagePath == null && _audioFilePath == null) {
      context.pop();
      return;
    }

    final note = NoteModel(
      id: widget.note?.id ?? const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      checklistItems: _checklistItems.isNotEmpty ? _checklistItems : null,
      drawingImagePath: _drawingImagePath,
      audioFilePath: _audioFilePath,
      reminderDate: _reminderDate,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.note == null) {
      ref.read(notesProvider.notifier).addNote(note);
    } else {
      ref.read(notesProvider.notifier).updateNote(note);
    }

    if (note.reminderDate != null && note.reminderDate!.isAfter(DateTime.now())) {
      NotificationService().scheduleNotification(
        id: note.id.hashCode,
        title: 'Reminder: ${note.title}',
        body: note.content.isNotEmpty ? note.content : 'You have a note reminder.',
        scheduledTime: note.reminderDate!,
      );
    } else if (note.reminderDate == null && widget.note?.reminderDate != null) {
      NotificationService().cancelNotification(note.id.hashCode);
    }

    context.pop();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio_${const Uuid().v4()}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordDuration = 0;
      });
      _pulseController.repeat(reverse: true);
      _startTimer();
    }
  }

  void _startTimer() {
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!_isPaused) {
        setState(() => _recordDuration++);
      }
    });
  }

  Future<void> _pauseResumeRecording() async {
    if (_isPaused) {
      await _audioRecorder.resume();
      setState(() => _isPaused = false);
      _pulseController.repeat(reverse: true);
    } else {
      await _audioRecorder.pause();
      setState(() => _isPaused = true);
      _pulseController.stop();
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _recordTimer?.cancel();
    _pulseController.stop();
    setState(() {
      _isRecording = false;
      _isPaused = false;
      _audioFilePath = path;
    });
  }

  Future<void> _togglePlayback() async {
    if (_audioFilePath == null) return;
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioFilePath!));
    }
  }

  Future<void> _pickReminderDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _reminderDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_reminderDate != null)
              Row(
                children: [
                  const Icon(Icons.alarm, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text('Reminder: ${DateFormat.yMd().add_jm().format(_reminderDate!)}'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _reminderDate = null),
                  )
                ],
              ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView(
                children: [
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(hintText: 'Note', border: InputBorder.none),
                    maxLines: null,
                  ),
                  if (_checklistItems.isNotEmpty) ...[
                    const Divider(),
                    const Text('Checklist', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._checklistItems.asMap().entries.map((entry) {
                      int idx = entry.key;
                      ChecklistItem item = entry.value;
                      return Row(
                        children: [
                          Checkbox(
                            value: item.isCompleted,
                            onChanged: (val) {
                              setState(() {
                                _checklistItems[idx].isCompleted = val ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.title,
                              decoration: const InputDecoration(border: InputBorder.none),
                              onChanged: (val) {
                                _checklistItems[idx] = ChecklistItem(title: val, isCompleted: item.isCompleted);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _checklistItems.removeAt(idx);
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                  if (_drawingImagePath != null) ...[
                    const Divider(),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.file(File(_drawingImagePath!)),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => setState(() => _drawingImagePath = null),
                        )
                      ],
                    ),
                  ],
                  if (_audioFilePath != null) ...[
                    const Divider(),
                    ListTile(
                      leading: IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: _togglePlayback,
                      ),
                      title: const Text('Audio Recording'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _audioPlayer.stop();
                          setState(() {
                            _audioFilePath = null;
                            _isPlaying = false;
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (_isRecording) ...[
              FadeTransition(
                opacity: _pulseController,
                child: const Icon(Icons.mic, color: Colors.red),
              ),
              Text('$_recordDuration s'),
              IconButton(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                onPressed: _pauseResumeRecording,
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: _stopRecording,
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.mic),
                onPressed: _startRecording,
              ),
              IconButton(
                icon: const Icon(Icons.brush),
                onPressed: () async {
                  final path = await context.push<String>('/drawing');
                  if (path != null) {
                    setState(() {
                      _drawingImagePath = path;
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.check_box),
                onPressed: () {
                  setState(() {
                    _checklistItems.add(ChecklistItem(title: ''));
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.alarm_add),
                onPressed: _pickReminderDate,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
