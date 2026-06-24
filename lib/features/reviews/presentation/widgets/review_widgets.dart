import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../providers/review_providers.dart';

/// نجوم التقييم
class StarRating extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int>? onRatingChanged;
  final double size;
  final bool readOnly;

  const StarRating({
    super.key,
    this.initialRating = 5,
    this.onRatingChanged,
    this.size = 32,
    this.readOnly = false,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final filled = index < _rating;
        return GestureDetector(
          onTap: widget.readOnly
              ? null
              : () {
                  setState(() => _rating = index + 1);
                  widget.onRatingChanged?.call(index + 1);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              size: widget.size,
              color: filled ? AppColors.secondary : AppColors.divider,
            ),
          ),
        );
      }),
    );
  }
}

/// كارت تقييم واحد
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showReplyOption;
  final String? shopId;

  const ReviewCard({
    super.key,
    required this.review,
    this.showReplyOption = false,
    this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم + نجوم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(review.authorName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              StarRating(
                initialRating: review.rating,
                size: 18,
                readOnly: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(review.comment,
              style: Theme.of(context).textTheme.bodyMedium),

          // رد التاجر
          if (review.vendorReply != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.storefront_outlined,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      review.vendorReply!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet لكتابة تقييم جديد
class SubmitReviewSheet extends ConsumerStatefulWidget {
  final String shopId;
  final String? orderId;

  const SubmitReviewSheet({
    super.key,
    required this.shopId,
    this.orderId,
  });

  @override
  ConsumerState<SubmitReviewSheet> createState() =>
      _SubmitReviewSheetState();
}

class _SubmitReviewSheetState extends ConsumerState<SubmitReviewSheet> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reviewControllerProvider);

    ref.listen(reviewControllerProvider, (_, next) {
      if (next is AsyncData && !next.isLoading) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال تقييمك، شكراً!')),
        );
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('قيّم تجربتك',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),

          StarRating(
            initialRating: _rating,
            size: 40,
            onRatingChanged: (r) => setState(() => _rating = r),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'شاركنا رأيك في المنتجات والخدمة...',
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isLoading ? null : _submit,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('إرسال التقييم'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('من فضلك اكتب تعليقاً')),
      );
      return;
    }
    ref.read(reviewControllerProvider.notifier).submitReview(
          shopId: widget.shopId,
          rating: _rating,
          comment: _commentController.text,
          orderId: widget.orderId,
        );
  }
}
