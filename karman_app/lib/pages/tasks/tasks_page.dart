import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:karman_app/components/dialog_window.dart';
import 'package:karman_app/pages/tasks/task_tile.dart';
import 'package:karman_app/components/folder_drawer.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String currentFolder = 'Default';
  List<String> folders = ['Default'];
  Map<String, List<Map<String, dynamic>>> folderTasks = {
    'Default': [
      {'name': 'Task 1', 'completed': false},
      {'name': 'Task 2', 'completed': true},
    ],
  };

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _folderController = TextEditingController();

  void _toggleTaskCompletion(int index, bool? value) {
    setState(() {
      folderTasks[currentFolder]![index]['completed'] = value!;
    });
  }

  void _editTask(BuildContext context, int index) {
    _taskController.text = folderTasks[currentFolder]![index]['name'];
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return TaskDialog(
          controller: _taskController,
          onSave: () {
            setState(() {
              folderTasks[currentFolder]![index]['name'] = _taskController.text;
              _taskController.clear();
            });
            Navigator.of(context).pop();
          },
          onCancel: () {
            _taskController.clear();
            Navigator.of(context).pop();
          },
          initialText: folderTasks[currentFolder]![index]['name'],
        );
      },
    );
  }

  void _deleteTask(BuildContext context, int index) {
    setState(() {
      folderTasks[currentFolder]!.removeAt(index);
    });
  }

  void _addTask() {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return TaskDialog(
          controller: _taskController,
          onSave: () {
            setState(() {
              folderTasks[currentFolder]!
                  .add({'name': _taskController.text, 'completed': false});
              _taskController.clear();
            });
            Navigator.of(context).pop();
          },
          onCancel: () {
            _taskController.clear();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _addFolder() {
    setState(() {
      String newFolder = _folderController.text;
      folders.add(newFolder);
      folderTasks[newFolder] = [];
      _folderController.clear();

      // Automatically select the newly created folder if no folder was selected
      if (folders.length == 1) {
        currentFolder = newFolder;
      }
    });
  }

  void _editFolder(BuildContext context, int index) {
    _folderController.text = folders[index];
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return TaskDialog(
          controller: _folderController,
          onSave: () {
            setState(() {
              String oldFolder = folders[index];
              String newFolder = _folderController.text;
              folders[index] = newFolder;
              folderTasks[newFolder] = folderTasks.remove(oldFolder)!;
              if (currentFolder == oldFolder) {
                currentFolder = newFolder;
              }
              _folderController.clear();
            });
            Navigator.of(context).pop();
          },
          onCancel: () {
            _folderController.clear();
            Navigator.of(context).pop();
          },
          initialText: folders[index],
        );
      },
    );
  }

  void _deleteFolder(BuildContext context, int index) {
    setState(() {
      String folder = folders.removeAt(index);
      folderTasks.remove(folder);
      if (currentFolder == folder) {
        currentFolder = folders.isNotEmpty ? folders[0] : 'Default';
      }
    });
  }

  void _openDrawer() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return FolderDrawer(
          folders: folders,
          onFolderSelected: (folder) {
            setState(() {
              currentFolder = folder;
            });
          },
          controller: _folderController,
          onCreateFolder: _addFolder,
          onEditFolder: (context, index) {
            _editFolder(context, index);
            setState(() {});
          },
          onDeleteFolder: (context, index) {
            _deleteFolder(context, index);
            setState(() {});
          },
        );
      },
    );
  }

  String getAppbarTitle() {
    if (folders.isEmpty) {
      return '¯\\_(ツ)_/¯'; // Shrugging emoticon when no folders exist
    } else {
      return currentFolder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,
        middle: Text(getAppbarTitle()),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _openDrawer,
          child: Icon(
            CupertinoIcons.square_stack,
            color: CupertinoColors.white,
          ),
        ),
        trailing: folders.isEmpty
            ? null // Disable trailing button when no folders are present
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _addTask,
                child: Icon(
                  CupertinoIcons.plus,
                  color: CupertinoColors.white,
                ),
              ),
      ),
      child: SafeArea(
        child: folders.isEmpty
            ? Center(
                child: Text(
                  'No folders? Create one!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16.0),
                itemCount: folderTasks[currentFolder]!.length,
                itemBuilder: (context, index) {
                  return TaskTile(
                    taskName: folderTasks[currentFolder]![index]['name'],
                    taskCompleted: folderTasks[currentFolder]![index]
                        ['completed'],
                    onChanged: (value) => _toggleTaskCompletion(index, value),
                    onEdit: (context) => _editTask(context, index),
                    onDelete: (context) => _deleteTask(context, index),
                  );
                },
              ),
      ),
    );
  }
}
