// File: add_new_leave_type.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Screens/hrm/leave_request/leave_type/repo/leave_type_repo.dart';

// --- Local Imports ---
import 'package:mobile_pos/Screens/hrm/widgets/label_style.dart';
import 'package:mobile_pos/constant.dart';

import 'model/leave_type_list_model.dart';

class AddNewLeaveType extends ConsumerStatefulWidget {
  final LeaveTypeData? leaveTypeData; // For editing

  // isEdit property replaced by checking if leaveTypeData is null
  const AddNewLeaveType({super.key, this.leaveTypeData});

  @override
  ConsumerState<AddNewLeaveType> createState() => _AddNewLeaveTypeState();
}

class _AddNewLeaveTypeState extends ConsumerState<AddNewLeaveType> {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  String? selectedValue;
  GlobalKey<FormState> key = GlobalKey();

  bool get isEditing => widget.leaveTypeData != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final data = widget.leaveTypeData!;
      nameController.text = data.name ?? '';
      descriptionController.text = data.description ?? '';

      // Convert num status (1/0) to string status ('Active'/'Inactive')
      if (data.status == 1) {
        selectedValue = 'Active';
      } else if (data.status == 0) {
        selectedValue = 'Inactive';
      }
    } else {
      // Default status for new entry
      selectedValue = 'Active';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (key.currentState!.validate() && selectedValue != null) {
      final repo = LeaveTypeRepo();
      final statusNum = selectedValue == 'Active' ? 1 : 0;

      if (isEditing) {
        // --- UPDATE LEAVE TYPE ---
        await repo.updateLeaveType(
          ref: ref,
          context: context,
          id: widget.leaveTypeData!.id!,
          name: nameController.text,
          description: descriptionController.text,
          status: statusNum,
        );
      } else {
        // --- CREATE LEAVE TYPE ---
        await repo.createLeaveType(
          ref: ref,
          context: context,
          name: nameController.text,
          description: descriptionController.text,
          status: statusNum,
        );
      }
    }
  }

  void _resetOrCancel() {
    if (isEditing) {
      Navigator.pop(context);
    } else {
      setState(() {
        key.currentState?.reset();
        nameController.clear();
        descriptionController.clear();
        selectedValue = 'Active';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          isEditing ? 'Edit Leave Type' : 'Add New Leave Type',
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 2,
            color: kBackgroundColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: key,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  label: labelSpan(
                    title: 'Name',
                    context: context,
                  ),
                  hintText: 'Enter leave type name',
                ),
                validator: (value) => value!.isEmpty ? 'Please Enter leave type name' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedValue,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: kNeutral800,
                ),
                decoration: const InputDecoration(
                  labelText: 'Status',
                  hintText: 'Select a status',
                ),
                items: ['Active', 'Inactive'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedValue = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a status' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description ',
                  hintText: 'Enter Description...',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetOrCancel,
                      child: Text(isEditing ? 'Cancel' : 'Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(isEditing ? 'Update' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
