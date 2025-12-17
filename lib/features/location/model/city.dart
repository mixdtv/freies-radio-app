class City {
  final String name;

  City({
    required this.name,
  });

  const City.empty({
     this.name = "",
  });

  const City.unknown({
    this.name = "Unknown",
  });

  bool get isEmpty => name.isEmpty;

  @override
  String toString() {
    return name;
  }

  static City fromString(String? value) {
    return City(
      name: value ?? "",
    );
  }
}