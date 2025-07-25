class Fundraiser {
  final String id;

  Fundraiser({required this.id});

  factory Fundraiser.fromMap(String id, Map<String, dynamic> data) {
    return Fundraiser(id: id);
  }
}
