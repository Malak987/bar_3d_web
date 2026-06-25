/// Selected pickup branch / date / time
class PickupInfo {
  final String? branch;
  final DateTime? date;
  final String? time;

  const PickupInfo({this.branch, this.date, this.time});

  bool get hasBranch => branch != null;
}
