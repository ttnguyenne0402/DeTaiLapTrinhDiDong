import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'review_form.dart';

class ReviewsScreen extends StatefulWidget {
  final Map<String, dynamic>? room;

  const ReviewsScreen({
    super.key,
    this.room,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late List<Map<String, dynamic>> _reviews;

  final List<Map<String, dynamic>> _defaultReviews = [
    {
      'name': 'Nguyễn Minh Anh',
      'rating': 5,
      'date': '2 ngày trước',
      'content':
          'Phòng sạch sẽ, khá thoáng và đầy đủ tiện nghi. Chủ trọ nhiệt tình, hỗ trợ nhanh khi có vấn đề.',
      'avatar': 'MA',
    },
    {
      'name': 'Trần Quốc Bảo',
      'rating': 4,
      'date': '1 tuần trước',
      'content':
          'Vị trí khá thuận tiện, khu vực xung quanh yên tĩnh. Phòng đúng như hình đăng.',
      'avatar': 'QB',
    },
    {
      'name': 'Lê Hoàng Nam',
      'rating': 5,
      'date': '2 tuần trước',
      'content':
          'Mình đã ở được một thời gian và cảm thấy khá ổn. An ninh tốt, giờ giấc thoải mái.',
      'avatar': 'HN',
    },
    {
      'name': 'Phạm Ngọc Hà',
      'rating': 4,
      'date': '1 tháng trước',
      'content':
          'Phòng đẹp, giá hợp lý. Chủ nhà thân thiện và dễ trao đổi.',
      'avatar': 'NH',
    },
  ];

  @override
  void initState() {
    super.initState();
    _reviews = List<Map<String, dynamic>>.from(_defaultReviews);
  }

  String get _roomName {
    return widget.room?['title']?.toString() ??
        'Phòng đầy đủ nội thất gần Đại học Công Thương';
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;

    final total = _reviews.fold<int>(
      0,
      (sum, review) => sum + (review['rating'] as int),
    );

    return total / _reviews.length;
  }

  Map<int, int> get _ratingCounts {
    return {
      5: _reviews.where((e) => e['rating'] == 5).length,
      4: _reviews.where((e) => e['rating'] == 4).length,
      3: _reviews.where((e) => e['rating'] == 3).length,
      2: _reviews.where((e) => e['rating'] == 2).length,
      1: _reviews.where((e) => e['rating'] == 1).length,
    };
  }

  void _openReviewForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewForm(
          room: widget.room,
          onReviewSubmitted: (review) {
            setState(() {
              _reviews.insert(0, review);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đánh giá phòng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _reviews.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                    children: [
                      _buildRoomHeader(),
                      const SizedBox(height: 18),
                      _buildRatingOverview(),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tất cả đánh giá',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${_reviews.length} đánh giá',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._reviews.map(
                        (review) => _buildReviewCard(review),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomSheet: _buildWriteReviewButton(),
    );
  }

  Widget _buildRoomHeader() {
    final image = widget.room?['image']?.toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.lightGreen.withOpacity(.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.lightGreen,
              image: image != null && image.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: image == null || image.isEmpty
                ? const Icon(
                    Icons.home_work_rounded,
                    color: AppColors.primaryGreen,
                    size: 28,
                  )
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ĐANG XEM ĐÁNH GIÁ',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _roomName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Column(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                _buildStars(
                  _averageRating.round(),
                  size: 17,
                  color: AppColors.accentYellow,
                ),
                const SizedBox(height: 7),
                Text(
                  '${_reviews.length} lượt đánh giá',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                _buildRatingBar(5),
                _buildRatingBar(4),
                _buildRatingBar(3),
                _buildRatingBar(2),
                _buildRatingBar(1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating) {
    final count = _ratingCounts[rating] ?? 0;
    final total = _reviews.length;
    final value = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 13,
            child: Text(
              '$rating',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.star_rounded,
            color: AppColors.accentYellow,
            size: 13,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(.18),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accentYellow,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 18,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white.withOpacity(.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final int rating = review['rating'] as int;
    final String name = review['name']?.toString() ?? 'Người dùng';
    final String date = review['date']?.toString() ?? '';
    final String content = review['content']?.toString() ?? '';
    final String avatar = review['avatar']?.toString() ?? 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(.045),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  avatar,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStars(
                rating,
                size: 15,
                color: AppColors.accentYellow,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(
    int rating, {
    double size = 18,
    Color color = AppColors.accentYellow,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: color,
        ),
      ),
    );
  }

  Widget _buildWriteReviewButton() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openReviewForm,
            icon: const Icon(
              Icons.rate_review_rounded,
              size: 20,
            ),
            label: const Text(
              'Viết đánh giá',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: AppColors.primaryGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có đánh giá',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy là người đầu tiên chia sẻ trải nghiệm về căn phòng này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}