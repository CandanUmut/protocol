import 'package:uuid/uuid.dart';

class TodoItem {
  TodoItem({String? id, required this.title, this.active = true}) : id = id ?? const Uuid().v4();

  final String id;
  final String title;
  final bool active;

  TodoItem copyWith({String? title, bool? active}) =>
      TodoItem(id: id, title: title ?? this.title, active: active ?? this.active);

  factory TodoItem.fromJson(Map<String, dynamic> json) =>
      TodoItem(id: json['id'] as String?, title: json['title'] as String, active: json['active'] as bool? ?? true);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'active': active};
}
