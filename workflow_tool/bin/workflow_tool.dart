import 'dart:convert';

import 'package:workflow_tool/workflow_tool.dart' as workflow_tool;

void main(List<String> arguments) {
  final matrix = workflow_tool.generateMatrix();
  final json = jsonEncode(matrix);
  print(json);
}
