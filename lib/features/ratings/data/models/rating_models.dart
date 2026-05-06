class Rating {
  const Rating({
    required this.id,
    required this.score,
    this.comment,
    required this.ratedAt,
    required this.userId,
    required this.sessionId,
  });

  final int id;
  final int score;
  final String? comment;
  final String ratedAt;
  final int userId;
  final int sessionId;

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
    id: json['id'] as int,
    score: json['score'] as int,
    comment: json['comment'] as String?,
    ratedAt: json['ratedAt'] as String,
    userId: json['userId'] as int,
    sessionId: json['sessionId'] as int,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'score': score,
    'comment': comment,
    'ratedAt': ratedAt,
    'userId': userId,
    'sessionId': sessionId,
  };
}

class RatingPage {
  const RatingPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasMore,
  });

  final List<Rating> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasMore;

  factory RatingPage.fromJson(Map<String, dynamic> json) => RatingPage(
    content: (json['content'] as List<dynamic>)
        .map((e) => Rating.fromJson(e as Map<String, dynamic>))
        .toList(),
    page: json['page'] as int,
    size: json['size'] as int,
    totalElements: json['totalElements'] as int,
    totalPages: json['totalPages'] as int,
    hasMore: json['hasMore'] as bool,
  );
}
