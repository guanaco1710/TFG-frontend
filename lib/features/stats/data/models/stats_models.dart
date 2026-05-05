class UserStats {
  const UserStats({
    required this.totalBookings,
    required this.totalAttended,
    required this.totalNoShows,
    required this.totalCancellations,
    required this.attendanceRate,
    required this.currentStreak,
    this.favoriteClassType,
    required this.classesBookedThisMonth,
    this.classesRemainingThisMonth,
  });

  final int totalBookings;
  final int totalAttended;
  final int totalNoShows;
  final int totalCancellations;
  final double attendanceRate;
  final int currentStreak;
  final String? favoriteClassType;
  final int classesBookedThisMonth;
  final int? classesRemainingThisMonth;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalBookings: json['totalBookings'] as int,
      totalAttended: json['totalAttended'] as int,
      totalNoShows: json['totalNoShows'] as int,
      totalCancellations: json['totalCancellations'] as int,
      attendanceRate: (json['attendanceRate'] as num).toDouble(),
      currentStreak: json['currentStreak'] as int,
      favoriteClassType: json['favoriteClassType'] as String?,
      classesBookedThisMonth: json['classesBookedThisMonth'] as int,
      classesRemainingThisMonth: json['classesRemainingThisMonth'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalBookings': totalBookings,
    'totalAttended': totalAttended,
    'totalNoShows': totalNoShows,
    'totalCancellations': totalCancellations,
    'attendanceRate': attendanceRate,
    'currentStreak': currentStreak,
    'favoriteClassType': favoriteClassType,
    'classesBookedThisMonth': classesBookedThisMonth,
    'classesRemainingThisMonth': classesRemainingThisMonth,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserStats &&
        other.totalBookings == totalBookings &&
        other.totalAttended == totalAttended &&
        other.totalNoShows == totalNoShows &&
        other.totalCancellations == totalCancellations &&
        other.attendanceRate == attendanceRate &&
        other.currentStreak == currentStreak &&
        other.favoriteClassType == favoriteClassType &&
        other.classesBookedThisMonth == classesBookedThisMonth &&
        other.classesRemainingThisMonth == classesRemainingThisMonth;
  }

  @override
  int get hashCode => Object.hash(
    totalBookings,
    totalAttended,
    totalNoShows,
    totalCancellations,
    attendanceRate,
    currentStreak,
    favoriteClassType,
    classesBookedThisMonth,
    classesRemainingThisMonth,
  );
}
