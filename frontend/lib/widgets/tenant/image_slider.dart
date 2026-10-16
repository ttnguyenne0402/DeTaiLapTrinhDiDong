import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class ImageSlider extends StatefulWidget {
  final List<String> images;
  final VoidCallback? onFavoritePressed;
  final bool isFavorite;

  const ImageSlider({
    super.key,
    required this.images,
    this.onFavoritePressed,
    this.isFavorite = false,
  });

  @override
  State<ImageSlider> createState() => _ImageSliderState();
}

class _ImageSliderState extends State<ImageSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _hasImages => widget.images.isNotEmpty;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // =========================
          // ẢNH / PLACEHOLDER
          // =========================
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: _hasImages
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.images[index],
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      );
                    },
                  )
                : _buildPlaceholder(),
          ),

          // =========================
          // NÚT YÊU THÍCH
          // =========================
          if (widget.onFavoritePressed != null)
            Positioned(
              top: 16,
              right: 16,
              child: _FavoriteButton(
                isFavorite: widget.isFavorite,
                onPressed: widget.onFavoritePressed!,
              ),
            ),

          // =========================
          // CHỈ SỐ SLIDER
          // =========================
          if (_hasImages && widget.images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) {
                    final isActive = index == _currentPage;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isActive ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // PLACEHOLDER
  // =========================
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_outlined,
              size: 46,
              color: AppColors.primaryGreen,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Chưa có hình ảnh phòng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Hình ảnh sẽ được cập nhật sau',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// FAVORITE BUTTON
// =========================

class _FavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const _FavoriteButton({
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovering = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_hovering ? 1 : 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IconButton(
          onPressed: widget.onPressed,
          icon: Icon(
            widget.isFavorite
                ? Icons.favorite
                : Icons.favorite_border,
            color: widget.isFavorite
                ? Colors.redAccent
                : AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }
}