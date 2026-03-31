import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../screens/task_form_screen.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    // Determine blocking state purely from Flutter cache
    final isBlocked = provider.isTaskBlocked(task);
    final blockerTitle = provider.getBlockerTitle(task.blockedBy);
    
    final DateFormat formatter = DateFormat('MMM d, yyyy h:mm a');
    final formattedDate = formatter.format(task.dueDate);

    Color getStatusColor() {
      switch (task.status) {
        case 'To-Do': return Colors.blue;
        case 'In Progress': return Colors.orange;
        case 'Done': return Colors.green;
        default: return Colors.grey;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isBlocked ? Colors.grey[200] : Colors.white, // Disable styling
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        // Prevent edit click if blocked by task
        onTap: isBlocked ? () {
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This task is blocked by another task')),
             );
          } : () {
            Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) => TaskFormScreen(taskToEdit: task),
                ),
            );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isBlocked ? Colors.grey[600] : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(
                        color: getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isBlocked && blockerTitle != null) ...[
                Row(
                  children: [
                    const Icon(Icons.lock, size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Blocked by: $blockerTitle',
                        style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                task.description,
                style: TextStyle(color: isBlocked ? Colors.grey[500] : Colors.grey[800]),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Due: $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  if (task.recurrence != 'None')
                    Text('Recurring: ${task.recurrence}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
