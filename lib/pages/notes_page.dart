import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import '../app_router.dart';
import '../cubit/notes_cubit.dart';
import '../cubit/notes_state.dart';
import '../models/note.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/note_dialog.dart';

@RoutePage()
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  void initState() {
    super.initState();
    context.read<NotesCubit>().loadNotes();
  }

  void openDetails(Note note) {
    context.router.push(NoteDetailsRoute(noteId: note.id));
  }

  void openSettings() {
    context.router.push(const SettingsRoute());
  }

  void showAddSuccessAnimation() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/todolist.json',
                    width: 180,
                    height: 180,
                    repeat: true,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Заметка добавлена',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> addNote() async {
    final saved = await showNoteDialog(context);
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar( 
        const SnackBar(content: Text('Заметка добавлена')),
      );
      showAddSuccessAnimation();
    }
  }

  void editNote(Note note) async {
    final saved = await showNoteDialog(context, note);
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заметка изменена')),
      );
    }
  }

  void deleteNote(Note note) async {
    final confirmed = await showDeleteDialog(context);
    if (confirmed && mounted) {
      context.read<NotesCubit>().deleteNote(note.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заметка удалена')),
      );
    }
  }

  Widget emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/todolist.json',
              width: 220,
              height: 220,
              repeat: true,
            ),
            const SizedBox(height: 12),
            const Text(
              'Заметок пока нет',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: addNote,
              child: const Text('Создать первую заметку'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                context.read<NotesCubit>().loadNotes();
              },
              child: const Text('Обновить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget noteCard(Note note) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          openDetails(note);
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: Theme.of(context).colorScheme.primary,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        note.title.isEmpty ? 'Без названия' : note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (note.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  editNote(note);
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: () {
                  deleteNote(note);
                },
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget notesView(List<Note> notes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 100,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return noteCard(notes[index]);
            },
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: noteCard(notes[index]),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
        actions: [
          IconButton(
            onPressed: openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: BlocBuilder<NotesCubit, NotesState>(
        builder: (context, state) {
          if (state is NotesLoading || state is NotesInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is NotesError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<NotesCubit>().loadNotes();
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          if (state is NotesLoaded) {
            if (state.notes.isEmpty) {
              return emptyView();
            }
            return notesView(state.notes);
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}
