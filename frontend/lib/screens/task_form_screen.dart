import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../utils/debouncer.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? taskToEdit;
  const TaskFormScreen({Key? key, this.taskToEdit}) : super(key: key);

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  
  DateTime? _selectedDate;
  String _status = 'To-Do';
  String _recurrence = 'None';
  int? _blockedBy;
  
  bool _isLoading = false;
  bool _isDeleting = false;
  
  final _debouncer = Debouncer(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      _titleController.text = widget.taskToEdit!.title;
      _descController.text = widget.taskToEdit!.description;
      _selectedDate = widget.taskToEdit!.dueDate;
      _status = widget.taskToEdit!.status;
      _recurrence = widget.taskToEdit!.recurrence;
      _blockedBy = widget.taskToEdit!.blockedBy;
    } else {
      _loadDraft();
    }
  }

  bool get _isEditMode => widget.taskToEdit != null;

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftStr = prefs.getString('task_draft');
    if (draftStr != null) {
      final draft = json.decode(draftStr);
      setState(() {
        _titleController.text = draft['title'] ?? '';
        _descController.text = draft['description'] ?? '';
        if (draft['due_date'] != null) {
          _selectedDate = DateTime.tryParse(draft['due_date']);
        }
        _status = draft['status'] ?? 'To-Do';
        _recurrence = draft['recurrence'] ?? 'None';
        _blockedBy = draft['blocked_by'];
      });
    }
  }

  void _saveDraft() {
    if (_isEditMode) return; // Only save drafts for NEW tasks
    _debouncer.run(() async {
      final prefs = await SharedPreferences.getInstance();
      final draft = {
        'title': _titleController.text,
        'description': _descController.text,
        'due_date': _selectedDate?.toIso8601String(),
        'status': _status,
        'recurrence': _recurrence,
        'blocked_by': _blockedBy,
      };
      await prefs.setString('task_draft', json.encode(draft));
    });
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('task_draft');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // cannot be in the past
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _saveDraft();
    }
  }

  List<Task> _getValidBlockingTasks(TaskProvider provider) {
    if (!_isEditMode) return provider.allTasks;
    
    return provider.allTasks.where((task) {
      // Exclude current task
      if (task.id == widget.taskToEdit!.id) return false;
      // Exclude tasks that already depend on the current task (circular dep)
      if (task.blockedBy == widget.taskToEdit!.id) return false;
      return true;
    }).toList();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Due Date')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      final newTask = Task(
        title: _titleController.text,
        description: _descController.text,
        dueDate: _selectedDate!,
        status: _status,
        recurrence: _recurrence,
        blockedBy: _blockedBy,
      );

      if (_isEditMode) {
        await provider.updateTask(widget.taskToEdit!.id!, newTask);
      } else {
        await provider.createTask(newTask);
        await _clearDraft(); // clear draft after successful creation
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask() async {
    setState(() => _isDeleting = true);
    try {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      await provider.deleteTask(widget.taskToEdit!.id!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final validBlockers = _getValidBlockingTasks(provider);
    final interactionDisabled = _isLoading || _isDeleting;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: _isDeleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.delete),
              onPressed: interactionDisabled ? null : _deleteTask,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  enabled: !interactionDisabled,
                  decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Title cannot be empty' : null,
                  onChanged: (_) => _saveDraft(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descController,
                  enabled: !interactionDisabled,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Description cannot be empty' : null,
                  onChanged: (_) => _saveDraft(),
                ),
                const SizedBox(height: 16),
                
                // Date Picker
                InkWell(
                  onTap: interactionDisabled ? null : () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                    child: Text(_selectedDate == null ? 'Select Date' : DateFormat('MMM d, yyyy').format(_selectedDate!)),
                  ),
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: ['To-Do', 'In Progress', 'Done'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: interactionDisabled ? null : (val) {
                    setState(() => _status = val!);
                    _saveDraft();
                  },
                ),
                const SizedBox(height: 16),

                // Recurrence Dropdown
                DropdownButtonFormField<String>(
                  value: _recurrence,
                  decoration: const InputDecoration(labelText: 'Recurrence', border: OutlineInputBorder()),
                  items: ['None', 'Daily', 'Weekly'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: interactionDisabled ? null : (val) {
                    setState(() => _recurrence = val!);
                    _saveDraft();
                  },
                ),
                const SizedBox(height: 16),

                // Blocked By Dropdown
                DropdownButtonFormField<int?>(
                  value: _blockedBy,
                  decoration: const InputDecoration(labelText: 'Blocked By (Optional)', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('None')),
                    ...validBlockers.map((t) => DropdownMenuItem<int?>(value: t.id, child: Text(t.title))),
                  ],
                  onChanged: interactionDisabled ? null : (val) {
                    setState(() => _blockedBy = val);
                    _saveDraft();
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: interactionDisabled ? null : _saveTask,
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('Save Task', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
