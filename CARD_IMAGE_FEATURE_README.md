# 카드 이미지 기능

## 실행 방법

1. Django 마이그레이션
```bash
python manage.py migrate
```

2. 카드 데이터 & 이미지 URL 로드
```bash
python manage.py load_cards
python manage.py sync_card_images
```

3. 테스트 계정으로 로그인
- 전화번호: `01012345678`
- 비밀번호: `test1234`

4. 카드 탭에서 이미지 확인 ✓

## 주요 변경 파일

**Backend**: `cards/serializers.py`, `cards/management/commands/sync_card_images.py`, `users/views.py`

**Frontend**: `lib/services/card_service.dart`, `lib/screens/cards/card_analysis_page.dart`, `lib/screens/cards/card_detail_page.dart`

---

이미지는 CSV에서 로드되어 DB에 저장되고, API를 통해 프론트에서 표시됩니다.

