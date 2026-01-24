// [설명] 카드 이미지 표시 위젯
// [용도] 백엔드에서 제공하는 카드 이미지 URL을 표시하고,
//       이미지가 없거나 로딩 실패 시 기본 카드 이미지를 표시
import 'package:flutter/material.dart';

class CardImageWidget extends StatelessWidget {
  // [설명] 백엔드에서 받아온 카드 이미지 URL (null일 수 있음)
  final String? imageUrl;

  // [설명] 이미지 위젯의 너비
  final double? width;

  // [설명] 이미지 위젯의 높이
  final double? height;

  // [설명] 이미지가 없을 때 표시할 기본 색상 (null이면 회색)
  final Color? fallbackColor;

  // [설명] 이미지의 모서리 둥글기
  final double borderRadius;

  // [설명] 이미지 표시 방식 (cover, contain 등)
  final BoxFit fit;

  const CardImageWidget({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fallbackColor,
    this.borderRadius = 12.0,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    // [설명] 이미지 URL이 있고 비어있지 않은 경우
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // [설명] 네트워크 이미지 표시 (백엔드에서 받아온 URL 사용)
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl!,
          width: width,
          height: height,
          fit: fit,
          // [설명] 이미지 로딩 중에 표시할 위젯 (로딩 인디케이터)
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              // [설명] 이미지 로딩 완료
              return child;
            }
            // [설명] 이미지 로딩 중 - 로딩 인디케이터 표시
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          // [설명] 이미지 로딩 실패 시 표시할 위젯 (기본 카드 이미지)
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackCard();
          },
        ),
      );
    } else {
      // [설명] 이미지 URL이 없는 경우 기본 카드 이미지 표시
      return _buildFallbackCard();
    }
  }

  // [설명] 이미지가 없거나 로딩 실패 시 표시할 기본 카드 이미지 위젯
  // [용도] 백엔드에 이미지 URL이 없거나, 네트워크 오류로 이미지를 불러올 수 없을 때 사용
  Widget _buildFallbackCard() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // [설명] 기본 배경색 (지정된 색상 또는 회색)
        color: fallbackColor ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          // [설명] 카드 아이콘 표시
          Icons.credit_card,
          size: (height ?? 100) * 0.4,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }
}
