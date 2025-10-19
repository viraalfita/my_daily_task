class Task {
  final String id;
  final String title;
  final String status;

  Task({required this.id, required this.title, required this.status});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(id: json['_id'], title: json['title'], status: json['status']);
  }

  Map<String, dynamic> toJson() {
    return {"title": title, "status": status};
  }
}
